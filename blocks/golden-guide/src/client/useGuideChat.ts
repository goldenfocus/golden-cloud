'use client';

import { useCallback, useRef, useState } from 'react';
import type { GuideFlow, GuideResponse, WireMessage } from '../shared/types';
import { collectSnapshot } from './snapshot';
import { executeToolCall } from './executor';

export interface ChatItem {
  role: 'user' | 'guide';
  text: string;
}

export interface UseGuideChatOptions {
  endpoint: string;
  flows: GuideFlow[];
  navigate: (path: string) => void;
}

const SNAG = 'Hmm, I hit a snag — mind trying that again?';
const MAX_CLIENT_ROUNDS = 5;

export function useGuideChat(opts: UseGuideChatOptions) {
  const [items, setItems] = useState<ChatItem[]>([]);
  const [busy, setBusy] = useState(false);
  const historyRef = useRef<WireMessage[]>([]);

  const say = useCallback((text: string) => {
    if (text) setItems((cur) => [...cur, { role: 'guide', text }]);
  }, []);

  const send = useCallback(
    async (text: string) => {
      const trimmed = text.trim();
      if (!trimmed || busy) return;
      setBusy(true);
      setItems((cur) => [...cur, { role: 'user', text: trimmed }]);
      historyRef.current.push({ role: 'user', content: trimmed });
      try {
        for (let round = 0; round < MAX_CLIENT_ROUNDS; round++) {
          const snapshot = collectSnapshot(document, window.location.pathname);
          const res = await fetch(opts.endpoint, {
            method: 'POST',
            headers: { 'content-type': 'application/json' },
            body: JSON.stringify({ messages: historyRef.current, snapshot }),
          });
          if (!res.ok) {
            say(SNAG);
            break;
          }
          const data = (await res.json()) as GuideResponse;
          historyRef.current.push({
            role: 'assistant',
            content: data.message,
            ...(data.toolCalls.length ? { toolCalls: data.toolCalls } : {}),
          });
          say(data.message);
          if (!data.toolCalls.length) break;
          for (const call of data.toolCalls) {
            const result = await executeToolCall(call, opts.flows, {
              navigate: opts.navigate,
              doc: document,
              onSay: say,
            });
            historyRef.current.push({
              role: 'tool_result',
              callId: call.callId,
              name: call.name,
              result,
            });
          }
        }
      } catch {
        say(SNAG); // network hiccups (device sleep etc.) get the same friendly retry line
      } finally {
        setBusy(false);
      }
    },
    [busy, opts, say]
  );

  /** Runs a flow entirely client-side (zero brain cost) — used by the "Show me around" chip. */
  const runLocalFlow = useCallback(
    async (flowId: string) => {
      if (busy) return;
      setBusy(true);
      try {
        await executeToolCall(
          { callId: 'local', name: 'run_flow', args: { flowId } },
          opts.flows,
          { navigate: opts.navigate, doc: document, onSay: say }
        );
      } finally {
        setBusy(false);
      }
    },
    [busy, opts, say]
  );

  return { items, busy, send, runLocalFlow };
}
