import { registerPlugin } from '@capacitor/core';

import type { NativeWebiewPlugin } from './definitions';

const NativeWebiew = registerPlugin<NativeWebiewPlugin>('NativeWebiew', {
  web: () => import('./web').then((m) => new m.NativeWebiewWeb()),
});

export * from './definitions';
export { NativeWebiew };
