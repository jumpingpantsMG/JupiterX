import SwiftUI

enum SidebarItem: String, Hashable {
    case reading
    case history, bookmarks
}

struct Sidebar: View {
    @State private var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
                item("Reading List", "text.book.closed", .reading)
                item("History", "clock", .history)
                item("Bookmarks", "bookmark", .bookmarks)
            
      
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
    }

    // MARK: - Helpers

    private func sidebarSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Section {
            content()
        } header: {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.top, 6)
        }
    }

    private func item(
        _ title: String,
        _ icon: String,
        _ tag: SidebarItem
    ) -> some View {
        Label {
            Text(title)
                .font(.system(size: 13)) // Safari text size
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 16)
        }
        .tag(tag)
        .padding(.vertical, 4) // Safari row height
    }
}

#Preview {
    NavigationSplitView {
        Sidebar()
    } detail: {
        Text("Detail View")
    }
}
