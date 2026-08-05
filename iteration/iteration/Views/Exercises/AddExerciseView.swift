import SwiftUI

struct AddExerciseView: View {
    var exerciseVM: ExerciseViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedCategory = Exercise.Category.chest.rawValue
    @State private var selectedEquipment = Exercise.EquipmentType.barbell.rawValue

    private var canSave: Bool { !name.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    BlockTextField(label: "EXERCISE NAME", text: $name)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("CATEGORY")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Color.appMuted)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Exercise.Category.allCases, id: \.rawValue) { cat in
                                    chipButton(cat.rawValue.capitalized,
                                              isSelected: selectedCategory == cat.rawValue) {
                                        selectedCategory = cat.rawValue
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("EQUIPMENT")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(Color.appMuted)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Exercise.EquipmentType.allCases, id: \.rawValue) { type in
                                    chipButton(type.rawValue.capitalized,
                                              isSelected: selectedEquipment == type.rawValue) {
                                        selectedEquipment = type.rawValue
                                    }
                                }
                            }
                        }
                    }

                    Spacer()

                    BlockButton(title: "ADD EXERCISE") {
                        Task {
                            await exerciseVM.addCustomExercise(
                                name: name,
                                category: selectedCategory,
                                equipmentType: selectedEquipment
                            )
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                }
                .padding(20)
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.appMuted)
                }
            }
        }
    }

    private func chipButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.appPrimary : Color.appSurface)
                .foregroundStyle(isSelected ? .white : Color.appText)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
