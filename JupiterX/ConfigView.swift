//
//  ConfigView.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/2/26.
//

import SwiftUI

struct ConfigView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var config: Config
    @StateObject private var accountManager = AccountManager()
    @State private var showAccountSheet = false
    @State private var draft = Config()
    @State private var selectedTab: SettingsTab = .general
    @State private var newBlacklistEntry: String = ""
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case security = "Security"
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Segmented tabs
                Picker("Section", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                // General Section
                if selectedTab == .general {
                    Section("General") {
                        Toggle("Back and Forward Navigation", isOn: $draft.navActions)
                        Toggle("Magnification Gestures", isOn: $draft.magnification)
                        Toggle("Weblink Previews", isOn: $draft.linkPreviews)
                        Toggle("Text Selection", isOn: $draft.textSelection)
                        Picker("Default Search Engine", selection: $draft.DefaultSearchEngine) {
                            Text("Google").tag("Google")
                            Text("Bing").tag("Bing")
                            Text("DuckDuckGo").tag("DuckDuckGo")
                            Text("Yahoo").tag("Yahoo")
                            Text("Ecosia")
                                .tag("Ecosia")
                        }
                        .pickerStyle(.menu)
                    }
                    Section {
                        Button {
                            showAccountSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                Text("Account")
                            }
                        }
                    }
                }

                // Security Section
                if selectedTab == .security {
                    Section("Security") {
                        Toggle("Advanced data protection", isOn: $draft.AdvancedDataProtection)
                    }
                    Section("Website Blacklist") {
                        if !draft.AdvancedDataProtection {
                            Text("Enable Advanced Data Protection to manage a website blacklist.")
                                .foregroundStyle(.secondary)
                        } else {
                            if draft.websiteBlacklist.isEmpty {
                                Text("No blocked websites").foregroundStyle(.secondary)
                            } else {
                                ForEach(draft.websiteBlacklist, id: \.self) { host in
                                    HStack {
                                        Image(systemName: "nosign")
                                            .foregroundStyle(.red)
                                        Text(host)
                                        Spacer()
                                        Button(role: .destructive) {
                                            if let idx = draft.websiteBlacklist.firstIndex(of: host) {
                                                draft.websiteBlacklist.remove(at: idx)
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }
                            }
                            HStack {
                                TextField("Add domain e.g. example.com", text: $newBlacklistEntry)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                Button("Add") {
                                    let trimmed = newBlacklistEntry.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmed.isEmpty, !draft.websiteBlacklist.contains(trimmed) {
                                        draft.websiteBlacklist.append(trimmed)
                                        newBlacklistEntry = ""
                                    }
                                }
                                .disabled(newBlacklistEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        draft.save()
                        config = draft
                        dismiss()
                    }
                    .disabled(draft == config)
                }
            }
            .onAppear {
                let persisted = Config.load()
                self.draft = persisted
                self.config = persisted
            }
            .sheet(isPresented: $showAccountSheet) {
                AccountView(manager: accountManager)
            }
        }
    
    }
    
    static func currentEngine(lowercase: Bool) -> String {
        var string = Config.load().DefaultSearchEngine
        if lowercase { string = string.lowercased() }
        return string
    }
    
}

#Preview {
    @Previewable @State var config = Config()
    ConfigView(config: $config)
}


struct Config: Equatable, Codable {
    var navActions = false
    var magnification = false
    var linkPreviews = false
    var textSelection = false
    var AdvancedDataProtection = false
    
    var DefaultSearchEngine = "Google"
    var websiteBlacklist: [String] = []
    var schemaVersion: Int = 1
    
    // MARK: - Persistence
    private static let defaultsKey = "Config"

    // Default instance used for merging when loading older schemas
    private static var defaults: Config { Config() }

    static func load() -> Config {
        // Prefer dictionary storage if available
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return Config.fromDictionary(dict, fallback: defaults)
        }
        // Fallback to older Codable blob if present
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(Config.self, from: data) {
            return decoded
        }
        return Config()
    }

    func save() {
        // Save as a dictionary to be tolerant of added/removed keys
        let dict: [String: Any] = [
            "navActions": navActions,
            "magnification": magnification,
            "linkPreviews": linkPreviews,
            "textSelection": textSelection,
            "AdvancedDataProtection": AdvancedDataProtection,
            "DefaultSearchEngine": DefaultSearchEngine,
            "websiteBlacklist": websiteBlacklist,
            "schemaVersion": schemaVersion
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict) {
            UserDefaults.standard.set(data, forKey: Config.defaultsKey)
        }
    }

    private static func fromDictionary(_ dict: [String: Any], fallback: Config) -> Config {
        var cfg = fallback
        if let v = dict["navActions"] as? Bool { cfg.navActions = v }
        if let v = dict["magnification"] as? Bool { cfg.magnification = v }
        if let v = dict["linkPreviews"] as? Bool { cfg.linkPreviews = v }
        if let v = dict["textSelection"] as? Bool { cfg.textSelection = v }
        if let v = dict["AdvancedDataProtection"] as? Bool { cfg.AdvancedDataProtection = v }
        if let v = dict["DefaultSearchEngine"] as? String { cfg.DefaultSearchEngine = v }
        if let v = dict["websiteBlacklist"] as? [String] { cfg.websiteBlacklist = v }
        if let v = dict["schemaVersion"] as? Int { cfg.schemaVersion = v }
        return cfg
    }
}

