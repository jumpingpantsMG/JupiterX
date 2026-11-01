//
//  StartPage.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/4/26.
//


import SwiftUI

struct StartPage: View {
    var onSelectURL: (String) -> Void

    private let quickLinks: [QuickLink]

    init(onSelectURL: @escaping (String) -> Void) {
        self.onSelectURL = onSelectURL
        let engineLower = ConfigView.currentEngine(lowercase: true)
        let engineTitle = ConfigView.currentEngine(lowercase: false)
        let engineDomain = (engineLower == "ecosia") ? "org" : "com"
        self.quickLinks = [
            .init(
                title: engineTitle,
                icon: "globe",
                url: "https://\(engineLower).\(engineDomain)"
            ),
            .init(title: "YouTube", icon: "play.rectangle", url: "https://youtube.com"),
            .init(title: "GitHub", icon: "chevron.left.slash.chevron.right", url: "https://github.com"),
            .init(title: "Apple", icon: "applelogo", url: "https://apple.com")
        ]
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("JupiterX")
                .font(.largeTitle.bold())

            Text("Start browsing")
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 16
            ) {
                ForEach(quickLinks) { link in
                    Button {
                        onSelectURL(link.url)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: link.icon)
                                .font(.system(size: 28))

                            Text(link.title)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct QuickLink: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let url: String
}

#Preview {
    StartPage { _ in }
}
