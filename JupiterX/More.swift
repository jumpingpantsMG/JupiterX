import SwiftUI

struct More: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("Settings") {
                    Label("Configuration", systemImage: "gear")
                    Label("Privacy", systemImage: "hand.raised")
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }

                Section("Help & About") {
                    Label("Help Center", systemImage: "questionmark.circle")
                    Label("Feedback", systemImage: "envelope")
                    Label("About JupiterX", systemImage: "info.circle")
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    More()
}
