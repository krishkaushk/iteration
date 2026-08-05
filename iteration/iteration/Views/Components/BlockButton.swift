import SwiftUI

struct BlockButton: View {
    let title: String
    var isLoading: Bool = false
    var isDestructive: Bool = false
    let action: () -> Void

    private var background: Color {
        isDestructive ? Color.appDestructive : Color.appPrimary
    }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1.5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(background)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading)
    }
}
