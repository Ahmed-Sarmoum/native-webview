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
        listeners.clear();
        call.resolve();
    }

    public void showCustomAlert(PluginCall call) {
        String message = call.getString("message");
        String type = call.getString("type", "info");
        String buttonText = call.getString("buttonText", "OK");

        if (message == null) {
            call.reject("Message is required");
            return;
        }

        // For Android, use a simple AlertDialog
        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(activity);
        builder.setMessage(message)
               .setPositiveButton(buttonText, (dialog, id) -> {
                   // User clicked OK button
                   dialog.dismiss();
                   call.resolve();
               });

        android.app.AlertDialog dialog = builder.create();
        dialog.show();
    }

    public void showAlert(PluginCall call) {
        String title = call.getString("title");
        String message = call.getString("message");

        if (message == null) {
            call.reject("Message is required");
            return;
        }

        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(activity);
        if (title != null) {
            builder.setTitle(title);
        }
        builder.setMessage(message)
               .setPositiveButton("OK", (dialog, id) -> {
                   dialog.dismiss();
                   call.resolve();
               });

        android.app.AlertDialog dialog = builder.create();
        dialog.show();
    }

    public void showSuccess(PluginCall call) {
        String message = call.getString("message");
        String buttonText = call.getString("buttonText", "OK");

        if (message == null) {
            call.reject("Message is required");
            return;
        }

        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(activity);
        builder.setMessage(message)
               .setPositiveButton(buttonText, (dialog, id) -> {
                   dialog.dismiss();
                   call.resolve();
               });

        android.app.AlertDialog dialog = builder.create();
        dialog.show();
    }

    public void showError(PluginCall call) {
        String message = call.getString("message");
        String buttonText = call.getString("buttonText", "OK");

        if (message == null) {
            call.reject("Message is required");
            return;
        }

        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(activity);
        builder.setMessage(message)
               .setPositiveButton(buttonText, (dialog, id) -> {
                   dialog.dismiss();
                   call.resolve();
               });

        android.app.AlertDialog dialog = builder.create();
        dialog.show();
    }

    public void showWarning(PluginCall call) {
        String message = call.getString("message");
        String buttonText = call.getString("buttonText", "OK");

        if (message == null) {
            call.reject("Message is required");
            return;
        }

        android.app.AlertDialog.Builder builder = new android.app.AlertDialog.Builder(activity);
        builder.setMessage(message)
               .setPositiveButton(buttonText, (dialog, id) -> {
                   dialog.dismiss();
                   call.resolve();
               });

        android.app.AlertDialog dialog = builder.create();
        dialog.show();
    }

    public void showLoading(PluginCall call) {
        String message = call.getString("message");

        // For simplicity, just use a Toast for loading indication
        String loadingMessage = message != null ? message : "Loading...";
        android.widget.Toast.makeText(activity, loadingMessage, android.widget.Toast.LENGTH_LONG).show();
        call.resolve();
    }

    public void hideLoading(PluginCall call) {
        // No persistent loading overlay in Android implementation, so just resolve
        call.resolve();
    }
}
