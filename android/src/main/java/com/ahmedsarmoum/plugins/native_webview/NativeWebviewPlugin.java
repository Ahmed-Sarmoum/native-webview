package com.ahmedsarmoum.plugins.native_webview;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "CapacitorIosNativeWebview")
public class NativeWebviewPlugin extends Plugin {

    private NativeWebview implementation = new NativeWebview(getActivity());

    @PluginMethod
    public void echo(PluginCall call) {
        String value = call.getString("value");

        JSObject ret = new JSObject();
        ret.put("value", implementation.echo(value));
        call.resolve(ret);
    }

    @PluginMethod
    public void open(PluginCall call) {
        implementation.open(call);
    }

    @PluginMethod
    public void close(PluginCall call) {
        implementation.close(call);
    }

    @PluginMethod
    public void addListener(PluginCall call) {
        implementation.addListener(call);
    }

    @PluginMethod
    public void removeAllListeners(PluginCall call) {
        implementation.removeAllListeners(call);
    }

    @PluginMethod
    public void showCustomAlert(PluginCall call) {
        implementation.showCustomAlert(call);
    }

    @PluginMethod
    public void showAlert(PluginCall call) {
        implementation.showAlert(call);
    }

    @PluginMethod
    public void showSuccess(PluginCall call) {
        implementation.showSuccess(call);
    }

    @PluginMethod
    public void showError(PluginCall call) {
        implementation.showError(call);
    }

    @PluginMethod
    public void showWarning(PluginCall call) {
        implementation.showWarning(call);
    }

    @PluginMethod
    public void showLoading(PluginCall call) {
        implementation.showLoading(call);
    }

    @PluginMethod
    public void hideLoading(PluginCall call) {
        implementation.hideLoading(call);
    }
}
