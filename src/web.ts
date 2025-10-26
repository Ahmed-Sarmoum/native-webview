import { WebPlugin } from '@capacitor/core';

import type { NativeWebiewPlugin } from './definitions';

export class NativeWebiewWeb extends WebPlugin implements NativeWebiewPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
