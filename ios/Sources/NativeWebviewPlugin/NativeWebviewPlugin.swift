import Foundation
import Capacitor
import WebKit
import SafariServices

@objc(NativeWebviewPlugin)
public class NativeWebviewPlugin: CAPPlugin, CAPBridgedPlugin, WKNavigationDelegate, WKUIDelegate {
    public let identifier = "NativeWebviewPlugin"
    public let jsName = "NativeWebview"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "close", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getWebViewRect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "addListener", returnType: CAPPluginReturnCallback),
        CAPPluginMethod(name: "removeAllListeners", returnType: CAPPluginReturnNone)
    ]
    
    private var embeddedWebView: WKWebView?
    private var reloadButton: UIButton?
    private var nextButton: UIButton?
    
    @objc func open(_ call: CAPPluginCall) {
        NSLog("🚀 NativeWebview.open() called")
        
        guard let urlString = call.getString("url") else {
            call.reject("URL is required")
            return
        }
        
        guard let url = URL(string: urlString) else {
            call.reject("Invalid URL")
            return
        }
        
        let clearCookies = call.getBool("clearCookies") ?? false
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if clearCookies {
                self.clearWebViewCookies()
            }
            
            guard let bridge = self.bridge else {
                call.reject("Bridge not available")
                return
            }
            
            guard let viewController = bridge.viewController else {
                call.reject("View controller not available")
                return
            }
            
            // Remove existing webview and buttons if any
            self.embeddedWebView?.removeFromSuperview()
            self.reloadButton?.removeFromSuperview()
            self.nextButton?.removeFromSuperview()
            
            // Create and configure embedded webview
            let config = WKWebViewConfiguration()
            config.allowsInlineMediaPlayback = true
            config.mediaTypesRequiringUserActionForPlayback = []
            config.websiteDataStore = .default()
            
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true
            config.defaultWebpagePreferences = preferences
            
            // Create webview with full screen frame (including safe areas)
            let webView = WKWebView(frame: viewController.view.bounds, configuration: config)
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.allowsBackForwardNavigationGestures = true
            webView.backgroundColor = .white
            webView.isOpaque = true
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            
            // Add top padding/inset to account for safe area (notch, status bar, etc.)
            let topInset = viewController.view.safeAreaInsets.top
            webView.scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            
            // Add webview to view
            viewController.view.addSubview(webView)
            viewController.view.bringSubviewToFront(webView)
            
            self.embeddedWebView = webView
            
            // Create RELOAD button (circular, top-left)
            let reloadButton = UIButton(type: .system)
            let reloadConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
            let reloadImage = UIImage(systemName: "arrow.clockwise", withConfiguration: reloadConfig)
            reloadButton.setImage(reloadImage, for: .normal)
            reloadButton.tintColor = .darkGray
            reloadButton.backgroundColor = .white
            reloadButton.layer.cornerRadius = 28
            reloadButton.layer.shadowColor = UIColor.black.cgColor
            reloadButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            reloadButton.layer.shadowRadius = 8
            reloadButton.layer.shadowOpacity = 0.1
            reloadButton.translatesAutoresizingMaskIntoConstraints = false
            reloadButton.addTarget(self, action: #selector(self.reloadButtonTapped), for: .touchUpInside)
            
            // Add reload button on top of webview
            viewController.view.addSubview(reloadButton)
            viewController.view.bringSubviewToFront(reloadButton)
            
            // Position reload button in top-left corner
            NSLayoutConstraint.activate([
                reloadButton.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 0),
                reloadButton.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                reloadButton.widthAnchor.constraint(equalToConstant: 56),
                reloadButton.heightAnchor.constraint(equalToConstant: 56)
            ])
            
            self.reloadButton = reloadButton
            
            // Create NEXT button (rounded rectangle, bottom-left)
            let nextButton = UIButton(type: .system)
            nextButton.setTitle("Suivant", for: .normal)
            nextButton.setTitleColor(.white, for: .normal)
            nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            nextButton.backgroundColor = UIColor(red: 0.27, green: 0.25, blue: 0.24, alpha: 1.0) // Dark brown/gray
            nextButton.layer.cornerRadius = 18
            nextButton.translatesAutoresizingMaskIntoConstraints = false
            nextButton.addTarget(self, action: #selector(self.nextButtonTapped), for: .touchUpInside)
            
            // Add next button on top of webview
            viewController.view.addSubview(nextButton)
            viewController.view.bringSubviewToFront(nextButton)
            
            // Position next button at bottom-left
            NSLayoutConstraint.activate([
                nextButton.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: 25),
                nextButton.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 14),
                nextButton.heightAnchor.constraint(equalToConstant: 54),
                nextButton.widthAnchor.constraint(equalToConstant: 100)
            ])
            
            self.nextButton = nextButton
            
            // Load URL
            NSLog("📱 Loading URL: \(url.absoluteString)")
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
            webView.load(request)
            
            // Inject CSS for viewport
            let jsCode = """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(meta);
            """
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
            
            call.resolve(["url": urlString])
        }
    }
    
    @objc private func reloadButtonTapped() {
        NSLog("🔄 Reload button tapped")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let webView = self.embeddedWebView else { return }
            webView.reload()
            self.notifyListeners("reload", data: [:])
        }
    }
    
    @objc private func nextButtonTapped() {
        NSLog("➡️ Next button tapped")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Notify Vue before closing
            self.notifyListeners("next", data: [:])
            NSLog("✅ Next clicked - notified Vue")
        }
    }
    
    @objc func close(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                call.resolve()
                return
            }
            
            if let webView = self.embeddedWebView {
                webView.stopLoading()
                webView.removeFromSuperview()
                self.embeddedWebView = nil
            }
            
            if let reloadBtn = self.reloadButton {
                reloadBtn.removeFromSuperview()
                self.reloadButton = nil
            }
            
            if let nextBtn = self.nextButton {
                nextBtn.removeFromSuperview()
                self.nextButton = nil
            }
            
            self.notifyListeners("closed", data: [:])
            call.resolve()
            NSLog("✅ Embedded webview and buttons removed")
        }
    }
    
    @objc func getWebViewRect(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let webView = self?.embeddedWebView else {
                call.reject("No webview available")
                return
            }
            
            let frame = webView.frame
            call.resolve([
                "x": frame.origin.x,
                "y": frame.origin.y,
                "width": frame.size.width,
                "height": frame.size.height
            ])
        }
    }
    
    private func clearWebViewCookies() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                NSLog("✅ Cookies cleared")
            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        NSLog("🔄 Started loading: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("✅ Page loaded: \(webView.url?.absoluteString ?? "unknown")")
        if let url = webView.url?.absoluteString {
            self.notifyListeners("urlChanged", data: ["url": url])
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("❌ Navigation failed: \(error.localizedDescription)")
        self.notifyListeners("error", data: ["error": error.localizedDescription])
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("❌ Provisional navigation failed: \(error.localizedDescription)")
        self.notifyListeners("error", data: ["error": error.localizedDescription])
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        NSLog("🔍 Navigation action: \(navigationAction.request.url?.absoluteString ?? "unknown")")
        
        if let url = navigationAction.request.url?.absoluteString {
            self.notifyListeners("urlChanged", data: ["url": url])
        }
        
        decisionHandler(.allow)
    }
    
    // MARK: - WKUIDelegate
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        
        DispatchQueue.main.async {
            self.bridge?.viewController?.present(alert, animated: true)
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        
        DispatchQueue.main.async {
            self.bridge?.viewController?.present(alert, animated: true)
        }
    }
    
    deinit {
        embeddedWebView?.stopLoading()
        embeddedWebView?.removeFromSuperview()
        embeddedWebView = nil
        reloadButton?.removeFromSuperview()
        reloadButton = nil
        nextButton?.removeFromSuperview()
        nextButton = nil
    }
}
