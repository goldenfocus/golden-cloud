export interface EscalateTarget {
  telegramBotToken: string;
  chatId: string;
}

const MAX_TRANSCRIPT = 3500;

export async function sendEscalation(
  target: EscalateTarget,
  transcript: string,
  reason: string,
  appName: string,
  fetchFn: typeof fetch = fetch
): Promise<void> {
  const clipped =
    transcript.length > MAX_TRANSCRIPT ? `…${transcript.slice(-MAX_TRANSCRIPT)}` : transcript;
  const text = `🆘 ${appName} guide escalation\nReason: ${reason.slice(0, 200)}\n\n${clipped}`;
  const res = await fetchFn(
    `https://api.telegram.org/bot${target.telegramBotToken}/sendMessage`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        chat_id: target.chatId,
        text,
        disable_web_page_preview: true,
      }),
    }
  );
  if (!res.ok) throw new Error(`telegram escalation failed: ${res.status}`);
}
