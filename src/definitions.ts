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
   * Show a custom styled alert dialog (matches your app design)
   * @param options.message - The message to display
   * @param options.type - The type of alert (info, success, error, warning)
   * @param options.buttonText - Custom text for the OK button (default: "OK")
   */
  showCustomAlert(options: {
    message: string;
    type?: 'info' | 'success' | 'error' | 'warning';
    buttonText?: string;
  }): Promise<void>;

  /**
   * Show a standard system alert
   */
  showAlert(options: { title?: string; message: string }): Promise<void>;

  /**
   * Show a success alert (uses custom styling)
   */
  showSuccess(options: { message: string; buttonText?: string }): Promise<void>;

  /**
   * Show an error alert (uses custom styling)
   */
  showError(options: { message: string; buttonText?: string }): Promise<void>;

  /**
   * Show a warning alert (uses custom styling)
   */
  showWarning(options: { message: string; buttonText?: string }): Promise<void>;

  /**
   * Show a loading overlay
   */
  showLoading(options?: { message?: string }): Promise<void>;

  /**
   * Hide the loading overlay
   */
  hideLoading(): Promise<void>;

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
   * Next button text
   */
  nextBtnText?: string;

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
