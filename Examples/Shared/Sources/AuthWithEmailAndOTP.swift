//
//  AuthWithPhoneAndOTP.swift
//  Examples
//
//  Created by Danh Nguyen on 06/04/2023.
//

import SwiftUI

struct AuthWithEmailAndOTP: View {
    @Environment(\.goTrueClient) private var client
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var otpNumber: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            Form {
                Section {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                    TextField("OTP",  text: $otpNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.oneTimeCode)
                }
                
                Section {
                    Button("Request OTP") {
                        requestOTP()
                    }
                    Button("Confirm OTP") {
                        confirmOtp()
                    }
                }
            }
        }
    }
    
    private func requestOTP() {
        isLoading = true
        Task {
            // Remember to config Supabase Email templates -> Magic Link -> {{ .Token }}
            // https://supabase.com/docs/guides/auth/auth-email-templates
            try await client.signInWithOTP(email: email)
            isLoading = false
        }
    }
    
    private func confirmOtp() {
        isLoading = true
        Task {
            do {
                try await client.verifyOTP(email: email, token: otpNumber, type: .magiclink)
            } catch {
                NSLog("Error \(error)")
            }
            isLoading = false
        }
    }
}

struct AuthWithPhoneAndOTP_Previews: PreviewProvider {
    static var previews: some View {
        AuthWithEmailAndOTP()
    }
}
