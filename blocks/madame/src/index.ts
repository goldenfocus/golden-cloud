/**
 * Default entry — re-exports MadameEngine and the type surface.
 * Adapters are imported separately via `@golden/madame/adapters/<platform>`.
 */
export {
  MadameEngine,
  MadameLogger,
  encryptCredentials,
  decryptCredentials,
} from './engine/index';
export type {
  Credentials,
  MadameAdapter,
  PlatformStatus,
  SessionCache,
  ToggleEventType,
  ToggleRequest,
  ToggleResult,
} from './core/types';
