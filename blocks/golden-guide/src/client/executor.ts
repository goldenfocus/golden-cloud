import type { GuideFlow, WireToolCall } from '../shared/types';

export interface ExecutorDeps {
  navigate: (path: string) => void;
  doc: Document;
  onSay: (text: string) => void; // narration lines appended to the chat
  wait?: (ms: number) => Promise<void>;
}

const defaultWait = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/** Executes a server-validated tool call in the browser. Always returns an honest result string
 * (the model is told the truth, including failures). */
export async function executeToolCall(
  call: WireToolCall,
  flows: GuideFlow[],
  deps: ExecutorDeps
): Promise<string> {
  const wait = deps.wait ?? defaultWait;
  switch (call.name) {
    case 'navigate_to':
      deps.navigate(call.args.path);
      return `navigated to ${call.args.path}`;
    case 'highlight': {
      if (call.args.say) deps.onSay(call.args.say);
      return highlightElement(deps.doc, call.args.agentId);
    }
    case 'run_flow': {
      const flow = flows.find((f) => f.id === call.args.flowId);
      if (!flow) return `flow not found: ${call.args.flowId}`;
      for (const step of flow.steps) {
        deps.onSay(step.say);
        if ('navigate' in step) {
          deps.navigate(step.navigate);
          await wait(900);
        } else if ('highlight' in step) {
          await wait(300);
          highlightElement(deps.doc, step.highlight);
          await wait(1600);
        } else {
          await wait(900);
        }
      }
      return `flow ${flow.id} completed`;
    }
    case 'escalate_to_support':
      return 'escalation sent'; // executed server-side; client just records it
    default:
      return `unknown tool: ${call.name}`;
  }
}

export function highlightElement(doc: Document, agentId: string): string {
  ensureStyles(doc);
  const el = doc.querySelector(`[data-agent-id="${agentId}"]`);
  if (!el) return `element not found: ${agentId}`;
  el.scrollIntoView({ behavior: 'smooth', block: 'center' });
  el.classList.add('gg-glow');
  setTimeout(() => el.classList.remove('gg-glow'), 2600);
  return `highlighted ${agentId}`;
}

/** One-time injected stylesheet: the glow animation the widget applies to highlighted elements. */
export function ensureStyles(doc: Document): void {
  if (doc.getElementById('gg-styles')) return;
  const style = doc.createElement('style');
  style.id = 'gg-styles';
  style.textContent = `
@keyframes gg-pulse {
  0%, 100% { box-shadow: 0 0 0 3px rgba(16,185,129,.9), 0 0 24px 6px rgba(16,185,129,.45); }
  50% { box-shadow: 0 0 0 6px rgba(16,185,129,.55), 0 0 36px 10px rgba(16,185,129,.3); }
}
.gg-glow { animation: gg-pulse 1.2s ease-in-out 2; border-radius: 8px; }`;
  doc.head.appendChild(style);
}
