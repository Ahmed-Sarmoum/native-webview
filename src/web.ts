import { WebPlugin } from '@capacitor/core';

import type { NativeWebviewPlugin, OpenWebviewOptions, PluginListenerHandle } from './definitions';

export class NativeWebviewWeb extends WebPlugin implements NativeWebviewPlugin {
  async open(options: OpenWebviewOptions): Promise<{ url?: string }> {
    console.log('Opening URL in new window (web fallback):', options.url);

    // Web fallback: open in new window/tab
    // const width = 800;
    // const height = 600;
    // const left = (screen.width - width) / 2;
    // const top = (screen.height - height) / 2;

    // this.webviewWindow = window.open(
    //   options.url,
    //   '_blank',
    //   `width=${width},height=${height},left=${left},top=${top},resizable=yes,scrollbars=yes`,
    // );

    // if (!this.webviewWindow) {
    //   throw new Error('Failed to open window. Please check popup blocker settings.');
    // }

    return { url: options.url };
  }

  async close(): Promise<void> {
    // if (this.webviewWindow && !this.webviewWindow.closed) {
    //   this.webviewWindow.close();
    //   this.webviewWindow = null;
    // }
  }

  async addListener(
    eventName: 'urlChanged',
    listenerFunc: (info: { url: string }) => void,
  ): Promise<PluginListenerHandle>;
  async addListener(eventName: 'closed', listenerFunc: () => void): Promise<PluginListenerHandle>;
  async addListener(_eventName: string, _listenerFunc: any): Promise<PluginListenerHandle> {
    // Web implementation doesn't support native events
    return {
      remove: async () => {
        // No-op
      },
    };
  }

  async removeAllListeners(): Promise<void> {
    // No-op for web implementation
  }
}
