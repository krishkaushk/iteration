import SwiftUI

struct SignInView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("GYM")
                            .font(.system(size: 64, weight: .heavy))
                            .foregroundStyle(Color.appPrimary)
                            .tracking(-1)
                        Text("TRACKER")
                            .font(.system(size: 64, weight: .heavy))
                            .foregroundStyle(Color.appText)
                            .tracking(-1)
                    }
                    .padding(.top, 56)
                    .padding(.bottom, 8)

                    Rectangle()
                        .frame(height: 3)
                        .foregroundStyle(Color.appPrimary)
                        .padding(.bottom, 40)

                    VStack(spacing: 16) {
                        BlockTextField(label: "EMAIL", text: $email)
                        BlockTextField(label: "PASSWORD", text: $password, isSecure: true)
                    }
                    .padding(.bottom, 24)

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.appDestructive)
                            .padding(.bottom, 12)
                    }

                    BlockButton(title: "SIGN IN", isLoading: authViewModel.isLoading) {
                        Task { await authViewModel.signIn(email: email, password: password) }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("No account?")
                            .foregroundStyle(Color.appMuted)
                        Button("SIGN UP") { showSignUp = true }
                            .fontWeight(.heavy)
                            .foregroundStyle(Color.appPrimary)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}
