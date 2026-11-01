//
//  TabHandler.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/17/26.
//

import SwiftUI

struct BrowserTab: Identifiable, Hashable {
    let id: UUID
    var title: String
    var urlString: String = "StartPage://"
    var htmlTitle: String? = nil
    init(id: UUID = UUID(), title: String, urlString: String = "StartPage://", htmlTitle: String? = nil) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.htmlTitle = htmlTitle
    }
}

struct TabHandler: View {
    @State private var tabs: [BrowserTab] = [BrowserTab(title: "Start", urlString: "StartPage://")]
    @State private var selectedTabID: BrowserTab.ID?

    private var selectedTab: BrowserTab? {
        tabs.first(where: { $0.id == selectedTabID }) ?? tabs.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tabs) { tab in
                            TabChip(
                                title: tab.title,
                                isActive: tab.id == selectedTab?.id,
                                onClose: { close(tab) }
                            )
                            .onTapGesture { selectedTabID = tab.id }
                        }

                        Button(action: addTab) {
                            Image(systemName: "plus")
                                .padding(6)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .accessibilityLabel("New Tab")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)

                Divider()

                Group {
                    if let current = selectedTab {
                        content(for: current)
                    } else {
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(currentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
            }
            .onAppear {
                if selectedTabID == nil {
                    selectedTabID = tabs.first?.id
                }
            }
        }
    }

    /// Navigation title logic:
    /// If the selected tab's urlString is "StartPage://" (StartPage) or htmlTitle is "New Tab",
    /// return an empty string to avoid showing placeholder titles.
    /// Otherwise, prefer the htmlTitle if available, then fallback to the urlString.
    private var currentTitle: String {
        guard let tab = selectedTab else { return "" }
        if tab.urlString == "StartPage://" || tab.htmlTitle == "New Tab" {
            return ""
        }
        return tab.htmlTitle ?? tab.urlString
    }

    @ViewBuilder
    private func content(for tab: BrowserTab) -> some View {
        // Using if-let instead of guard to avoid early return which is disallowed in @ViewBuilder
        // This fixes SwiftUI's opaque return type requirement by ensuring all code paths return a View
        if let idx = tabs.firstIndex(where: { $0.id == tab.id }) {
            if tab.title == "Start" {
                StartPage { newTitle in
                    tabs[idx].title = newTitle
                }
            } else {
                ContentView(urlString: $tabs[idx].urlString, htmlTitle: $tabs[idx].htmlTitle)
            }
        } else {
            EmptyView()
        }
    }

    private func addTab() {
        let new = BrowserTab(title: "New Tab", urlString: "StartPage://")
        tabs.append(new)
        selectedTabID = new.id
    }

    private func close(_ tab: BrowserTab) {
        guard let idx = tabs.firstIndex(of: tab) else { return }
        let closingIsSelected = (tab.id == selectedTabID)
        tabs.remove(at: idx)

        if tabs.isEmpty {
            let start = BrowserTab(title: "Start", urlString: "StartPage://")
            tabs = [start]
            selectedTabID = start.id
        } else if closingIsSelected {
            let newIndex = max(0, idx - 1)
            selectedTabID = tabs[min(newIndex, tabs.count - 1)].id
        }
    }
}

private struct TabChip: View {
    let title: String
    let isActive: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isActive ? "circle.fill" : "circle")
                .font(.system(size: 8))
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
            Text(title)
                .lineLimit(1)
                .font(.subheadline)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(4)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Tab")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isActive ? Color(.secondarySystemBackground) : Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isActive ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    TabHandler()
}

