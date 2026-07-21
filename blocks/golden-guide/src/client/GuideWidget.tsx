'use client';

import { useEffect, useRef, useState } from 'react';
import type { GuideFlow } from '../shared/types';
import { useGuideChat } from './useGuideChat';

export interface GuideWidgetProps {
  endpoint?: string;
  flows: GuideFlow[];
  navigate: (path: string) => void;
  appName: string;
  tourFlowId?: string;
  greeting?: string;
}

export function GuideWidget({
  endpoint = '/api/guide',
  flows,
  navigate,
  appName,
  tourFlowId,
  greeting,
}: GuideWidgetProps) {
  const [open, setOpen] = useState(false);
  const [draft, setDraft] = useState('');
  const { items, busy, send, runLocalFlow } = useGuideChat({ endpoint, flows, navigate });
  const listRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    listRef.current?.scrollTo({ top: listRef.current.scrollHeight, behavior: 'smooth' });
  }, [items, busy]);

  const submit = () => {
    void send(draft);
    setDraft('');
  };

  return (
    <div className="fixed bottom-20 right-4 z-50 flex flex-col items-end sm:bottom-6">
      {open && (
        <div className="mb-3 flex h-[28rem] w-[calc(100vw-2rem)] max-w-sm flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl">
          <div className="flex items-center justify-between bg-emerald-600 px-4 py-3">
            <p className="text-sm font-semibold text-white">{appName} Guide</p>
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Close guide"
              className="rounded-full px-2 py-1 text-sm font-medium text-emerald-100 hover:bg-emerald-700 hover:text-white"
            >
              ✕
            </button>
          </div>
          <div ref={listRef} className="flex-1 space-y-2 overflow-y-auto px-3 py-3">
            {items.length === 0 && (
              <div className="space-y-2">
                <p className="text-sm text-gray-700">
                  {greeting ?? `Hi! Ask me anything about ${appName} — I can take you there and show you.`}
                </p>
                {tourFlowId && (
                  <button
                    type="button"
                    onClick={() => void runLocalFlow(tourFlowId)}
                    className="rounded-full border border-emerald-300 bg-emerald-50 px-3 py-1.5 text-sm font-medium text-emerald-800 hover:bg-emerald-100"
                  >
                    ✨ Show me around
                  </button>
                )}
              </div>
            )}
            {items.map((item, i) => (
              <div key={i} className={item.role === 'user' ? 'flex justify-end' : 'flex justify-start'}>
                <p
                  className={
                    item.role === 'user'
                      ? 'max-w-[85%] rounded-2xl rounded-br-sm bg-emerald-600 px-3 py-2 text-sm text-white'
                      : 'max-w-[85%] rounded-2xl rounded-bl-sm bg-gray-100 px-3 py-2 text-sm text-gray-900'
                  }
                >
                  {item.text}
                </p>
              </div>
            ))}
            {busy && <p className="text-sm text-gray-600">…</p>}
          </div>
          <div className="flex items-center gap-2 border-t border-gray-200 px-3 py-2">
            <input
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') submit();
              }}
              placeholder="Ask me anything…"
              className="min-w-0 flex-1 rounded-full border border-gray-300 bg-white px-3 py-2 text-base text-gray-900 placeholder:text-gray-500 focus:border-emerald-500 focus:outline-none"
            />
            <button
              type="button"
              onClick={submit}
              disabled={busy || !draft.trim()}
              className="rounded-full bg-emerald-600 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
            >
              Send
            </button>
          </div>
          <p className="border-t border-gray-100 px-3 py-1.5 text-center text-xs text-gray-600">
            Guided by{' '}
            <a
              href="https://github.com/goldenfocus/golden-cloud/tree/main/blocks/golden-guide"
              target="_blank"
              rel="noreferrer"
              className="font-medium text-emerald-700 hover:underline"
            >
              golden-guide
            </a>
          </p>
        </div>
      )}
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-label={open ? 'Close guide' : 'Open guide'}
        className="flex h-14 w-14 items-center justify-center rounded-full bg-emerald-600 text-2xl text-white shadow-lg hover:bg-emerald-700"
      >
        {open ? '✕' : '💬'}
      </button>
    </div>
  );
}
