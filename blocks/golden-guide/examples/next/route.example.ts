// app/api/guide/route.ts in the host app.
import { createGuideHandler } from '@/lib/golden-guide/server/handler';
import { guideFlows, guideRoutes, guideVoice } from '@/lib/guide/config';
import { guideKb } from '@/lib/guide/kb';

const handler = createGuideHandler({
  appName: 'MyApp',
  voice: guideVoice,
  kb: guideKb,
  flows: guideFlows,
  routes: guideRoutes,
  brain: {
    baseURL: process.env.GUIDE_BRAIN_BASE_URL ?? 'https://api.openai.com/v1',
    apiKey: process.env.GUIDE_BRAIN_API_KEY ?? process.env.OPENAI_API_KEY,
    model: process.env.GUIDE_BRAIN_MODEL ?? 'gpt-4o-mini',
  },
  escalate:
    process.env.GUIDE_TELEGRAM_BOT_TOKEN && process.env.GUIDE_TELEGRAM_CHAT_ID
      ? {
          telegramBotToken: process.env.GUIDE_TELEGRAM_BOT_TOKEN,
          chatId: process.env.GUIDE_TELEGRAM_CHAT_ID,
        }
      : undefined,
  disabled: process.env.GUIDE_DISABLED === '1',
});

export async function POST(request: Request) {
  return handler(request);
}
