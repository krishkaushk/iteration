import SwiftUI

struct NumericField: View {
    let placeholder: String
    @Binding var value: Double
    var allowDecimal: Bool = true

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .multilineTextAlignment(.center)
            .onChange(of: text) { _, newValue in
                let allowed: Set<Character> = allowDecimal
                    ? Set("0123456789.")
                    : Set("0123456789")
                let filtered = String(newValue.filter { allowed.contains($0) })
                if filtered != newValue {
                    text = filtered
                }
                value = Double(filtered) ?? 0
            }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    text = value == 0 ? "" : formatValue(value)
                } else {
                    text = value == 0 ? "" : formatValue(value)
                }
            }
            .onAppear {
                text = value == 0 ? "" : formatValue(value)
            }
    }

    private func formatValue(_ v: Double) -> String {
        if v == v.rounded() {
            return String(Int(v))
        }
        return String(format: "%.1f", v)
    }
}
