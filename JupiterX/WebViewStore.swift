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
    @Published var isScrolled = false
    private var scrollObservation: NSKeyValueObservation?

    private var progressObservation: NSKeyValueObservation?
    private func observeWebViewProgress() {
        progressObservation = webView?.observe(\WKWebView.estimatedProgress, options: [.new]) { [weak self] webView, change in
            DispatchQueue.main.async {
                self?.progress = change.newValue ?? webView.estimatedProgress
            }
        }
        scrollObservation = webView?.scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            DispatchQueue.main.async { self?.isScrolled = sv.contentOffset.y > 0 }
        }
    }

    deinit {
        progressObservation?.invalidate()
    }
}

