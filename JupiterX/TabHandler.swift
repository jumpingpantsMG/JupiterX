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
    var faviconURL: URL? = nil

    init(id: UUID = UUID(), title: String, urlString: String = "StartPage://", htmlTitle: String? = nil) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.htmlTitle = htmlTitle
    }
}

extension BrowserTab {
    var displayTitle: String {
        if let t = htmlTitle, !t.isEmpty { return t }
        return urlString == "StartPage://" ? "New Tab" : urlString
    }
}

struct TabHandler: View {
    @State private var tabs: [BrowserTab] = [BrowserTab(title: "New Tab")]
    @State private var selectedTabID: BrowserTab.ID?
    @State private var config = Config.load()
    @State private var showSettings = false

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
                                title: tab.displayTitle,
                                faviconURL: tab.urlString == "StartPage://" ? nil : tab.faviconURL,
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

                // Keep every tab alive and only show the selected one,
                // so switching tabs doesn't reload pages.
                ZStack {
                    ForEach(tabs) { tab in
                        let isSelected = tab.id == selectedTab?.id
                        content(for: tab)
                            .opacity(isSelected ? 1 : 0)
                            .allowsHitTesting(isSelected)
                            .accessibilityHidden(!isSelected)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(currentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showSettings = true }
                }
            }
            .sheet(isPresented: $showSettings) { ConfigView(config: $config) }
            .onAppear {
                if selectedTabID == nil {
                    selectedTabID = tabs.first?.id
                }
            }
        }
    }

    /// Navigation title logic:
    /// If the selected tab is on the start page or its title is "New Tab",
    /// return an empty string to avoid showing placeholder titles.
    /// Otherwise, prefer the htmlTitle if available, then fall back to the urlString.
    private var currentTitle: String {
        guard let tab = selectedTab else { return "" }
        if tab.urlString == "StartPage://" || tab.htmlTitle == "New Tab" {
            return ""
        }
        return tab.htmlTitle ?? tab.urlString
    }

    @ViewBuilder
    private func content(for tab: BrowserTab) -> some View {
        if let idx = tabs.firstIndex(where: { $0.id == tab.id }) {
            ContentView(
                urlString: $tabs[idx].urlString,
                htmlTitle: $tabs[idx].htmlTitle,
                faviconURL: $tabs[idx].faviconURL,
                config: config
            )
            .id(tab.id) // separate state per tab
        }
    }

    private func addTab() {
        let new = BrowserTab(title: "New Tab")
        tabs.append(new)
        selectedTabID = new.id
    }

    private func close(_ tab: BrowserTab) {
        guard let idx = tabs.firstIndex(of: tab) else { return }
        let closingIsSelected = (tab.id == selectedTabID)
        tabs.remove(at: idx)

        if tabs.isEmpty {
            let start = BrowserTab(title: "New Tab")
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
    let faviconURL: URL?
    let isActive: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Group {
                if let faviconURL {
                    AsyncImage(url: faviconURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFit()
                        } else {
                            Image(systemName: "globe").foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "globe").foregroundStyle(.secondary)
                }
            }
            .frame(width: 14, height: 14)
            .clipShape(RoundedRectangle(cornerRadius: 3))

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
