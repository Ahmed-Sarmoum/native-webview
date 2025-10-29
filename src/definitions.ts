import { registerPlugin } from '@capacitor/core';

export interface NativeWebviewPlugin {
  /**
   * Open a URL in a native webview (iOS only)
   * @param options - Configuration for the webview
   * @returns Promise that resolves when webview is opened
   */
  open(options: OpenWebviewOptions): Promise<{ url?: string }>;

  /**
   * Close the currently open webview
   */
  close(): Promise<void>;

  /**
   * Add a listener for webview events
   */
  addListener(eventName: 'urlChanged', listenerFunc: (info: { url: string }) => void): Promise<PluginListenerHandle>;

  addListener(eventName: 'closed', listenerFunc: () => void): Promise<PluginListenerHandle>;

  addListener(eventName: 'reload', listenerFunc: () => void): Promise<PluginListenerHandle>;

  addListener(eventName: 'next', listenerFunc: () => void): Promise<PluginListenerHandle>;

  /**
   * Remove all listeners for this plugin
   */
  removeAllListeners(): Promise<void>;
}

export interface OpenWebviewOptions {
  /**
   * The URL to load in the webview
   */
  url: string;

  /**
   * Title for the navigation bar (iOS only)
   */
  title?: string;

  /**
   * Show a done/close button (default: true)
   */
  showCloseButton?: boolean;

  /**
   * Close button text (default: "Done")
   */
  closeButtonText?: string;

  /**
   * Enable toolbar with navigation controls (default: false)
   */
  toolbarEnabled?: boolean;

  /**
   * Color for toolbar and navigation bar (hex format)
   */
  toolbarColor?: string;

  /**
   * Allow clearing cookies before loading (default: false)
   */
  clearCookies?: boolean;
}

export interface PluginListenerHandle {
  remove: () => Promise<void>;
}

const NativeWebview = registerPlugin<NativeWebviewPlugin>('NativeWebview');

export default NativeWebview;
