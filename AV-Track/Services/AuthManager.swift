//
//  AuthManager.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 12.03.2026..
//

import Foundation
import Combine
import SwiftUI
import Supabase
import SwiftData

@MainActor
@Observable
final class AuthManager {
    static let shared = AuthManager()

    var session: Session?
    var isLoading = false
    var currentError: String?

    private init() {
        Task {
            await initializeSession()
        }
    }

    func initializeSession() async {
        do {
            isLoading = true
            session = try await supabase.auth.session
            
            for await state in await supabase.auth.authStateChanges {
                self.session = state.session
            }
        } catch {
            print("No active session found: \(error)")
            session = nil
        }
        isLoading = false
    }

    func login(email: String, password: String) async {
        do {
            isLoading = true
            currentError = nil
            session = try await supabase.auth.signIn(email: email, password: password)
        } catch {
            currentError = error.localizedDescription
        }
        isLoading = false
    }

    func signup(email: String, password: String) async {
        do {
            isLoading = true
            currentError = nil
            let response = try await supabase.auth.signUp(email: email, password: password)
            session = response.session
            
            if session == nil {
                currentError = "Signup successful. Please check your email to confirm your account."
            }
        } catch {
            currentError = error.localizedDescription
        }
        isLoading = false
    }
    
    func logout() async {
        do {
            isLoading = true
            try await supabase.auth.signOut()
            session = nil
        } catch {
            currentError = error.localizedDescription
            session = nil
        }
        isLoading = false
    }
}
