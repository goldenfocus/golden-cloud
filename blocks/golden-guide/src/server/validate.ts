import type { GuideConfig, PageSnapshot } from '../shared/types';

export interface RawToolCall {
  name: string;
  args: Record<string, unknown>;
}

export type ValidationResult =
  | { ok: true; name: string; args: Record<string, string> }
  | { ok: false; error: string };

function str(v: unknown): string | null {
  return typeof v === 'string' && v.length > 0 && v.length <= 500 ? v : null;
}

/** Every model tool call passes through here before leaving the server. The tool layer IS the sandbox. */
export function validateToolCall(
  raw: RawToolCall,
  config: GuideConfig,
  snapshot: PageSnapshot
): ValidationResult {
  switch (raw.name) {
    case 'navigate_to': {
      const path = str(raw.args.path);
      if (!path) return { ok: false, error: 'navigate_to: path must be a string' };
      if (!config.routes.some((r) => r.path === path))
        return { ok: false, error: `navigate_to: ${path} not in allowlist` };
      return { ok: true, name: raw.name, args: { path } };
    }
    case 'highlight': {
      const agentId = str(raw.args.agentId);
      if (!agentId) return { ok: false, error: 'highlight: agentId must be a string' };
      if (!snapshot.elements.some((e) => e.id === agentId))
        return { ok: false, error: `highlight: ${agentId} not on current page` };
      const say = str(raw.args.say);
      return { ok: true, name: raw.name, args: say ? { agentId, say } : { agentId } };
    }
    case 'run_flow': {
      const flowId = str(raw.args.flowId);
      if (!flowId) return { ok: false, error: 'run_flow: flowId must be a string' };
      if (!config.flows.some((f) => f.id === flowId))
        return { ok: false, error: `run_flow: unknown flow ${flowId}` };
      return { ok: true, name: raw.name, args: { flowId } };
    }
    case 'escalate_to_support': {
      const reason = str(raw.args.reason) ?? 'unspecified';
      return { ok: true, name: raw.name, args: { reason } };
    }
    default:
      return { ok: false, error: `unknown tool: ${raw.name}` };
  }
}
