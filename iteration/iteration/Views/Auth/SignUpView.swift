import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool { password == confirmPassword }
    private var canSubmit: Bool { !email.isEmpty && password.count >= 6 && passwordsMatch }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("CREATE")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(Color.appPrimary)
                        .tracking(-1)
                    Text("ACCOUNT")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(Color.appText)
                        .tracking(-1)
                }
                .padding(.top, 32)
                .padding(.bottom, 8)

                Rectangle()
                    .frame(height: 3)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.bottom, 40)

                VStack(spacing: 16) {
                    BlockTextField(label: "EMAIL", text: $email)
                    BlockTextField(label: "PASSWORD", text: $password, isSecure: true)
                    BlockTextField(label: "CONFIRM PASSWORD", text: $confirmPassword, isSecure: true)
                }
                .padding(.bottom, 12)

                if !passwordsMatch && !confirmPassword.isEmpty {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundStyle(Color.appDestructive)
                        .padding(.bottom, 8)
                }

                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.appDestructive)
                        .padding(.bottom, 12)
                }

                BlockButton(title: "CREATE ACCOUNT", isLoading: authViewModel.isLoading) {
                    Task { await authViewModel.signUp(email: email, password: password) }
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)

                Spacer()

                HStack(spacing: 6) {
                    Text("Have an account?")
                        .foregroundStyle(Color.appMuted)
                    Button("SIGN IN") { dismiss() }
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.appPrimary)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
    }
}
