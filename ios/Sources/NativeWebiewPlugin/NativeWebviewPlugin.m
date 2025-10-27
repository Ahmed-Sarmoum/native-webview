#import <Capacitor/Capacitor.h>

CAP_PLUGIN(NativeWebviewPlugin, "NativeWebview",
    CAP_PLUGIN_METHOD(open, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(close, CAPPluginReturnPromise);
)