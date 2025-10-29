#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(NativeWebviewPlugin, "NativeWebview",
    CAP_PLUGIN_METHOD(open, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(close, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(addListener, CAPPluginReturnCallback);
    CAP_PLUGIN_METHOD(removeAllListeners, CAPPluginReturnNone);
)