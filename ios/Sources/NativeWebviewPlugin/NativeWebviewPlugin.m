#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(NativeWebviewPlugin, "CapacitorIosNativeWebview",
    CAP_PLUGIN_METHOD(open, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(close, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(showAlert, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(showCustomAlert, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(showSuccess, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(showError, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(showWarning, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(showLoading, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(hideLoading, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(addListener, CAPPluginReturnCallback);
    CAP_PLUGIN_METHOD(removeAllListeners, CAPPluginReturnNone);

)