import type { GuideConfig } from '../shared/types';

export interface ToolDef {
  type: 'function';
  function: {
    name: string;
    description: string;
    parameters: {
      type: 'object';
      properties: Record<string, unknown>;
      required: string[];
    };
  };
}

/** Allowlists are baked into the schemas as enums — small models call far more reliably
 * when the valid values are visible in the schema itself. */
export function buildToolDefs(config: GuideConfig): ToolDef[] {
  return [
    {
      type: 'function',
      function: {
        name: 'run_flow',
        description:
          'Run a scripted guided flow that navigates and highlights for the user. Prefer this whenever a flow matches the question.',
        parameters: {
          type: 'object',
          properties: { flowId: { type: 'string', enum: config.flows.map((f) => f.id) } },
          required: ['flowId'],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'navigate_to',
        description: 'Navigate the app to one of the allowed routes.',
        parameters: {
          type: 'object',
          properties: { path: { type: 'string', enum: config.routes.map((r) => r.path) } },
          required: ['path'],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'highlight',
        description:
          'Scroll to and visually highlight an element on the CURRENT page, by its agent id from the page snapshot.',
        parameters: {
          type: 'object',
          properties: {
            agentId: { type: 'string' },
            say: { type: 'string', description: 'Optional short narration shown while highlighting.' },
          },
          required: ['agentId'],
        },
      },
    },
    {
      type: 'function',
      function: {
        name: 'escalate_to_support',
        description:
          'Send this conversation to a human. Use when you cannot help or the user asks for a person.',
        parameters: {
          type: 'object',
          properties: { reason: { type: 'string' } },
          required: ['reason'],
        },
      },
    },
  ];
}
