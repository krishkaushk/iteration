import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exerciseVM = ExerciseViewModel()
    @State private var showAddExercise = false
    var onSelect: (Exercise) -> Void

    private var categoryColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if exerciseVM.isLoading && exerciseVM.allExercises.isEmpty {
                    ProgressView().tint(Color.appText)
                } else if !exerciseVM.searchText.isEmpty {
                    exerciseList(exerciseVM.filteredExercises)
                } else {
                    categoryBoxGrid
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddExercise = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseView(exerciseVM: exerciseVM)
            }
            .navigationDestination(for: String.self) { category in
                exerciseList(exerciseVM.filteredExercises)
                    .navigationTitle(category.capitalized)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .onAppear { exerciseVM.selectedCategory = category }
                    .onDisappear { exerciseVM.selectedCategory = nil }
            }
            .task {
                await exerciseVM.seedIfNeeded()
            }
        }
    }

    // MARK: - Category Box Grid (landing state)

    private var categoryBoxGrid: some View {
        ScrollView {
            LazyVGrid(columns: categoryColumns, spacing: 12) {
                ForEach(Exercise.Category.allCases, id: \.rawValue) { category in
                    NavigationLink(value: category.rawValue) {
                        categoryBox(category)
                    }
                }
            }
            .padding(20)
        }
    }

    private func categoryBox(_ category: Exercise.Category) -> some View {
        let count = exerciseVM.exercisesByCategory[category.rawValue]?.count ?? 0
        return VStack(alignment: .leading, spacing: 6) {
            Text(category.rawValue.capitalized)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.appText)
            Text("\(count) exercises")
                .font(.system(size: 12))
                .foregroundStyle(Color.appMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 90)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Exercise List (used for both search results and a drilled-into category)

    private func exerciseList(_ exercises: [Exercise]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(exercises) { exercise in
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
