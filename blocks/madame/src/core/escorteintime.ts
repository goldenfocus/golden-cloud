/**
 * escorteintime.com adapter.
 *
 * Toggles a profile's online presence on/off so it stays at the top of
 * listings. The site marks a profile online for 2h after a PATCH; we bump
 * the timestamp every 15-30 min while active.
 *
 * Logic (preserved from original 2025 port):
 *   diff < 0                       → profile offline → toggle ON
 *   diff < 120 - EVERY_MINUTES (105) → still online but stale → OFF then ON (bump)
 *   else                           → too soon, sleep until 'diff - 105'
 *
 * BrightData proxy is required — escorteintime rate-limits cloud IPs.
 */

import type {
  Credentials,
  MadameAdapter,
  PlatformStatus,
  SessionCache,
  ToggleRequest,
  ToggleResult,
} from './types';

const DOMAIN = 'escorteintime.com';
const AUTH_ENDPOINT = `https://www.${DOMAIN}/api/auth`;
const USER_ENDPOINT = `https://www.${DOMAIN}/api/user`;
const SESSION_KEY = `madame:session@${DOMAIN}`;
const SESSION_REGEX = /^[A-Za-z0-9_]{21}$/;
const EVERY_MINUTES = 15;
const ONLINE_DURATION_MIN = 120; // escorteintime keeps profile "online" for 120 min after a bump

export interface EscorteintimeOptions {
  brightDataId: string;
  brightDataPass: string;
  /** Override fetch — useful for tests. Defaults to a node-fetch + proxy-agent dynamic import. */
  fetcher?: ProxiedFetcher;
}

export type ProxiedFetcher = (
  url: string,
  init: ProxiedFetchInit,
) => Promise<ProxiedFetchResponse>;

export interface ProxiedFetchInit {
  method: 'GET' | 'POST' | 'PATCH';
  headers: Record<string, string>;
  body?: string;
  proxy: string;
  signal?: AbortSignal;
}

export interface ProxiedFetchResponse {
  ok: boolean;
  status: number;
  headers: { get(name: string): string | null };
  json(): Promise<unknown>;
  text(): Promise<string>;
}

export class EscorteintimeAdapter implements MadameAdapter {
  readonly platform = DOMAIN;
  private readonly proxy: string;
  private readonly fetcher: ProxiedFetcher;

  constructor(
    private readonly sessionCache: SessionCache,
    options: EscorteintimeOptions,
  ) {
    this.proxy = buildBrightProxy(
      options.brightDataId,
      options.brightDataPass,
      'data_center',
      DOMAIN,
    );
    this.fetcher = options.fetcher ?? defaultProxiedFetch;
  }

  async toggleOnline(req: ToggleRequest): Promise<ToggleResult> {
    try {
      const sid = await this.getSessionId(req.credentials);
      const headers = this.fakeHeaders(USER_ENDPOINT, `NEXT_LOCALE=fr; sid=${sid}`);
      const now = new Date();

      const diff = await this.getOnlineDiff(sid, req.signal);
      const sleepMinutes = EVERY_MINUTES;

      if (diff < 0) {
        const onlineUntil = addMinutes(now, ONLINE_DURATION_MIN);
        await this.fetcher(USER_ENDPOINT, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({ online: onlineUntil.toISOString() }),
          proxy: this.proxy,
          signal: req.signal,
        });
        return {
          eventType: 'toggle_on',
          onlineUntil,
          payload: { from: 'offline', diffMin: diff },
          suggestedNextMs: minutesToMs(sleepMinutes),
        };
      }

      if (diff < ONLINE_DURATION_MIN - EVERY_MINUTES) {
        // Still online but stale — bump: toggle OFF then ON to refresh listing position.
        await this.fetcher(USER_ENDPOINT, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({ online: addMinutes(now, -1).toISOString() }),
          proxy: this.proxy,
          signal: req.signal,
        });
        const onlineUntil = addMinutes(now, ONLINE_DURATION_MIN);
        await this.fetcher(USER_ENDPOINT, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({ online: onlineUntil.toISOString() }),
          proxy: this.proxy,
          signal: req.signal,
        });
        return {
          eventType: 'toggle_bump',
          onlineUntil,
          payload: { from: 'online_stale', diffMin: diff },
          suggestedNextMs: minutesToMs(sleepMinutes),
        };
      }

      // Too fresh — skip and wait.
      const remainingMin = diff - (ONLINE_DURATION_MIN - EVERY_MINUTES);
      return {
        eventType: 'toggle_skip',
        onlineUntil: addMinutes(now, diff),
        payload: { reason: 'too_fresh', remainingMin },
        suggestedNextMs: minutesToMs(Math.max(remainingMin, 1)),
      };
    } catch (err) {
      return {
        eventType: 'error',
        error: err instanceof Error ? err.message : String(err),
        suggestedNextMs: minutesToMs(EVERY_MINUTES),
      };
    }
  }

  async getStatus(credentials?: Credentials): Promise<PlatformStatus> {
    if (!credentials) {
      // We need at least a cached session to read status.
      const cached = await this.sessionCache.get(SESSION_KEY);
      if (!cached) {
        return { isOnline: false, lastChecked: new Date() };
      }
      const diff = await this.getOnlineDiff(cached);
      return {
        isOnline: diff > 0,
        onlineUntil: diff > 0 ? addMinutes(new Date(), diff) : undefined,
        lastChecked: new Date(),
      };
    }
    const sid = await this.getSessionId(credentials);
    const diff = await this.getOnlineDiff(sid);
    return {
      isOnline: diff > 0,
      onlineUntil: diff > 0 ? addMinutes(new Date(), diff) : undefined,
      lastChecked: new Date(),
    };
  }

  async refreshSession(credentials: Credentials): Promise<boolean> {
    const sid = await this.generateSession(credentials);
    if (!sid) return false;
    await this.sessionCache.set(SESSION_KEY, sid, 60 * 60 * 12);
    return true;
  }

  // --- internals ---

  private async getSessionId(credentials: Credentials): Promise<string> {
    const cached = await this.sessionCache.get(SESSION_KEY);
    if (cached && SESSION_REGEX.test(cached)) return cached;
    const fresh = await this.generateSession(credentials);
    await this.sessionCache.set(SESSION_KEY, fresh, 60 * 60 * 12);
    return fresh;
  }

  private async generateSession(credentials: Credentials): Promise<string> {
    if (!credentials.email || !credentials.password) {
      throw new Error('escorteintime requires { type: "password", email, password }');
    }
    const headers = this.fakeHeaders(AUTH_ENDPOINT, 'NEXT_LOCALE=fr');
    const res = await this.fetcher(AUTH_ENDPOINT, {
      method: 'POST',
      headers,
      body: JSON.stringify({ email: credentials.email, password: credentials.password }),
      proxy: this.proxy,
    });
    if (!res.ok) {
      throw new Error(`escorteintime auth failed: ${res.status}`);
    }
    const setCookie = res.headers.get('set-cookie') ?? '';
    const sid = parseSidFromSetCookie(setCookie);
    if (!sid || !SESSION_REGEX.test(sid)) {
      throw new Error(`escorteintime returned malformed session id: ${sid}`);
    }
    return sid;
  }

  private async getOnlineDiff(sid: string, signal?: AbortSignal): Promise<number> {
    const headers = this.fakeHeaders(USER_ENDPOINT, `NEXT_LOCALE=fr; sid=${sid}`);
    const res = await this.fetcher(USER_ENDPOINT, {
      method: 'GET',
      headers,
      proxy: this.proxy,
      signal,
    });
    if (!res.ok) {
      throw new Error(`escorteintime /api/user failed: ${res.status}`);
    }
    const body = (await res.json()) as { online?: string };
    if (!body.online) throw new Error('escorteintime /api/user missing online field');
    const onlineDate = new Date(body.online);
    const now = new Date();
    return Math.floor((onlineDate.getTime() - now.getTime()) / 60000);
  }

  private fakeHeaders(url: string, cookie?: string): Record<string, string> {
    const u = new URL(url);
    return {
      accept: '*/*',
      'accept-encoding': 'gzip, deflate, br',
      'accept-language': 'fr-CA,en;q=0.9',
      'content-type': 'application/json',
      ...(cookie ? { cookie } : {}),
      origin: u.origin,
      referer: u.toString(),
      'sec-ch-ua': '"Chromium";v="118", "Google Chrome";v="118", "Not=A?Brand";v="99"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': 'Windows',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
      'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
    };
  }
}

// --- helpers ---

function buildBrightProxy(
  id: string,
  pass: string,
  service: 'data_center' | 'unblocker',
  sessionName: string,
): string {
  const username = [
    'brd-customer',
    id,
    'zone',
    service,
    'session',
    sessionName,
  ].join('-');
  return `https://${username}:${pass}@brd.superproxy.io:22225`;
}

function addMinutes(date: Date, minutes: number): Date {
  return new Date(date.getTime() + minutes * 60_000);
}

function minutesToMs(min: number): number {
  return Math.max(0, Math.floor(min)) * 60_000;
}

/** Extracts the first cookie value from a Set-Cookie header. */
function parseSidFromSetCookie(setCookie: string): string | null {
  if (!setCookie) return null;
  const first = setCookie.split(',')[0] ?? '';
  const eq = first.indexOf('=');
  const semi = first.indexOf(';');
  if (eq < 0) return null;
  const end = semi < 0 ? first.length : semi;
  return first.slice(eq + 1, end).trim() || null;
}

/**
 * Default proxied fetch — dynamically loads node-fetch + https-proxy-agent.
 * Tests inject `options.fetcher`; production runs this on Node serverless.
 */
const defaultProxiedFetch: ProxiedFetcher = async (url, init) => {
  const [{ default: nodeFetch }, { HttpsProxyAgent }] = await Promise.all([
    import('node-fetch'),
    import('https-proxy-agent'),
  ]);
  const agent = new HttpsProxyAgent(init.proxy);
  // escorteintime cert chain via Bright proxy is sometimes incomplete.
  // The original code disabled cert verification globally; we scope it here.
  (agent as unknown as { options?: { rejectUnauthorized?: boolean } }).options = {
    ...((agent as unknown as { options?: Record<string, unknown> }).options ?? {}),
    rejectUnauthorized: false,
  };
  const res = await (nodeFetch as unknown as (
    u: string,
    o: Record<string, unknown>,
  ) => Promise<{
    ok: boolean;
    status: number;
    headers: { get(name: string): string | null };
    json(): Promise<unknown>;
    text(): Promise<string>;
  }>)(url, {
    method: init.method,
    headers: init.headers,
    body: init.body,
    agent,
    signal: init.signal,
  });
  return res;
};
