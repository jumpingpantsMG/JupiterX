//
//  SearchEngine.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/3/26.
//

import Foundation
import SwiftUI

struct SearchEngine {

    static func url(prompt: String, engine: String) -> URL {
        let query = prompt.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        switch engine {
        case "Bing":
            return URL(string: "https://www.bing.com/search?q=" + query)!
        case "DuckDuckGo":
            return URL(string: "https://duckduckgo.com/?q=" + query)!
        case "Yahoo":
            return URL(string: "https://yahoo.com/?p=" + query)!
        case "Ecosia":
            return URL(string: "https://www.ecosia.org/search?method=index&q=" + query)!
        default:
            return URL(string: "https://www.google.com/search?q=" + query)!
        }
    }
}

#Preview("SearchEngine URL Preview") {
    let url = SearchEngine.url(prompt: "hi", engine: "Ecosia")
    return Text(url.absoluteString)
        .padding()
}
