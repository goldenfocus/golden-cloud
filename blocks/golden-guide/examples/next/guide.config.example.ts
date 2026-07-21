// Shared (server + client safe — no secrets here). Vendored path shown as lib/golden-guide.
import type { GuideFlow, RouteEntry } from '../../src/shared/types';

export const guideRoutes: RouteEntry[] = [
  { path: '/', description: 'Home' },
  { path: '/pricing', description: 'Plans and pricing' },
];

export const guideFlows: GuideFlow[] = [
  {
    id: 'tour',
    title: 'Quick tour of the app',
    triggers: ['show me around', 'what can I do here'],
    steps: [
      { say: 'Welcome! Let me show you around.' },
      { navigate: '/pricing', say: 'Here are the plans.' },
    ],
  },
];

export const guideVoice = 'warm, confident, lightly playful';
