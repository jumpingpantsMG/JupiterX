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

    // Binding for the page icon (favicon / logo) extracted from the loaded webpage
    @Binding var faviconURL: URL?

    let config: Config

    @State private var url: URL?
    @State private var isReachable = false
    @State private var isRefreshing = false
    @State private var StartPageVisible = true
    @State private var isWebsiteSafeAndSecure = true
    @State private var UnsafnessLevel = 0
    @StateObject private var store = WebViewStore()
    @State private var retries = 0
    @State private var isEditing = false
    @State private var isResolving = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
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
                    BrowserWebView(
                        url: Binding<URL>(
                            get: { url ?? URL(string: "about:blank")! },
                            set: { url = $0 }
                        ),
                        urlString: $urlString,
                        store: store,
                        htmlTitle: $htmlTitle,
                        faviconURL: $faviconURL,
                        config: config
                    )
                    .ignoresSafeArea(edges: .bottom)
                } else if StartPageVisible {
                    StartPage { selectedURL in
                        urlString = selectedURL
                        Task { await checkAvailability() }
                    }
                } else {
                    ContentUnavailableView("Enter a valid URL", systemImage: "link")
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .task {
                await checkAvailability()
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
                    secondaryButtonAction: { }
                )
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            if store.isScrolled {
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
        await checkAvailability()
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

        // Resolve to a final URL (https/http/search)
        let resolvedURL = await URLDetector.URLorSearchAsync(input: input)
        let resolvedString = resolvedURL.absoluteString

        // Commit to state
        urlString = resolvedString
        url = resolvedURL
        StartPageVisible = (resolvedString.lowercased() == "startpage://")

        // If StartPage, stop here
        if StartPageVisible {
            retries = 0
            return
        }

        // Reachability + safety checks on the resolved URL
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
                retries = 0
            }
        }
    }
}

#Preview {
    ContentView(
        urlString: .constant("StartPage://"),
        htmlTitle: .constant(nil),
        faviconURL: .constant(nil),
        config: Config()
    )
}

// MARK: - BrowserWebView

/// UIViewRepresentable wrapper around WKWebView. The Coordinator acts as
/// WKNavigationDelegate to keep the address bar, title and icon in sync after navigation.
struct BrowserWebView: UIViewRepresentable {
    @Binding var url: URL
    @Binding var urlString: String
    @ObservedObject var store: WebViewStore
    @Binding var htmlTitle: String?
    @Binding var faviconURL: URL?
    let config: Config

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        store.webView = webView
        context.coordinator.lastLoaded = url
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
        uiView.allowsBackForwardNavigationGestures = config.navActions
        uiView.allowsLinkPreview = config.linkPreviews
        // Only load when the address bar changed, not after link taps
        if context.coordinator.lastLoaded != url {
            context.coordinator.lastLoaded = url
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: BrowserWebView
        var lastLoaded: URL?
        init(_ parent: BrowserWebView) { self.parent = parent }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let current = webView.url {
                lastLoaded = current
                parent.url = current
                parent.urlString = current.absoluteString
            }
            parent.htmlTitle = webView.title

            let js = """
            (function() {
              var rels = ['icon', 'shortcut icon', 'apple-touch-icon', 'apple-touch-icon-precomposed', 'logo'];
              var links = document.getElementsByTagName('link');
              for (var r = 0; r < rels.length; r++) {
                for (var i = 0; i < links.length; i++) {
                  var rel = (links[i].getAttribute('rel') || '').toLowerCase().trim();
                  if (rel !== rels[r]) continue;
                  if (links[i].href) return links[i].href;
                  var src = links[i].getAttribute('src');
                  if (src) return new URL(src, document.baseURI).href;
                }
              }
              return location.origin + '/favicon.ico';
            })();
            """
            webView.evaluateJavaScript(js) { [weak self] result, _ in
                guard let s = result as? String else { return }
                DispatchQueue.main.async { self?.parent.faviconURL = URL(string: s) }
            }
        }
    }
}

// Scroll WKWebView to top via the store's reference
extension WebViewStore {
    func scrollToTop() {
        webView?.scrollView.setContentOffset(.zero, animated: true)
    }
}
