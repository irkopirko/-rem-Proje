//
//  InkAcademyApp.swift
//  InkAcademy
//
//  Created by Mesutcy on 26.03.2026.
//

import SwiftUI

@main
struct InkAcademyApp: App {
    @State private var container = DIContainer()

    var body: some Scene {
        WindowGroup {
            Group {
                if container.router.isAuthenticated {
                    MainTabView(container: container)
                } else {
                    LoginView(viewModel: container.makeAuthViewModel())
                }
            }
            .animation(.easeInOut(duration: 0.3), value: container.router.isAuthenticated)
            .task {
                // Restore Supabase session on launch (no-op for mock)
                if let supaAuth = container.authService as? SupabaseAuthService {
                    await supaAuth.restoreSession()
                    if supaAuth.currentUser != nil {
                        container.router.isAuthenticated = true
                    }
                }
            }
        }
    }
}