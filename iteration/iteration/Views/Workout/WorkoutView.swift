import SwiftUI

struct WorkoutView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(WorkoutViewModel.self) private var workoutVM
    @State private var gymVM = GymViewModel()
    @State private var showExercisePicker = false
    @State private var showGymPicker = false
    @State private var showFinishConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if workoutVM.isActive {
                    activeWorkoutView
                } else {
                    startView
                }

                if workoutVM.isRestTimerActive {
                    restTimerOverlay
                }
            }
            .navigationTitle(workoutVM.isActive ? "Workout" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView { exercise in
                    workoutVM.addExercise(exercise)
                }
            }
            .sheet(isPresented: $showGymPicker) {
                GymPickerView(gymVM: gymVM) { gym in
                    workoutVM.startWorkout(gym: gym)
                }
            }
            .task {
                await gymVM.loadGyms()
            }
        }
    }

    // MARK: - Start View

    private var startView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.appPrimary)

            Text("Ready to train?")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.appText)

            BlockButton(title: "START WORKOUT") {
                if gymVM.gyms.isEmpty {
                    workoutVM.startWorkout()
                } else {
                    showGymPicker = true
                }
            }
            .padding(.horizontal, 40)

            Button("Skip gym selection") {
                workoutVM.startWorkout()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.appMuted)

            Spacer()
        }
    }

    // MARK: - Active Workout

    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            if let gymName = workoutVM.selectedGym?.name {
                HStack {
                    Image(systemName: "building.2")
                        .font(.system(size: 12))
                    Text(gymName)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.appMuted)
                .padding(.top, 8)
            }

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(workoutVM.currentSession!.exercises.enumerated()), id: \.element.id) { exIndex, exercise in
                        exerciseCard(exercise, at: exIndex)
                    }
                }
                .padding(20)
            }

            bottomBar
        }
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ exercise: WorkoutExercise, at exIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appText)

                Spacer()

                Button {
                    workoutVM.removeExercise(at: exIndex)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                }
            }

            HStack(spacing: 0) {
                Text("SET")
                    .frame(width: 40, alignment: .leading)
                Text("WEIGHT")
                    .frame(maxWidth: .infinity)
                Text("REPS")
                    .frame(maxWidth: .infinity)
                Text("")
                    .frame(width: 44)
            }
            .font(.system(size: 11, weight: .medium))
            .tracking(0.6)
            .foregroundStyle(Color.appMuted)

            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, exerciseSet in
                setRow(exerciseSet, exerciseIndex: exIndex, setIndex: setIndex)
            }

            Button {
                workoutVM.addSet(toExerciseAt: exIndex)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                    Text("Add set")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.appPrimary)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Set Row

    private func setRow(_ exerciseSet: ExerciseSet, exerciseIndex: Int, setIndex: Int) -> some View {
        HStack(spacing: 0) {
            Button {
                guard let session = workoutVM.currentSession,
                      exerciseIndex < session.exercises.count,
                      setIndex < session.exercises[exerciseIndex].sets.count
                else { return }
                workoutVM.removeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
            } label: {
                Text("\(exerciseSet.setNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appDestructive)
                    .frame(width: 40, alignment: .leading)
            }

            NumericField(
                placeholder: "0",
                value: Binding(
                    get: {
                        guard let session = workoutVM.currentSession,
                              exerciseIndex < session.exercises.count,
                              setIndex < session.exercises[exerciseIndex].sets.count
                        else { return 0 }
                        return session.exercises[exerciseIndex].sets[setIndex].weight
                    },
                    set: { workoutVM.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: $0, reps: exerciseSet.reps) }
                )
            )
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.appText)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer().frame(width: 8)

            NumericField(
                placeholder: "0",
                value: Binding(
                    get: {
                        guard let session = workoutVM.currentSession,
                              exerciseIndex < session.exercises.count,
                              setIndex < session.exercises[exerciseIndex].sets.count
                        else { return 0 }
                        return Double(session.exercises[exerciseIndex].sets[setIndex].reps)
                    },
                    set: { workoutVM.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: exerciseSet.weight, reps: Int($0)) }
                ),
                allowDecimal: false
            )
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.appText)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Button {
                workoutVM.toggleSetComplete(exerciseIndex: exerciseIndex, setIndex: setIndex)
            } label: {
                Image(systemName: exerciseSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(exerciseSet.isCompleted ? Color.appAccent : Color.appMuted)
            }
            .frame(width: 44)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                showExercisePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Exercise")
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.appSurface)
                .foregroundStyle(Color.appText)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showFinishConfirm = true
            } label: {
                Text("Finish")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.appPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .alert("Finish workout?", isPresented: $showFinishConfirm) {
                Button("Finish", role: .destructive) {
                    Task { await workoutVM.finishWorkout() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.appSurface)
    }

    // MARK: - Rest Timer Overlay

    private var restTimerOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("REST")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(Color.appAccent)

                    Text(workoutVM.restTimerFormatted)
                        .font(.system(size: 32, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    workoutVM.dismissRestTimer()
                } label: {
                    Text("DONE")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(1)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(20)
            .background(Color.appCardMaroon)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: workoutVM.isRestTimerActive)
    }
}
