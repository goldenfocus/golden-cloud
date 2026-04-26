/**
 * MADAME — DB write helpers.
 *
 * @supabase/supabase-js is a peer dep of this block; consumers provide the client.
 * We type the client loosely (`any` for table shape) so we work against any
 * project's generated `Database` type without coupling.
 */

import type { SupabaseClient } from '@supabase/supabase-js';
import type { ToggleResult } from '../core/types';

export interface PlatformConfigRow {
  id: string;
  tenant_id: string;
  platform: string;
  listing_id: string | null;
  is_active: boolean;
  credentials_enc: string | null;
  interval_min: number;
  interval_max: number;
  last_event_at: string | null;
  last_error: string | null;
  next_run_at: string | null;
  run_lock_until: string | null;
}

export interface PostingEventRow {
  id: string;
  tenant_id: string;
  platform: string;
  listing_id: string | null;
  event_type: string;
  payload: Record<string, unknown> | null;
  online_until: string | null;
  triggered_by: string;
  created_at: string;
}

export interface ConfigPatch {
  is_active?: boolean;
  last_event_at?: Date | string | null;
  last_error?: string | null;
  next_run_at?: Date | string | null;
  run_lock_until?: Date | string | null;
}

export class MadameLogger {
  constructor(
    private readonly db: SupabaseClient,
    private readonly tenantId: string,
    private readonly listingId?: string,
  ) {}

  async writeEvent(
    platform: string,
    result: ToggleResult,
    triggeredBy: string = 'cron',
  ): Promise<void> {
    await this.db.from('madame_posting_events').insert({
      tenant_id: this.tenantId,
      platform,
      listing_id: this.listingId ?? null,
      event_type: result.eventType,
      payload: result.payload ?? null,
      online_until: result.onlineUntil?.toISOString() ?? null,
      triggered_by: triggeredBy,
    } as never);
  }

  async updateConfig(platform: string, patch: ConfigPatch): Promise<void> {
    const normalized: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(patch)) {
      normalized[k] = v instanceof Date ? v.toISOString() : v;
    }
    let q = this.db
      .from('madame_platform_config')
      .update(normalized as never)
      .eq('tenant_id', this.tenantId)
      .eq('platform', platform);
    if (this.listingId) q = q.eq('listing_id', this.listingId);
    else q = q.is('listing_id', null);
    await q;
  }

  async getConfig(platform: string): Promise<PlatformConfigRow | null> {
    let q = this.db
      .from('madame_platform_config')
      .select('*')
      .eq('tenant_id', this.tenantId)
      .eq('platform', platform);
    if (this.listingId) q = q.eq('listing_id', this.listingId);
    else q = q.is('listing_id', null);
    const { data } = await q.maybeSingle();
    return (data as PlatformConfigRow) ?? null;
  }

  async getEvents(platform: string, limit = 50): Promise<PostingEventRow[]> {
    let q = this.db
      .from('madame_posting_events')
      .select('*')
      .eq('tenant_id', this.tenantId)
      .eq('platform', platform);
    if (this.listingId) q = q.eq('listing_id', this.listingId);
    const { data } = await q.order('created_at', { ascending: false }).limit(limit);
    return (data as PostingEventRow[] | null) ?? [];
  }
}
