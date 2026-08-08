import SwiftUI

struct NumericField: View {
    let placeholder: String
    @Binding var value: Double
    var allowDecimal: Bool = true
    var onCommit: (() -> Void)? = nil
    var dismissTrigger: Int = 0
    var cancelTrigger: Int = 0

    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @State private var valueBeforeEditing: Double = 0
    @State private var isCancelling = false

    var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .multilineTextAlignment(.center)
            .keyboardType(allowDecimal ? .decimalPad : .numberPad)
            .autocorrectionDisabled(true)
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
                    valueBeforeEditing = value
                }
                text = value == 0 ? "" : formatValue(value)
                if !focused {
                    if !isCancelling {
                        onCommit?()
                    }
                    isCancelling = false
                }
            }
            .onAppear {
                text = value == 0 ? "" : formatValue(value)
            }
            .onChange(of: dismissTrigger) { _, _ in
                isFocused = false
            }
            .onChange(of: cancelTrigger) { _, _ in
                guard isFocused else { return }
                isCancelling = true
                value = valueBeforeEditing
                isFocused = false
            }
    }

    private func formatValue(_ v: Double) -> String {
        if v == v.rounded() {
            return String(Int(v))
        }
        return String(format: "%.1f", v)
    }
}
