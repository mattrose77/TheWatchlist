//
//  EditProfileView.swift
//  The Watchlist
//
//  Created by Matt Rose on 19/06/2026.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName = "Add Name"
    
    @State private var editedName: String = ""
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Avatar section
                    avatarSection
                    
                    // Form fields
                    VStack(spacing: 24) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("Enter your name", text: $editedName)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
            .background(
                AppGradient.background
                    .ignoresSafeArea()
            )
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .disabled(editedName.isEmpty)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Profile Updated", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your profile has been successfully updated.")
            }
            .onAppear {
                editedName = userName
            }
        }
    }
    
    // MARK: - Avatar Section
    
    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "0E3D3A"),
                        Color(hex: "1A6B5A")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                
                Text(String((editedName.isEmpty ? "AN" : editedName).prefix(1)).uppercased())
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Button(action: {
                // Future: Add avatar change functionality
            }) {
                Text("Change Avatar")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        userName = editedName
        showingSaveConfirmation = true
    }
}

// MARK: - Preview

#Preview("Edit Profile") {
    EditProfileView()
}
