/**
 * MADAME — core types.
 *
 * Adapter-agnostic shapes. Adding a new platform = implement MadameAdapter
 * and pass it to MadameEngine. Engine never reaches into adapter internals.
 */

export type CredentialsType = 'password' | 'oauth' | 'api_key' | 'session';

export interface Credentials {
  type: CredentialsType;
  /** password-type */
  email?: string;
  password?: string;
  phone?: string;
  /** oauth-type */
  accessToken?: string;
  refreshToken?: string;
  /** api_key-type */
  apiKey?: string;
  /** session-type — for pre-authenticated sessions */
  sessionCookie?: string;
}

export interface ToggleRequest {
  credentials: Credentials;
  /** Optional — some platforms have one listing per account; others have many. */
  listingId?: string;
  /** Optional — abort long-running toggles (e.g. on pause()). */
  signal?: AbortSignal;
}

export type ToggleEventType =
  | 'toggle_on'
  | 'toggle_bump'
  | 'toggle_skip'
  | 'session_refresh'
  | 'error'
  | 'lock_contention';

export interface ToggleResult {
  eventType: ToggleEventType;
  onlineUntil?: Date;
  payload?: Record<string, unknown>;
  error?: string;
  /** Adapter-suggested next interval in ms. Engine may override (config bounds). */
  suggestedNextMs?: number;
}

export interface PlatformStatus {
  isOnline: boolean;
  onlineUntil?: Date;
  lastChecked: Date;
  listingId?: string;
}

export interface MadameAdapter {
  /** Stable identifier (e.g. 'escorteintime.com'). */
  platform: string;
  toggleOnline(req: ToggleRequest): Promise<ToggleResult>;
  /** Optional — adapters may use a cached session if credentials are omitted. */
  getStatus(credentials?: Credentials, listingId?: string): Promise<PlatformStatus>;
  /** Optional — explicit session refresh, separate from toggle. */
  refreshSession?(credentials: Credentials): Promise<boolean>;
}

/**
 * Pluggable session cache. Caller provides — Vercel KV, Redis, Supabase row,
 * in-memory Map for tests, etc.
 */
export interface SessionCache {
  get(key: string): Promise<string | null>;
  set(key: string, value: string, ttlSeconds?: number): Promise<void>;
  delete?(key: string): Promise<void>;
}
