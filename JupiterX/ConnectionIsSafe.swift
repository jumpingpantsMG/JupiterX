//
//  ConnectionIsSafe.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/4/26.
//


import Foundation
import Security

struct ConnectionIsSafe {
    
    /// Checks if a URL is safe to connect to
    /// - Parameters:
    ///   - url: The URL to check
    ///   - advancedDataProtection: If true, enforces stricter rules
    /// - Returns: true if the connection is considered safe
    static func check(url: URL, advancedDataProtection: Bool = false) async -> (isSafe: Bool, unsafenessLevel: Int) {
        // Unsafeness levels (higher means more unsafe)
        // 0: No issues detected
        // 1: Non-HTTPS scheme
        // 2: Invalid/malformed URL components (missing host)
        // 3: Blacklisted domain (advancedDataProtection)
        // 4: Network response not HTTP or unacceptable status code
        // 5: Network error / no response
        // 6: TLS verification failure (advancedDataProtection)
        var maxUnsafeness = 0

        // 1️⃣ Basic validation: scheme must be https
        guard let scheme = url.scheme?.lowercased(), scheme == "https" else {
            maxUnsafeness = max(maxUnsafeness, 1)
            return (false, maxUnsafeness)
        }

        // 1b️⃣ Basic structure: must have host
        guard let host = url.host?.lowercased(), !host.isEmpty else {
            maxUnsafeness = max(maxUnsafeness, 2)
            return (false, maxUnsafeness)
        }

        // 2️⃣ Advanced Data Protection - blacklist / whitelist
        if advancedDataProtection {
            let unsafeDomains = Config().websiteBlacklist
            if unsafeDomains.contains(host) {
                maxUnsafeness = max(maxUnsafeness, 3)
                return (false, maxUnsafeness)
            }
        }

        // 3️⃣ Attempt a network request: try HEAD first, then fallback to GET
        func performRequest(method: String) async throws -> HTTPURLResponse {
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.timeoutInterval = 5.0
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            return httpResponse
        }

        var httpResponse: HTTPURLResponse
        do {
            // Try HEAD first (fast)
            httpResponse = try await performRequest(method: "HEAD")
        } catch {
            // Some servers/CDNs reject HEAD; try a lightweight GET
            do {
                httpResponse = try await performRequest(method: "GET")
            } catch {
                maxUnsafeness = max(maxUnsafeness, 5)
                return (false, maxUnsafeness)
            }
        }

        // 4️⃣ Check acceptable status codes (2xx or 3xx)
        guard (200..<400).contains(httpResponse.statusCode) else {
            maxUnsafeness = max(maxUnsafeness, 4)
            return (false, maxUnsafeness)
        }

        // 5️⃣ Optional: TLS certificate verification
        if advancedDataProtection {
            let validTLS = await verifyTLS(url: url)
            if !validTLS {
                maxUnsafeness = max(maxUnsafeness, 6)
                return (false, maxUnsafeness)
            }
        }

        // ✅ All checks passed
        return (true, maxUnsafeness)
    }
    
    /// Verifies basic TLS information
    private static func verifyTLS(url: URL) async -> Bool {
        // Simple placeholder: checks if URLSession can reach HTTPS without error
        // For real pinning / cert checks, you'd need SecTrust APIs
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        do {
            _ = try await URLSession.shared.data(for: request)
            return true
        } catch {
            return false
        }
    }
}

