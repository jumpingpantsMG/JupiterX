//
//  ContentView.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/2/26.
//

import SwiftUI
import WebKit

struct ContentView: View {
    // Binding for the URL string passed from outside
    @Binding var urlString: String
    
    // Binding for the HTML title extracted from the loaded webpage
    @Binding var htmlTitle: String?
    
    @State private var url: URL?
    @State private var isReachable = false
    @State private var config = Config()
    @State private var isRefreshing = false
    @State private var scrollPosition = ScrollPosition()
    @State private var StartPageVisible = true
    @State private var isWebsiteSafeAndSecure = true
    @State private var UnsafnessLevel = 0
    @State private var showScrollToTopButton = false
    @StateObject private var store = WebViewStore()
    @State private var retries = 0
    @State private var isEditing = false
    @State private var isResolving = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack{
                    Button {
                        Task {
                           await Refresh()
                        }
                    
                    } label: {
                       Image(systemName: "arrow.clockwise")
                    }
                    TextField(text: $urlString) {
                        Text("\(Image(systemName: "magnifyingglass")) Type a url")
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .submitLabel(.go)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .onSubmit {
                        Task {
                            isEditing = false
                            await checkAvailability()
                        }
                    }
                    if !urlString.isEmpty {
                        Button {
                            urlString = ""
                            isEditing = true
                        } label: {
                           Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Show linear progress view below the URL text field when loading
                if store.progress < 1.0 {
                    ProgressView(value: store.progress)
                        .progressViewStyle(.linear)
                        .padding(.horizontal)
                }
                
                if isReachable && !StartPageVisible {
                    // Use BrowserWebView instead of WebView
                    BrowserWebView(url: Binding<URL>(
                        get: { url ?? URL(string: "about:blank")! },
                        set: { url = $0 }
                    ), store: store, htmlTitle: $htmlTitle)   // Pass htmlTitle binding to BrowserWebView
                        .ignoresSafeArea(edges: .bottom)
                        .scrollBounceBehavior(.basedOnSize)
                        .webViewBackForwardNavigationGestures(config.navActions ? .enabled : .disabled)
                        .webViewMagnificationGestures(config.magnification ? .enabled : .disabled)
                        .webViewLinkPreviews(config.linkPreviews ? .enabled : .disabled)
                        .webViewTextSelection(config.textSelection)
                        .defaultScrollAnchor(.top)
                        .webViewScrollPosition($scrollPosition)
                        .webViewOnScrollGeometryChange(for: CGFloat.self) {
                            geometry in
                            geometry.contentOffset.y
                        } action: { _, newValue in
                            showScrollToTopButton = newValue > 0
                        }
                        // Assign WKWebView instance to store to track progress
                        .onAppear {
                            if store.webView == nil, let webView = store.webViewFromBinding() {
                                store.webView = webView
                            }
                        }
                } else if StartPageVisible {
                    StartPage { selectedURL in
                            urlString = selectedURL
                            Task { await checkAvailability() }
                        }
                } else {
                    ContentUnavailableView("Enter a valid URL", systemImage: "link")
                }
               /* HStack {
                    Button {
                        store.webView?.goBack()
                        }
                    label: {
                        Image(systemName: "arrow.backward")
                    }
                    .disabled(store.webView?.canGoBack != true)
                    Button {
                        store.webView?.goForward()
                    } label: {
                        Image(systemName: "arrow.forward")
                    }
                    .disabled(store.webView?.canGoForward != true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6)))*/
            }
            .ignoresSafeArea(edges: .bottom)
                        
            .task {
                await checkAvailability()
            }
            .onReceive(NotificationCenter.default.publisher(for: .WebViewVerticalOffsetDidChange)) { note in
                if let y = note.userInfo?["y"] as? CGFloat {
                    showScrollToTopButton = y > 0
                }
            }
            .popup(isPresented: Binding<Bool>(
                get: { !isWebsiteSafeAndSecure },
                set: { newValue in isWebsiteSafeAndSecure = !newValue }
            )) {
                Popup(
                    isPresented: Binding<Bool>(
                        get: { !isWebsiteSafeAndSecure },
                        set: { newValue in isWebsiteSafeAndSecure = !newValue }
                    ),
                    title: "Connection Safety",
                    message: "This site \(UnsafnessLevel > 2 ? "is" : "may be") unsafe (level: \(UnsafnessLevel)).",
                    systemImage: "exclamationmark.triangle",
                    primaryButtonTitle: UnsafnessLevel > 2 ? "Ignore" : "OK",
                    primaryButtonRole: .none,
                    accentColor: UnsafnessLevel > 2 ? .red : .orange,
                    placement: .center,
                    primaryButtonAction: { },
                    secondaryButtonTitle: "Dismiss",
                    secondaryButtonRole: .cancel,
                    secondaryButtonAction: {  }
                )
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            if showScrollToTopButton {
                Image(systemName: "arrow.up")
                    .font(.system(size: 36))
                    .frame(width: 60, height: 60)
#if !os(visionOS)
                    .glassEffect(.regular.interactive())
#endif
                    .padding()
                    .onTapGesture {
                        store.scrollToTop()
                    }
            }
        }
    }
    
    @MainActor func Refresh() async {
        guard !isRefreshing else { return } // prevent double-tap
        isRefreshing = true

        // Re-check availability without clearing the text field
        await checkAvailability()

        // Reset rotation to default
        isRefreshing = false
    }
    
    @MainActor func checkAvailability() async {
        // Prevent overlapping resolutions
        if isResolving { return }
        isResolving = true
        defer { isResolving = false }
        
        // Capture the latest user input and allow SwiftUI to commit pending binding updates
        var input = urlString
        await Task.yield()
        input = urlString
        print("[checkAvailability] input:", input)
        
        // Treat startpage command only when user explicitly typed/submitted it
        if input.lowercased() == "startpage://" && isEditing == true {
            StartPageVisible = true
            urlString = ""
            retries = 0
            return
        }
        
        // Resolve to a final URL (https/http/search) using async detector without mutating urlString mid-flight
        let resolvedURL = await URLDetector.URLorSearchAsync(input: input)
        let resolvedString = resolvedURL.absoluteString
        
        // Now atomically commit to state
        urlString = resolvedString
        url = resolvedURL
        StartPageVisible = (resolvedString.lowercased() == "startpage://")
        
        // If StartPage, stop here
        if StartPageVisible {
            retries = 0
            return
        }
        
        // Reachability check on the resolved URL string
        isReachable = await Reachability.checkURL(resolvedString)
        (isWebsiteSafeAndSecure, UnsafnessLevel) = await ConnectionIsSafe.check(
            url: resolvedURL,
            advancedDataProtection: config.AdvancedDataProtection
        )
        
        if isReachable {
            StartPageVisible = false
            retries = 0
        } else {
            retries += 1
            if retries < 3 {
                Task { await checkAvailability() }
            } else {
                showScrollToTopButton = false
                retries = 0
            }
        }
    }
}

#Preview {
    // Preview uses ContentView with bindings for urlString and htmlTitle
    ContentView(urlString: .constant("StartPage://"), htmlTitle: .constant(nil))
}

// MARK: - BrowserWebView Implementation with htmlTitle Binding

/// BrowserWebView is a UIViewRepresentable (or NSViewRepresentable) wrapper around WKWebView.
/// The Coordinator acts as WKNavigationDelegate to capture page load events and extract the HTML title.
struct BrowserWebView: UIViewRepresentable {
    @Binding var url: URL
    @ObservedObject var store: WebViewStore
    @Binding var htmlTitle: String?  // Binding to update the HTML title
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        store.webView = webView
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: BrowserWebView
        
        init(_ parent: BrowserWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Evaluate JavaScript to get the HTML document title
            webView.evaluateJavaScript("document.title") { result, error in
                if let title = result as? String {
                    DispatchQueue.main.async {
                        self.parent.htmlTitle = title
                    }
                } else {
                    DispatchQueue.main.async {
                        self.parent.htmlTitle = nil
                    }
                }
            }
        }
    }
}

struct WebViewTextSelectionModifier: ViewModifier {
    let textSelection: Bool
    func body(content: Content) -> some View {
        if textSelection {
            content
                .webViewTextSelection(.enabled)
        } else {
            content
                .webViewTextSelection(.disabled)
        }
    }
}

extension View {
    func webViewTextSelection(_ textSelection: Bool) -> some View {
        modifier(WebViewTextSelectionModifier(textSelection: textSelection))
    }
}

// Convenience helper to scroll WKWebView to top via the store's reference
extension WebViewStore {
    func scrollToTop() {
        if let webView = self.webView {
            webView.scrollView.setContentOffset(.zero, animated: true)
        }
    }
}

// Add this helper to get WKWebView from the WebView if needed
extension WebViewStore {
    /// Tries to retrieve WKWebView reference from the store's webView property or other means.
    /// This is a placeholder for actual WKWebView assignment logic if needed.
    func webViewFromBinding() -> WKWebView? {
        // In your BrowserWebView implementation, you should assign the WKWebView instance here.
        // For this example, just return the existing webView if any.
        return self.webView
    }
}

