//
//  ContentView.swift
//  GymTracker
//
//  Created by Krish Kaushik on 2026-06-05.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        Group {
            if authViewModel.isCheckingAuth {
                ZStack {
                    Color.appBackground.ignoresSafeArea()
                    ProgressView()
                        .tint(Color.appText)
                }
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
    }
}
