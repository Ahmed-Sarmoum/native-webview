# native-webview

A Capacitor Native Webview

## Install

```bash
npm install native-webview
npx cap sync
```

## API

<docgen-index>

* [`open(...)`](#open)
* [`close()`](#close)
* [`addListener('urlChanged', ...)`](#addlistenerurlchanged-)
* [`addListener('closed', ...)`](#addlistenerclosed-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### open(...)

```typescript
open(options: OpenWebviewOptions) => Promise<{ url?: string; }>
```

Open a URL in a native webview (iOS only)

| Param         | Type                                                              | Description                     |
| ------------- | ----------------------------------------------------------------- | ------------------------------- |
| **`options`** | <code><a href="#openwebviewoptions">OpenWebviewOptions</a></code> | - Configuration for the webview |

**Returns:** <code>Promise&lt;{ url?: string; }&gt;</code>

--------------------


### close()

```typescript
close() => Promise<void>
```

Close the currently open webview

--------------------


### addListener('urlChanged', ...)

```typescript
addListener(eventName: 'urlChanged', listenerFunc: (info: { url: string; }) => void) => Promise<PluginListenerHandle>
```

Add a listener for webview events

| Param              | Type                                             |
| ------------------ | ------------------------------------------------ |
| **`eventName`**    | <code>'urlChanged'</code>                        |
| **`listenerFunc`** | <code>(info: { url: string; }) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('closed', ...)

```typescript
addListener(eventName: 'closed', listenerFunc: () => void) => Promise<PluginListenerHandle>
```

| Param              | Type                       |
| ------------------ | -------------------------- |
| **`eventName`**    | <code>'closed'</code>      |
| **`listenerFunc`** | <code>() =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

Remove all listeners for this plugin

--------------------


### Interfaces


#### OpenWebviewOptions

| Prop                  | Type                 | Description                                              |
| --------------------- | -------------------- | -------------------------------------------------------- |
| **`url`**             | <code>string</code>  | The URL to load in the webview                           |
| **`title`**           | <code>string</code>  | Title for the navigation bar (iOS only)                  |
| **`showCloseButton`** | <code>boolean</code> | Show a done/close button (default: true)                 |
| **`closeButtonText`** | <code>string</code>  | Close button text (default: "Done")                      |
| **`toolbarEnabled`**  | <code>boolean</code> | Enable toolbar with navigation controls (default: false) |
| **`toolbarColor`**    | <code>string</code>  | Color for toolbar and navigation bar (hex format)        |
| **`clearCookies`**    | <code>boolean</code> | Allow clearing cookies before loading (default: false)   |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |

</docgen-api>
