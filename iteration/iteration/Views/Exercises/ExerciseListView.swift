import SwiftUI

struct ExerciseListView: View {
    @State private var exerciseVM = ExerciseViewModel()
    @State private var showAddExercise = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if exerciseVM.isLoading && exerciseVM.allExercises.isEmpty {
                    ProgressView().tint(Color.appText)
                } else if !exerciseVM.searchText.isEmpty {
                    searchResultsList
                } else {
                    categoryBoxGrid
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $exerciseVM.searchText, prompt: "Search exercises")
            .toolbar {
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
                categoryDetail(category)
            }
            .task {
                await exerciseVM.seedIfNeeded()
            }
        }
    }

    // MARK: - Category Box Grid (landing state)

    private var categoryColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

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

    // MARK: - Category Detail (drilled into a box)

    private func categoryDetail(_ category: String) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                equipmentFilter
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                LazyVStack(spacing: 0) {
                    ForEach(exerciseVM.filteredExercises) { exercise in
                        exerciseRow(exercise)
                    }
                }
                .padding(.top, 12)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle(category.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { exerciseVM.selectedCategory = category }
        .onDisappear { exerciseVM.selectedCategory = nil }
    }

    // MARK: - Search Results (global, ignores box grouping)

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(exerciseVM.filteredExercises) { exercise in
                    exerciseRow(exercise)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Equipment Filter

    private var equipmentFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", isSelected: exerciseVM.selectedEquipmentType == nil) {
                    exerciseVM.selectedEquipmentType = nil
                }
                ForEach(Exercise.EquipmentType.allCases, id: \.rawValue) { type in
                    filterChip(type.rawValue.capitalized,
                              isSelected: exerciseVM.selectedEquipmentType == type.rawValue) {
                        exerciseVM.selectedEquipmentType = type.rawValue
                    }
                }
            }
        }
    }

    // MARK: - Filter Chip

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
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

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.appPrimary)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appText)

                HStack(spacing: 6) {
                    Text(exercise.category.capitalized)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                    Text("·")
                        .foregroundStyle(Color.appMuted)
                    Text(exercise.equipmentType.capitalized)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                }
            }

            Spacer()

            if exercise.isCustom {
                Text("CUSTOM")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Color.appAccent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
