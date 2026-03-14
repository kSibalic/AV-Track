//
//  LoginView.swift
//  AV-Track
//
//  Created by Karlo Šibalić on 12.03.2026..
//

import Foundation
import SwiftUI

struct LoginView: View {
    @State private var authManager = AuthManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var isSignupMode = false

    private var isValid: Bool {
        if isSignupMode {
            return !email.trimmingCharacters(in: .whitespaces).isEmpty && isPasswordValid(password)
        } else {
            return !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
        }
    }
    
    private func isPasswordValid(_ pass: String) -> Bool {
        let hasMinLength = pass.count >= 8
        let hasUppercase = pass.contains(where: { $0.isUppercase })
        let hasLowercase = pass.contains(where: { $0.isLowercase })
        let hasNumber = pass.contains(where: { $0.isNumber })
        
        return hasMinLength && hasUppercase && hasLowercase && hasNumber
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.accentColor)
                            .padding(.bottom, 8)

                        Text("AV-Track")
                            .font(.largeTitle.weight(.bold))

                        Text("Rental Inventory Management")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Form Fields
                    VStack(spacing: 16) {
                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .padding()
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if isSignupMode {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Minimum 8 characters", systemImage: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                Label("Requires uppercase letter", systemImage: password.contains(where: { $0.isUppercase }) ? "checkmark.circle.fill" : "circle")
                                Label("Requires lowercase letter", systemImage: password.contains(where: { $0.isLowercase }) ? "checkmark.circle.fill" : "circle")
                                Label("Requires a number", systemImage: password.contains(where: { $0.isNumber }) ? "checkmark.circle.fill" : "circle")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.horizontal)

                    // Error Message
                    if let error = authManager.currentError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Action Buttons
                    VStack(spacing: 16) {
                        Button {
                            Task {
                                if isSignupMode {
                                    await authManager.signup(email: email, password: password)
                                } else {
                                    await authManager.login(email: email, password: password)
                                }
                            }
                        } label: {
                            Group {
                                if authManager.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignupMode ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValid ? Color.accentColor : Color.accentColor.opacity(0.5))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!isValid || authManager.isLoading)

                        // Toggle Mode
                        Button {
                            withAnimation {
                                isSignupMode.toggle()
                                authManager.currentError = nil
                            }
                        } label: {
                            Text(isSignupMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .disabled(authManager.isLoading)
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

#Preview {
    LoginView()
}

