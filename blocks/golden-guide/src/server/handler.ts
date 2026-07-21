import type {
  GuideConfig,
  GuideLimits,
  GuideRequest,
  GuideResponse,
  PageSnapshot,
  WireMessage,
  WireToolCall,
} from '../shared/types';
import { buildSystemPrompt } from './prompt';
import { buildToolDefs } from './tools';
import { validateToolCall } from './validate';
import { deriveSecret, mintCallId, verifyCallId } from './security';
import { countToolRounds, RateLimiter, totalChars } from './limits';
import { sendEscalation } from './telegram';

const DEFAULT_LIMITS: GuideLimits = {
  maxToolIterations: 4,
  maxMessages: 30,
  maxInputChars: 24_000,
  perIpPerMinute: 10,
  escalationsPerSession: 3,
};

export interface HandlerDeps {
  fetchFn?: typeof fetch;
}

interface BrainToolCall {
  id?: string;
  function?: { name?: string; arguments?: string };
}

interface BrainMessage {
  content?: string | null;
  tool_calls?: BrainToolCall[];
}

interface BrainCompletion {
  choices?: Array<{ message?: BrainMessage }>;
}

function json(body: GuideResponse, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

export function createGuideHandler(config: GuideConfig, deps: HandlerDeps = {}) {
  const fetchFn = deps.fetchFn ?? fetch;
  const limits = { ...DEFAULT_LIMITS, ...config.limits };
  const secret = config.secret ?? deriveSecret(config.brain.apiKey ?? 'golden-guide');
  const ipLimiter = new RateLimiter(limits.perIpPerMinute, 60_000);
  const escalationLimiter = new RateLimiter(1, 60_000);

  return async function handleGuideRequest(req: Request): Promise<Response> {
    if (config.disabled) {
      return json({ message: 'The guide is resting right now — try again a bit later!', toolCalls: [] });
    }
    const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown';
    if (!ipLimiter.allow(ip)) {
      return json({ message: 'Whoa, easy there! Give me a minute to catch up.', toolCalls: [] }, 429);
    }

    let body: GuideRequest;
    try {
      body = (await req.json()) as GuideRequest;
    } catch {
      return json({ message: '', toolCalls: [], error: 'invalid JSON' }, 400);
    }
    const shapeError = validateShape(body, limits, secret);
    if (shapeError) return json({ message: '', toolCalls: [], error: shapeError }, 400);

    if (countToolRounds(body.messages) >= limits.maxToolIterations) {
      return json({
        message: "Let's pause there — tell me what you'd like next, or I can bring in a human.",
        toolCalls: [],
      });
    }

    let completion: BrainCompletion;
    try {
      completion = await callBrain(config, body, fetchFn);
    } catch {
      return json({ message: 'My brain is briefly unreachable — try again in a moment?', toolCalls: [] }, 502);
    }

    const msg = completion.choices?.[0]?.message ?? {};
    const text = typeof msg.content === 'string' ? msg.content : '';
    const outCalls: WireToolCall[] = [];

    for (const raw of msg.tool_calls ?? []) {
      let args: Record<string, unknown> = {};
      try {
        args = JSON.parse(raw.function?.arguments ?? '{}') as Record<string, unknown>;
      } catch {
        continue;
      }
      const v = validateToolCall({ name: raw.function?.name ?? '', args }, config, body.snapshot);
      if (!v.ok) continue;

      if (v.name === 'escalate_to_support') {
        const already = body.messages.filter(
          (m) => m.role === 'tool_result' && m.name === 'escalate_to_support'
        ).length;
        if (already >= limits.escalationsPerSession || !escalationLimiter.allow(ip)) continue;
        if (config.escalate) {
          try {
            await sendEscalation(
              config.escalate,
              transcriptOf(body.messages),
              v.args.reason,
              config.appName,
              fetchFn
            );
          } catch (error) {
            console.error('golden-guide: escalation failed', error);
            continue;
          }
        }
      }
      outCalls.push({ callId: mintCallId(v.name, secret), name: v.name, args: v.args });
    }

    return json({ message: text, toolCalls: outCalls });
  };
}

function validateShape(body: GuideRequest, limits: GuideLimits, secret: string): string | null {
  if (!body || !Array.isArray(body.messages)) return 'messages required';
  if (body.messages.length === 0 || body.messages.length > limits.maxMessages)
    return 'message count out of range';
  if (!isSnapshot(body.snapshot)) return 'invalid snapshot';
  for (const m of body.messages) {
    if (m.role === 'user' || m.role === 'assistant') {
      if (typeof m.content !== 'string') return 'invalid message content';
    } else if (m.role === 'tool_result') {
      if (typeof m.result !== 'string' || typeof m.callId !== 'string') return 'invalid tool_result';
      if (!verifyCallId(m.callId, m.name, secret)) return 'unrecognized tool_result';
    } else {
      return 'invalid role'; // includes client-supplied "system"
    }
  }
  if (totalChars(body.messages) > limits.maxInputChars) return 'input too large';
  return null;
}

function isSnapshot(s: PageSnapshot): boolean {
  return (
    !!s &&
    typeof s.route === 'string' &&
    s.route.length <= 200 &&
    Array.isArray(s.elements) &&
    s.elements.length <= 100 &&
    s.elements.every(
      (e) =>
        typeof e.id === 'string' &&
        typeof e.tag === 'string' &&
        typeof e.label === 'string' &&
        e.id.length <= 100 &&
        e.label.length <= 100
    )
  );
}

async function callBrain(
  config: GuideConfig,
  body: GuideRequest,
  fetchFn: typeof fetch
): Promise<BrainCompletion> {
  const messages: Array<Record<string, unknown>> = [
    { role: 'system', content: buildSystemPrompt(config, body.snapshot) },
  ];
  for (const m of body.messages) {
    if (m.role === 'user') {
      messages.push({ role: 'user', content: m.content });
    } else if (m.role === 'assistant') {
      messages.push({
        role: 'assistant',
        content: m.content,
        ...(m.toolCalls?.length
          ? {
              tool_calls: m.toolCalls.map((tc) => ({
                id: tc.callId,
                type: 'function',
                function: { name: tc.name, arguments: JSON.stringify(tc.args) },
              })),
            }
          : {}),
      });
    } else {
      messages.push({ role: 'tool', tool_call_id: m.callId, content: m.result });
    }
  }
  const res = await fetchFn(`${config.brain.baseURL}/chat/completions`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(config.brain.apiKey ? { authorization: `Bearer ${config.brain.apiKey}` } : {}),
    },
    body: JSON.stringify({
      model: config.brain.model,
      messages,
      tools: buildToolDefs(config),
      temperature: 0.3,
      max_tokens: 400,
    }),
  });
  if (!res.ok) throw new Error(`brain ${res.status}`);
  return (await res.json()) as BrainCompletion;
}

function transcriptOf(messages: WireMessage[]): string {
  return messages
    .map((m) =>
      m.role === 'tool_result' ? `[tool ${m.name}: ${m.result}]` : `${m.role}: ${m.content}`
    )
    .join('\n');
}
