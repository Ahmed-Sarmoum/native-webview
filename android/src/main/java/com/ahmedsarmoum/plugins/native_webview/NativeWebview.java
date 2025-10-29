package com.ahmedsarmoum.plugins.native_webview;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.view.View;
import android.view.ViewGroup;
import android.graphics.Color;
import java.util.HashMap;
import java.util.Map;

import com.getcapacitor.JSObject;
import com.getcapacitor.Logger;
import com.getcapacitor.PluginCall;

public class NativeWebview {

    private Activity activity;
    private WebView webView;
    private FrameLayout container;
    private Map<String, PluginCall> listeners = new HashMap<>();

    public NativeWebview(Activity activity) {
        this.activity = activity;
    }

    public String echo(String value) {
        Logger.info("Echo", value);
        return value;
    }

    public void open(PluginCall call) {
        String url = call.getString("url");
        if (url == null) {
            call.reject("URL is required");
            return;
        }

        try {
            Uri uri = Uri.parse(url);
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            activity.startActivity(intent);
            JSObject ret = new JSObject();
            ret.put("url", url);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject("Failed to open URL: " + e.getMessage());
        }
    }

    public void close(PluginCall call) {
        // Android doesn't maintain a persistent webview like iOS, so close is a no-op for external browser
        call.resolve();
    }

    public void addListener(PluginCall call) {
        String eventName = call.getString("eventName");
        if (eventName != null) {
            listeners.put(eventName, call);
        }
        // Keep call alive for listeners
        call.setKeepAlive(true);
    }

    public void removeAllListeners(PluginCall call) {
        for (PluginCall listenerCall : listeners.values()) {
            listenerCall.releaseKeepAlive();
        }
        listeners.clear();
        call.resolve();
    }
}
