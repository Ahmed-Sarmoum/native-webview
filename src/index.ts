import { registerPlugin } from '@capacitor/core';
import type { NativeWebviewPlugin } from './definitions';

const NativeWebview = registerPlugin<NativeWebviewPlugin>('CapacitorIosNativeWebview', {
  web: () => import('./web').then((m) => new m.NativeWebviewWeb()),
});

export * from './definitions';
export { NativeWebview };
