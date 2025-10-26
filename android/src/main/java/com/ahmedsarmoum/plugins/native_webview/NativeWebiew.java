package com.ahmedsarmoum.plugins.native_webview;

import com.getcapacitor.Logger;

public class NativeWebiew {

    public String echo(String value) {
        Logger.info("Echo", value);
        return value;
    }
}
