import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sendEscalation } from '../src/server/telegram';

test('sendEscalation posts truncated transcript with previews disabled', async () => {
  let captured: { url: string; body: Record<string, unknown> } | null = null;
  const fakeFetch = (async (url: string | URL | Request, init?: RequestInit) => {
    captured = { url: String(url), body: JSON.parse(String(init?.body)) };
    return new Response('{"ok":true}', { status: 200 });
  }) as typeof fetch;

  await sendEscalation(
    { telegramBotToken: 'TOK', chatId: '42' },
    'x'.repeat(5000),
    'user stuck',
    'EZViet',
    fakeFetch
  );
  assert.ok(captured, 'fetch not called');
  const c = captured as { url: string; body: Record<string, unknown> };
  assert.ok(c.url.includes('botTOK/sendMessage'));
  assert.equal(c.body.chat_id, '42');
  assert.equal(c.body.disable_web_page_preview, true);
  const text = String(c.body.text);
  assert.ok(text.length <= 3900);
  assert.ok(text.includes('user stuck'));
  assert.ok(text.includes('EZViet'));
});
