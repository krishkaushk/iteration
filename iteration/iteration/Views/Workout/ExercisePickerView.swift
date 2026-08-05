import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseVM = ExerciseViewModel()
    var onSelect: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if exerciseVM.isLoading && exerciseVM.allExercises.isEmpty {
                    ProgressView().tint(Color.appText)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(exerciseVM.filteredExercises) { exercise in
                                Button {
                                    onSelect(exercise)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(Color.appText)
                                            HStack(spacing: 4) {
                                                Text(exercise.category.capitalized)
                                                Text("·")
                                                Text(exercise.equipmentType.capitalized)
                                            }
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.appMuted)
                                        }

                                        Spacer()

                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(Color.appPrimary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $exerciseVM.searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.appMuted)
                }
            }
            .task {
                await exerciseVM.loadExercises()
            }
        }
    }
}
