import type { WireMessage } from '../shared/types';

/** In-memory sliding-window limiter. Per serverless instance — a real but imperfect guard;
 * combine with per-request caps. */
export class RateLimiter {
  private hits = new Map<string, number[]>();

  constructor(
    private max: number,
    private windowMs: number
  ) {}

  allow(key: string, now = Date.now()): boolean {
    const cutoff = now - this.windowMs;
    const recent = (this.hits.get(key) ?? []).filter((t) => t > cutoff);
    if (recent.length >= this.max) {
      this.hits.set(key, recent);
      return false;
    }
    recent.push(now);
    this.hits.set(key, recent);
    if (this.hits.size > 5000) this.hits.clear(); // memory backstop
    return true;
  }
}

/** Tool rounds since the last user message (iteration cap input). */
export function countToolRounds(messages: WireMessage[]): number {
  let rounds = 0;
  for (let i = messages.length - 1; i >= 0; i--) {
    const m = messages[i];
    if (m.role === 'user') break;
    if (m.role === 'assistant' && m.toolCalls && m.toolCalls.length > 0) rounds++;
  }
  return rounds;
}

export function totalChars(messages: WireMessage[]): number {
  return messages.reduce(
    (n, m) => n + (m.role === 'tool_result' ? m.result.length : m.content.length),
    0
  );
}
