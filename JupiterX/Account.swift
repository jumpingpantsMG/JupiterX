//
//  Account.swift
//  JupiterX
//
//  Created by Jaiden Kumar on 1/3/26.
//


import SwiftUI
import Combine

// MARK: - Account Model
struct Account {
    var username: String = ""
    var email: String = ""
    var isSignedIn: Bool = false
}

// MARK: - Account Manager
class AccountManager: ObservableObject {
    @Published var account = Account()
    
    func signIn(username: String, email: String) {
        account.username = username
        account.email = email
        account.isSignedIn = true
    }
    
    func signUp(username: String, email: String) {
        account.username = username
        account.email = email
        account.isSignedIn = true
    }
    
    func signOut() {
        account = Account()
    }
    
    func updateSettings(username: String, email: String) {
        account.username = username
        account.email = email
    }
}

// MARK: - Account View
struct AccountView: View {
    @ObservedObject var manager: AccountManager
    @Environment(\.dismiss) var dismiss
    @State private var username = ""
    @State private var email = ""
    
    var body: some View {
        NavigationStack {
            Form {
                if manager.account.isSignedIn {
                    Section("Account Settings") {
                        TextField("Username", text: $username)
                        TextField("Email", text: $email)
                        Button("Update Settings") {
                            manager.updateSettings(username: username, email: email)
                        }
                        Button("Sign Out", role: .destructive) {
                            manager.signOut()
                        }
                    }
                } else {
                    Section("Sign In / Sign Up") {
                        TextField("Username", text: $username)
                        TextField("Email", text: $email)
                        Button("Sign In") {
                            manager.signIn(username: username, email: email)
                        }
                        Button("Sign Up") {
                            manager.signUp(username: username, email: email)
                        }
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .onAppear {
            // Load current account info
            username = manager.account.username
            email = manager.account.email
        }
    }
}

// MARK: - Preview
#Preview {
    let manager = AccountManager()
    AccountView(manager: manager)
}

