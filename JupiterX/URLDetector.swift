//
//  URLDetector.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/4/26.
//


import Foundation
import SwiftUI
import Network

struct URLDetector {
    private static func defaultScheme(forHostLike input: String) -> String {
        // Extract a host-like portion from input (strip any leading scheme and path)
        var hostCandidate = input
        if hostCandidate.hasPrefix("http://") {
            hostCandidate = String(hostCandidate.dropFirst("http://".count))
        } else if hostCandidate.hasPrefix("https://") {
            hostCandidate = String(hostCandidate.dropFirst("https://".count))
        }
        if let slashIndex = hostCandidate.firstIndex(of: "/") {
            hostCandidate = String(hostCandidate[..<slashIndex])
        }
        let lower = hostCandidate.lowercased()

        return "https://"
    }
    
    private static func makeURL(_ base: String, enforcingScheme scheme: String) -> URL? {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: scheme + trimmed)
    }

    private static func isReachableHEAD(_ url: URL, timeout: TimeInterval = 3.0) async -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                // Consider 2xx and 3xx as reachable
                return (200..<400).contains(http.statusCode)
            }
            return false
        } catch {
            return false
        }
    }

    static func URLorSearchAsync(input: String) async -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return URL(string: "https://www." + ConfigView.currentEngine(lowercase: true) + ".com")!
        }
        if trimmed.lowercased() == "startpage://" {
            return URL(string: "startpage://")!
        }
        // If it already parses as a full URL with a host, return it
        if let url = URL(string: trimmed), url.host != nil {
            if url.scheme == nil {
                // Try https then http
                if let https = makeURL(trimmed, enforcingScheme: "https://"), await isReachableHEAD(https) {
                    return https
                }
                if let http = makeURL(trimmed, enforcingScheme: "http://"), await isReachableHEAD(http) {
                    return http
                }
            }
            return url
        }
        // Heuristic for bare domains (contains a dot, no spaces)
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if let https = makeURL(trimmed, enforcingScheme: "https://"), await isReachableHEAD(https) {
                return https
            }
            if let http = makeURL(trimmed, enforcingScheme: "http://"), await isReachableHEAD(http) {
                return http
            }
        }
        // Fallback to search
        return SearchEngine.url(prompt: trimmed, engine: ConfigView.currentEngine(lowercase: false))
    }

    static func URLorSearch(input: String) -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return URL(string: "https://www." + ConfigView.currentEngine(lowercase: true) + ".com")!
        }
        
        if trimmed.lowercased() == "startpage://" {
            return URL(string: "startpage://")!
        }
        
        // If input already looks like a full URL with a host, return it (adding https if missing scheme)
        if let components = URLComponents(string: trimmed), components.host != nil || components.scheme != nil {
            // If there's no scheme but we have something that looks like a host, add https
            if components.scheme == nil {
                let withScheme = URLDetector.defaultScheme(forHostLike: trimmed) + trimmed
                if let valid = URL(string: withScheme), valid.host != nil {
                    return valid
                }
            }
            if let url = URL(string: trimmed), url.host != nil {
                return url
            }
        }
        
        // Heuristic: Treat as URL if it contains a dot, no spaces, and doesn't start with a known search operator
        if trimmed.contains(".") && !trimmed.contains(" ") {
            let withScheme = (trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")) ? trimmed : URLDetector.defaultScheme(forHostLike: trimmed) + trimmed
            if let valid = URL(string: withScheme), valid.host != nil {
                return valid
            }
        }
        
        // Otherwise treat as search
        return SearchEngine.url(prompt: trimmed, engine: ConfigView.currentEngine(lowercase: false))
    }
}

#Preview("URLDetector Preview") {
    struct DetectorPreview: View {
        @State private var results: [(String, String)] = []
        private let cases = [
            "https://apple.com",
            "apple.com",
            "selenite.cc",
            "hello world",
            "startpage://"
        ]
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(results, id: \.0) { pair in
                    Text("Input: \(pair.0)\nOutput: \(pair.1)")
                        .font(.system(.body, design: .monospaced))
                        .padding(.vertical, 4)
                }
            }
            .padding()
            .task {
                var built: [(String, String)] = []
                for input in cases {
                    let url = await URLDetector.URLorSearchAsync(input: input)
                    built.append((input, url.absoluteString))
                }
                results = built
            }
        }
    }
    return DetectorPreview()
}

