//
//  WebViewStore.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/5/26.
//


import Foundation
import Combine
import WebKit

final class WebViewStore: ObservableObject {
    weak var webView: WKWebView? {
        didSet {
            observeWebViewProgress()
        }
    }

    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var progress: Double = 1.0

    private var progressObservation: NSKeyValueObservation?
    private func observeWebViewProgress() {
        progressObservation = webView?.observe(\WKWebView.estimatedProgress, options: [.new]) { [weak self] webView, change in
            DispatchQueue.main.async {
                self?.progress = change.newValue ?? webView.estimatedProgress
            }
        }
    }

    deinit {
        progressObservation?.invalidate()
    }
}

