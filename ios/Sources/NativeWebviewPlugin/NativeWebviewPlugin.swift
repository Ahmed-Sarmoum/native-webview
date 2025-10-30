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
        CAPPluginMethod(name: "showCustomAlert", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showAlert", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showSuccess", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showError", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showWarning", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showLoading", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hideLoading", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getWebViewRect", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "addListener", returnType: CAPPluginReturnCallback),
        CAPPluginMethod(name: "removeAllListeners", returnType: CAPPluginReturnNone)
    ]
    
    private var embeddedWebView: WKWebView?
    private var reloadButton: UIButton?
    private var nextButton: UIButton?
    private var loadingOverlay: UIView?
    private var loadingSpinner: UIActivityIndicatorView?
    private var loadingLabel: UILabel?
    
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
            
            
            self.embeddedWebView?.removeFromSuperview()
            self.reloadButton?.removeFromSuperview()
            self.nextButton?.removeFromSuperview()
            
            
            let config = WKWebViewConfiguration()
            config.allowsInlineMediaPlayback = true
            config.mediaTypesRequiringUserActionForPlayback = []
            config.websiteDataStore = .default()
            
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true
            config.defaultWebpagePreferences = preferences
            
            
            let webView = WKWebView(frame: viewController.view.bounds, configuration: config)
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.allowsBackForwardNavigationGestures = true
            webView.backgroundColor = .white
            webView.isOpaque = true
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            
            
            let topInset = viewController.view.safeAreaInsets.top
            webView.scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            
            
            viewController.view.addSubview(webView)
            viewController.view.bringSubviewToFront(webView)
            
            self.embeddedWebView = webView
            
            
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
            
            
            viewController.view.addSubview(reloadButton)
            viewController.view.bringSubviewToFront(reloadButton)
            
            
            NSLayoutConstraint.activate([
                reloadButton.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 20),
                reloadButton.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                reloadButton.widthAnchor.constraint(equalToConstant: 56),
                reloadButton.heightAnchor.constraint(equalToConstant: 56)
            ])
            
            self.reloadButton = reloadButton
            
            
            let nextButton = UIButton(type: .system)
            nextButton.setTitle("Suivant", for: .normal)
            nextButton.setTitleColor(.white, for: .normal)
            nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            nextButton.backgroundColor = UIColor(red: 0.27, green: 0.25, blue: 0.24, alpha: 1.0)
            nextButton.layer.cornerRadius = 18
            nextButton.translatesAutoresizingMaskIntoConstraints = false
            nextButton.addTarget(self, action: #selector(self.nextButtonTapped), for: .touchUpInside)
            
            
            viewController.view.addSubview(nextButton)
            viewController.view.bringSubviewToFront(nextButton)
            
            
            NSLayoutConstraint.activate([
                nextButton.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: 25),
                nextButton.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor, constant: 14),
                nextButton.heightAnchor.constraint(equalToConstant: 54),
                nextButton.widthAnchor.constraint(equalToConstant: 100)
            ])
            
            self.nextButton = nextButton
            
            
            NSLog("📱 Loading URL: \(url.absoluteString)")
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
            webView.load(request)
            
            
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
            
            
            self.notifyListeners("next", data: [:])
            NSLog("✅ Next clicked - notified Vue")
        }
    }
    
    
    
    @objc func showCustomAlert(_ call: CAPPluginCall) {
        guard let message = call.getString("message") else {
            call.reject("Message is required")
            return
        }
        
        let type = call.getString("type") ?? "info" 
        let buttonText = call.getString("buttonText") ?? "OK"
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let viewController = self.bridge?.viewController else {
                call.reject("View controller not available")
                return
            }
            
            self.showCustomAlertDialog(
                viewController: viewController,
                message: message,
                type: type,
                buttonText: buttonText,
                completion: {
                    call.resolve()
                }
            )
        }
    }
    
    private func showCustomAlertDialog(
        viewController: UIViewController,
        message: String,
        type: String,
        buttonText: String,
        completion: @escaping () -> Void
    ) {
        
        let overlay = UIView(frame: viewController.view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.alpha = 0
        
        
        let dialog = UIView()
        dialog.backgroundColor = UIColor(red: 0.96, green: 0.95, blue: 0.94, alpha: 1.0) 
        dialog.layer.cornerRadius = 16
        dialog.translatesAutoresizingMaskIntoConstraints = false
        
        
        let iconLabel = UILabel()
        iconLabel.font = UIFont.systemFont(ofSize: 48)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        switch type {
        case "success":
            iconLabel.text = "✓"
            iconLabel.textColor = UIColor.systemGreen
        case "error":
            iconLabel.text = "!"
            iconLabel.textColor = UIColor.systemRed
        case "warning":
            iconLabel.text = "!"
            iconLabel.textColor = UIColor.systemOrange
        default:
            iconLabel.text = "!"
            iconLabel.textColor = UIColor.darkGray
        }
        
        
        let iconContainer = UIView()
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconLabel)
        
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = UIColor.darkGray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        
        let okButton = UIButton(type: .system)
        okButton.setTitle(buttonText, for: .normal)
        okButton.setTitleColor(.white, for: .normal)
        okButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        okButton.backgroundColor = UIColor(red: 0.27, green: 0.25, blue: 0.24, alpha: 1.0) 
        okButton.layer.cornerRadius = 8
        okButton.translatesAutoresizingMaskIntoConstraints = false
        
        
        dialog.addSubview(iconContainer)
        dialog.addSubview(messageLabel)
        dialog.addSubview(okButton)
        
        overlay.addSubview(dialog)
        viewController.view.addSubview(overlay)
        
        
        NSLayoutConstraint.activate([
            
            iconContainer.topAnchor.constraint(equalTo: dialog.topAnchor, constant: 32),
            iconContainer.centerXAnchor.constraint(equalTo: dialog.centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 64),
            iconContainer.heightAnchor.constraint(equalToConstant: 64),
            
            
            iconLabel.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            
            
            messageLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 24),
            messageLabel.leadingAnchor.constraint(equalTo: dialog.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: dialog.trailingAnchor, constant: -24),
            
            
            okButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 32),
            okButton.leadingAnchor.constraint(equalTo: dialog.leadingAnchor, constant: 24),
            okButton.trailingAnchor.constraint(equalTo: dialog.trailingAnchor, constant: -24),
            okButton.heightAnchor.constraint(equalToConstant: 48),
            okButton.bottomAnchor.constraint(equalTo: dialog.bottomAnchor, constant: -24),
            
            
            dialog.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            dialog.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            dialog.widthAnchor.constraint(equalToConstant: 320)
        ])
        
        
        okButton.addAction(UIAction { _ in
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0
            }) { _ in
                overlay.removeFromSuperview()
                completion()
            }
        }, for: .touchUpInside)
        
        
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1
        }
    }
    
    
    
    @objc func showAlert(_ call: CAPPluginCall) {
        guard let message = call.getString("message") else {
            call.reject("Message is required")
            return
        }
        
        let title = call.getString("title")
        
        DispatchQueue.main.async { [weak self] in
            guard let viewController = self?.bridge?.viewController else {
                call.reject("View controller not available")
                return
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                call.resolve()
            })
            
            viewController.present(alert, animated: true)
        }
    }
    
    @objc func showSuccess(_ call: CAPPluginCall) {
        guard let message = call.getString("message") else {
            call.reject("Message is required")
            return
        }
        
        let buttonText = call.getString("buttonText") ?? "OK"
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let viewController = self.bridge?.viewController else {
                call.reject("View controller not available")
                return
            }
            
            self.showCustomAlertDialog(
                viewController: viewController,
                message: message,
                type: "success",
                buttonText: buttonText,
                completion: {
                    call.resolve()
                }
            )
        }
    }
    
    @objc func showError(_ call: CAPPluginCall) {
        guard let message = call.getString("message") else {
            call.reject("Message is required")
            return
        }
        
        let buttonText = call.getString("buttonText") ?? "OK"
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let viewController = self.bridge?.viewController else {
                call.reject("View controller not available")
                return
            }
            
            self.showCustomAlertDialog(
                viewController: viewController,
                message: message,
                type: "error",
                buttonText: buttonText,
                completion: {
                    call.resolve()
                }
            )
        }
    }
    
    @objc func showWarning(_ call: CAPPluginCall) {
        guard let message = call.getString("message") else {
            call.reject("Message is required")
            return
        }
        
        let buttonText = call.getString("buttonText") ?? "OK"
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let viewController = self.bridge?.viewController else {
                call.reject("View controller not available")
                return
            }
            
            self.showCustomAlertDialog(
                viewController: viewController,
                message: message,
                type: "warning",
                buttonText: buttonText,
                completion: {
                    call.resolve()
                }
            )
        }
    }
    
    @objc func showLoading(_ call: CAPPluginCall) {
        let message = call.getString("message")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let viewController = self.bridge?.viewController else {
                call.reject("View controller not available")
                return
            }
            
            
            self.loadingOverlay?.removeFromSuperview()
            
            
            let overlay = UIView(frame: viewController.view.bounds)
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            
            let container = UIView()
            container.backgroundColor = .white
            container.layer.cornerRadius = 12
            container.translatesAutoresizingMaskIntoConstraints = false
            
            
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.color = .systemBlue
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            
            container.addSubview(spinner)
            
            
            if let msg = message {
                let label = UILabel()
                label.text = msg
                label.textColor = .darkGray
                label.font = UIFont.systemFont(ofSize: 16)
                label.textAlignment = .center
                label.numberOfLines = 0
                label.translatesAutoresizingMaskIntoConstraints = false
                
                container.addSubview(label)
                self.loadingLabel = label
                
                NSLayoutConstraint.activate([
                    spinner.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
                    spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    
                    label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
                    label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
                    label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
                    
                    container.widthAnchor.constraint(equalToConstant: 200)
                ])
            } else {
                NSLayoutConstraint.activate([
                    spinner.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
                    spinner.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 30),
                    spinner.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -30),
                    spinner.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -30)
                ])
            }
            
            overlay.addSubview(container)
            
            NSLayoutConstraint.activate([
                container.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
                container.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
            ])
            
            viewController.view.addSubview(overlay)
            viewController.view.bringSubviewToFront(overlay)
            
            self.loadingOverlay = overlay
            self.loadingSpinner = spinner
            
            call.resolve()
        }
    }
    
    @objc func hideLoading(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.2, animations: {
                self.loadingOverlay?.alpha = 0
            }) { _ in
                self.loadingOverlay?.removeFromSuperview()
                self.loadingOverlay = nil
                self.loadingSpinner = nil
                self.loadingLabel = nil
                call.resolve()
            }
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
            
            
            self.loadingOverlay?.removeFromSuperview()
            self.loadingOverlay = nil
            self.loadingSpinner = nil
            self.loadingLabel = nil
            
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
        loadingOverlay?.removeFromSuperview()
        loadingOverlay = nil
        loadingSpinner = nil
        loadingLabel = nil
    }
}