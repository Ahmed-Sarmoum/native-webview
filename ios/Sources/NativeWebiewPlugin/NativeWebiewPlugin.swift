import Foundation
import Capacitor
import WebKit
import SafariServices

@objc(NativeWebviewPlugin)
public class NativeWebviewPlugin: CAPPlugin {
    private var safariViewController: SFSafariViewController?
    private var webViewController: WebViewController?
    
    @objc func open(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url") else {
            call.reject("URL is required")
            return
        }
        
        guard let url = URL(string: urlString) else {
            call.reject("Invalid URL")
            return
        }
        
        let title = call.getString("title") ?? ""
        let showCloseButton = call.getBool("showCloseButton") ?? true
        let closeButtonText = call.getString("closeButtonText") ?? "Done"
        let toolbarEnabled = call.getBool("toolbarEnabled") ?? false
        let toolbarColor = call.getString("toolbarColor")
        let clearCookies = call.getBool("clearCookies") ?? false
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if clearCookies {
                self.clearWebViewCookies()
            }
            
            // Use custom WKWebView controller for more control
            let webVC = WebViewController()
            webVC.url = url
            webVC.navTitle = title
            webVC.showCloseButton = showCloseButton
            webVC.closeButtonText = closeButtonText
            webVC.toolbarEnabled = toolbarEnabled
            
            if let colorHex = toolbarColor {
                webVC.toolbarColor = self.hexToUIColor(hex: colorHex)
            }
            
            webVC.onClose = {
                self.notifyListeners("closed", data: [:])
                call.resolve(["url": urlString])
            }
            
            webVC.onURLChange = { newURL in
                self.notifyListeners("urlChanged", data: ["url": newURL])
            }
            
            let navController = UINavigationController(rootViewController: webVC)
            navController.modalPresentationStyle = .fullScreen
            
            self.webViewController = webVC
            
            self.bridge?.viewController?.present(navController, animated: true) {
                call.resolve(["url": urlString])
            }
        }
    }
    
    @objc func close(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            if let webVC = self?.webViewController {
                webVC.dismiss(animated: true) {
                    self?.webViewController = nil
                    call.resolve()
                }
            } else if let safariVC = self?.safariViewController {
                safariVC.dismiss(animated: true) {
                    self?.safariViewController = nil
                    call.resolve()
                }
            } else {
                call.resolve()
            }
        }
    }
    
    private func clearWebViewCookies() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                dataStore.removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
    private func hexToUIColor(hex: String) -> UIColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// Custom WebView Controller
class WebViewController: UIViewController, WKNavigationDelegate {
    var url: URL?
    var navTitle: String = ""
    var showCloseButton: Bool = true
    var closeButtonText: String = "Done"
    var toolbarEnabled: Bool = false
    var toolbarColor: UIColor = .systemBlue
    var onClose: (() -> Void)?
    var onURLChange: ((String) -> Void)?
    
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var toolbar: UIToolbar?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        setupNavigationBar()
        
        if toolbarEnabled {
            setupToolbar()
        }
        
        if let url = url {
            webView.load(URLRequest(url: url))
        }
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        // Important: Enable cross-origin requests and cookies
        config.websiteDataStore = .default()
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: toolbarEnabled ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor)
        ])
        
        // Progress view
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }
    
    private func setupNavigationBar() {
        title = navTitle
        navigationController?.navigationBar.tintColor = toolbarColor
        
        if showCloseButton {
            let closeButton = UIBarButtonItem(
                title: closeButtonText,
                style: .done,
                target: self,
                action: #selector(closeTapped)
            )
            navigationItem.rightBarButtonItem = closeButton
        }
    }
    
    private func setupToolbar() {
        toolbar = UIToolbar()
        guard let toolbar = toolbar else { return }
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
        let forwardButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(goForward))
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reload))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [backButton, space, forwardButton, space, refreshButton]
        
        // Update webView constraints
        webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor).isActive = true
    }
    
    @objc private func closeTapped() {
        onClose?()
        dismiss(animated: true)
    }
    
    @objc private func goBack() {
        webView.goBack()
    }
    
    @objc private func goForward() {
        webView.goForward()
    }
    
    @objc private func reload() {
        webView.reload()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress >= 1.0
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            onURLChange?(url)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
}