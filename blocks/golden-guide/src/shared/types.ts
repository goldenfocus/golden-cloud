// golden-guide shared types: config + wire protocol (browser <-> /api/guide).

export interface BrainConfig {
  baseURL: string; // OpenAI-compatible, e.g. https://api.openai.com/v1
  apiKey?: string;
  model: string;
}

export interface RouteEntry {
  path: string;
  description: string;
}

export type FlowStep =
  | { navigate: string; say: string }
  | { highlight: string; say: string } // highlight = data-agent-id
  | { say: string };

export interface GuideFlow {
  id: string;
  title: string;
  triggers: string[]; // example user phrasings, shown to the model
  steps: FlowStep[];
}

export interface GuideLimits {
  maxToolIterations: number; // tool rounds per user turn
  maxMessages: number;
  maxInputChars: number;
  perIpPerMinute: number;
  escalationsPerSession: number;
}

export interface GuideConfig {
  brain: BrainConfig;
  appName: string;
  voice: string; // brand voice, injected into system prompt
  kb: string; // markdown, inlined into system prompt
  flows: GuideFlow[];
  routes: RouteEntry[]; // navigate_to allowlist
  secret?: string; // HMAC key for tool-call IDs; defaults to hash of brain.apiKey
  escalate?: { telegramBotToken: string; chatId: string };
  limits?: Partial<GuideLimits>;
  disabled?: boolean;
}

// ---- wire protocol ----

export interface SnapshotElement {
  id: string;
  tag: string;
  label: string;
}

export interface PageSnapshot {
  route: string;
  elements: SnapshotElement[];
}

export interface WireToolCall {
  callId: string; // minted + HMAC-signed by the server
  name: string;
  args: Record<string, string>;
}

export type WireMessage =
  | { role: 'user'; content: string }
  | { role: 'assistant'; content: string; toolCalls?: WireToolCall[] }
  | { role: 'tool_result'; callId: string; name: string; result: string };

export interface GuideRequest {
  messages: WireMessage[];
  snapshot: PageSnapshot;
}

export interface GuideResponse {
  message: string;
  toolCalls: WireToolCall[];
  error?: string;
}
