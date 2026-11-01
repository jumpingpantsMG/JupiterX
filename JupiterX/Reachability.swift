//
//  Reachability.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/2/26.
//

import Foundation

enum Reachability {
    static func checkURL(_ urlString: String) async -> Bool {
        guard let originalURL = URL(string: urlString),
              let scheme = originalURL.scheme,
              let host = originalURL.host else {
            return false
        }
        let base = scheme + "://" + host
        print(base)
        guard let url = URL(string: base) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...399).contains(httpResponse.statusCode)
            }
        } catch {
            print("Request failed with error: \(error)")
        }
        return false
    }
}
