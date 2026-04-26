/**
 * MADAME engine — orchestrates a single (tenant, platform, listing) toggle cycle.
 *
 * Race safety:
 *   - Cron and manual `Bump Now` may both fire while a toggle is in flight.
 *   - Lock is acquired atomically via `madame_acquire_lock` SQL function
 *     before the adapter is called. Lock TTL = 5 min (covers slow proxies).
 *   - Lock is released by setting run_lock_until = NULL in the post-run update.
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import type {
  Credentials,
  MadameAdapter,
  ToggleResult,
} from '../core/types';
import { MadameLogger } from './logger';
import { decryptCredentials } from './credentials';

const LOCK_TTL_MS = 5 * 60 * 1000;
const LOCK_RETRY_MS = 60 * 1000;

export interface RunResult {
  nextInMs: number;
  skipped?: 'inactive' | 'locked' | 'no_config';
  result?: ToggleResult;
}

export interface MadameEngineOptions {
  /** Optional listing identifier — for platforms with multiple ads per credentials. */
  listingId?: string;
}

export class MadameEngine {
  private readonly logger: MadameLogger;

  constructor(
    private readonly adapter: MadameAdapter,
    private readonly db: SupabaseClient,
    private readonly tenantId: string,
    private readonly encryptionKey: string,
    private readonly options: MadameEngineOptions = {},
  ) {
    this.logger = new MadameLogger(db, tenantId, options.listingId);
  }

  async runOnce(triggeredBy: 'cron' | 'manual' = 'cron'): Promise<RunResult> {
    const config = await this.logger.getConfig(this.adapter.platform);

    if (!config) {
      return {
        nextInMs: this.randomInterval(15, 30),
        skipped: 'no_config',
      };
    }

    if (!config.is_active) {
      return {
        nextInMs: this.randomInterval(config.interval_min, config.interval_max),
        skipped: 'inactive',
      };
    }

    if (!config.credentials_enc) {
      const result: ToggleResult = {
        eventType: 'error',
        error: 'no credentials configured',
      };
      await this.logger.writeEvent(this.adapter.platform, result, triggeredBy);
      return { nextInMs: this.randomInterval(config.interval_min, config.interval_max), result };
    }

    // Atomic lock — bail if another runner holds it.
    const lockUntil = new Date(Date.now() + LOCK_TTL_MS);
    const { data: locked, error: lockErr } = await this.db.rpc('madame_acquire_lock', {
      p_tenant_id: this.tenantId,
      p_platform: this.adapter.platform,
      p_listing_id: this.options.listingId ?? null,
      p_lock_until: lockUntil.toISOString(),
    });

    if (lockErr) {
      const result: ToggleResult = {
        eventType: 'error',
        error: `lock_acquire_failed: ${(lockErr as { message?: string }).message ?? 'unknown'}`,
      };
      await this.logger.writeEvent(this.adapter.platform, result, triggeredBy);
      return { nextInMs: LOCK_RETRY_MS, result };
    }

    if (!locked) {
      const result: ToggleResult = { eventType: 'lock_contention' };
      await this.logger.writeEvent(this.adapter.platform, result, triggeredBy);
      return { nextInMs: LOCK_RETRY_MS, skipped: 'locked', result };
    }

    try {
      const credentials = JSON.parse(
        await decryptCredentials(config.credentials_enc, this.encryptionKey),
      ) as Credentials;

      const result = await this.adapter.toggleOnline({
        credentials,
        listingId: this.options.listingId,
      });

      await this.logger.writeEvent(this.adapter.platform, result, triggeredBy);

      const nextInMs =
        result.suggestedNextMs ??
        this.randomInterval(config.interval_min, config.interval_max);

      await this.logger.updateConfig(this.adapter.platform, {
        last_event_at: new Date(),
        last_error: result.error ?? null,
        next_run_at: new Date(Date.now() + nextInMs),
        run_lock_until: null,
      });

      return { nextInMs, result };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      const result: ToggleResult = { eventType: 'error', error: message };
      await this.logger.writeEvent(this.adapter.platform, result, triggeredBy);
      await this.logger.updateConfig(this.adapter.platform, {
        last_event_at: new Date(),
        last_error: message,
        run_lock_until: null,
      });
      return {
        nextInMs: this.randomInterval(config.interval_min, config.interval_max),
        result,
      };
    }
  }

  async pause(): Promise<void> {
    await this.logger.updateConfig(this.adapter.platform, { is_active: false });
  }

  async resume(): Promise<void> {
    await this.logger.updateConfig(this.adapter.platform, { is_active: true });
  }

  async getStatus() {
    const config = await this.logger.getConfig(this.adapter.platform);
    const events = await this.logger.getEvents(this.adapter.platform, 1);
    return { config, lastEvent: events[0] ?? null };
  }

  async getEvents(limit = 50) {
    return this.logger.getEvents(this.adapter.platform, limit);
  }

  private randomInterval(minMin: number, maxMin: number): number {
    const min = Math.max(1, minMin);
    const max = Math.max(min, maxMin);
    const minutes = Math.floor(Math.random() * (max - min + 1)) + min;
    return minutes * 60 * 1000;
  }
}

export { MadameLogger } from './logger';
export { encryptCredentials, decryptCredentials } from './credentials';
export type {
  Credentials,
  MadameAdapter,
  PlatformStatus,
  SessionCache,
  ToggleRequest,
  ToggleResult,
} from '../core/types';
