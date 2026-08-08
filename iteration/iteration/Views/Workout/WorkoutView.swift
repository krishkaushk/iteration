import SwiftUI

struct WorkoutView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(WorkoutViewModel.self) private var workoutVM
    @State private var gymVM = GymViewModel()
    @State private var showExercisePicker = false
    @State private var showGymPicker = false
    @State private var showFinishConfirm = false
    @State private var showCancelConfirm = false
    @State private var keyboardDismissTrigger = 0
    @State private var keyboardCancelTrigger = 0
    @State private var manualExpansionOverrides: [String: Bool] = [:]

    private var hasPendingCompletion: Bool {
        guard let session = workoutVM.currentSession else { return false }
        for exercise in session.exercises {
            for set in exercise.sets where set.reps > 0 && !set.isCompleted {
                return true
            }
        }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if workoutVM.isActive {
                    activeWorkoutView
                } else {
                    startView
                }
            }
            .navigationTitle(workoutVM.isActive ? "Workout" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            // Keep the bottom bar pinned at the true bottom of the screen instead of
            // sliding up above the keyboard along with the rest of the layout.
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .toolbar {
                // decimalPad/numberPad have no Return key, so there's otherwise no other
                // way to signal "done typing" — one Done button, shared by every field.
                ToolbarItemGroup(placement: .keyboard) {
                    Button {
                        keyboardCancelTrigger += 1
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(Color.appMuted)
                    .padding(.bottom, 6)

                    Spacer()

                    Button {
                        keyboardDismissTrigger += 1
                    } label: {
                        Text("Done")
                            .fontWeight(hasPendingCompletion ? .bold : .regular)
                    }
                    .tint(hasPendingCompletion ? Color.appAccent : Color.appMuted)
                    .padding(.bottom, 6)
                }
            }
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
                            .opacity(dimAmount(for: exIndex))
                            .saturation(dimAmount(for: exIndex))
                    }
                }
                .padding(20)
                .animation(.easeInOut(duration: 0.3), value: workoutVM.isRestTimerActive)
                .animation(.easeInOut(duration: 0.25), value: manualExpansionOverrides)
                .contentShape(Rectangle())
                .onTapGesture {
                    keyboardDismissTrigger += 1
                }
            }
            .scrollDismissesKeyboard(.immediately)

            bottomBar
        }
    }

    // MARK: - Exercise Card

    private func dimAmount(for exIndex: Int) -> Double {
        guard workoutVM.isRestTimerActive, workoutVM.restTimerExerciseIndex != exIndex else { return 1 }
        return 0.4
    }

    // Only the most-recently-added exercise is expanded by default — everything
    // else collapses to a compact summary until tapped. An exercise currently
    // resting always stays expanded regardless of that default or any manual
    // override, since collapsing it mid-rest would hide the timer/Done button.
    private func isExpanded(exercise: WorkoutExercise, at exIndex: Int, totalCount: Int) -> Bool {
        if workoutVM.isRestTimerActive && workoutVM.restTimerExerciseIndex == exIndex {
            return true
        }
        if let override = manualExpansionOverrides[exercise.id] {
            return override
        }
        return exIndex == totalCount - 1
    }

    private func toggleExpanded(exercise: WorkoutExercise, at exIndex: Int, totalCount: Int) {
        let currentlyExpanded = isExpanded(exercise: exercise, at: exIndex, totalCount: totalCount)
        manualExpansionOverrides[exercise.id] = !currentlyExpanded
    }

    private func collapsedSummary(_ exercise: WorkoutExercise) -> String {
        let completed = exercise.sets.filter(\.isCompleted).count
        return completed == 0 ? "No sets logged" : "\(completed) set\(completed == 1 ? "" : "s") logged"
    }

    private func exerciseCard(_ exercise: WorkoutExercise, at exIndex: Int) -> some View {
        let isTimerHere = workoutVM.isRestTimerActive && workoutVM.restTimerExerciseIndex == exIndex
        let totalCount = workoutVM.currentSession?.exercises.count ?? 0
        let expanded = isExpanded(exercise: exercise, at: exIndex, totalCount: totalCount)

        return VStack(alignment: .leading, spacing: expanded ? 12 : 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.exerciseName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appText)

                    if !expanded {
                        Text(collapsedSummary(exercise))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appMuted)
                    .rotationEffect(.degrees(expanded ? 0 : -90))

                Button {
                    workoutVM.removeExercise(at: exIndex)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                toggleExpanded(exercise: exercise, at: exIndex, totalCount: totalCount)
            }

            if expanded {
                HStack(spacing: 0) {
                    Text("SET")
                        .frame(width: 40, alignment: .leading)
                    Text("WEIGHT")
                        .frame(maxWidth: .infinity)
                    Text("REPS")
                        .frame(maxWidth: .infinity)
                    Text("")
                        .frame(width: 44)
                    Text("")
                        .frame(width: 28)
                }
                .font(.system(size: 11, weight: .medium))
                .tracking(0.6)
                .foregroundStyle(Color.appMuted)

                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, exerciseSet in
                    if let restSeconds = exerciseSet.restSeconds {
                        restAccumulatedLabel(restSeconds)
                    }

                    setRow(exerciseSet, exerciseIndex: exIndex, setIndex: setIndex)

                    // Sits between the set that was just completed and the fresh blank
                    // set behind it — not a floating overlay competing for attention.
                    if isTimerHere && setIndex == exercise.sets.count - 2 {
                        inlineRestTimer
                    }
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
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func restAccumulatedLabel(_ seconds: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 10))
            Text("Rested \(formattedRestDuration(seconds))")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color.appMuted)
    }

    private func formattedRestDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(remainder)s"
        }
        return "\(remainder)s"
    }

    // MARK: - Set Row

    private func setRow(_ exerciseSet: ExerciseSet, exerciseIndex: Int, setIndex: Int) -> some View {
        let isSkeleton = exerciseSet.reps == 0 && !exerciseSet.isCompleted

        return HStack(spacing: 0) {
            Text("\(exerciseSet.setNumber)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSkeleton ? Color.appMuted : Color.appText)
                .frame(width: 40, alignment: .leading)

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
                ),
                dismissTrigger: keyboardDismissTrigger,
                cancelTrigger: keyboardCancelTrigger
            )
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.appText)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSkeleton ? Color.clear : Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.appBorder, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .opacity(isSkeleton ? 1 : 0)
            )

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
                allowDecimal: false,
                onCommit: {
                    workoutVM.completeSetIfReady(exerciseIndex: exerciseIndex, setIndex: setIndex)
                },
                dismissTrigger: keyboardDismissTrigger,
                cancelTrigger: keyboardCancelTrigger
            )
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.appText)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSkeleton ? Color.clear : Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.appBorder, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .opacity(isSkeleton ? 1 : 0)
            )

            Button {
                workoutVM.toggleSetComplete(exerciseIndex: exerciseIndex, setIndex: setIndex)
            } label: {
                Image(systemName: exerciseSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(exerciseSet.isCompleted ? Color.appAccent : (isSkeleton ? Color.appBorder : Color.appMuted))
            }
            .frame(width: 44)
            .disabled(isSkeleton)

            Button {
                guard let session = workoutVM.currentSession,
                      exerciseIndex < session.exercises.count,
                      setIndex < session.exercises[exerciseIndex].sets.count
                else { return }
                workoutVM.removeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appMuted)
            }
            .frame(width: 28)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                showCancelConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .background(Color.appSurface)
                    .foregroundStyle(Color.appDestructive)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .alert("Discard workout?", isPresented: $showCancelConfirm) {
                Button("Discard", role: .destructive) {
                    workoutVM.cancelWorkout()
                }
                Button("Keep Going", role: .cancel) {}
            } message: {
                Text("This workout hasn't been saved yet. Discarding it can't be undone.")
            }

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

    // MARK: - Rest Timer (inline, between the completed set and the next one)

    private var inlineRestTimer: some View {
        let startedAt = workoutVM.restTimerStartedAt ?? Date()
        let displayDate: Date = workoutVM.restTimerMode == .countUp
            ? startedAt
            : startedAt.addingTimeInterval(TimeInterval(workoutVM.restTimerTargetSeconds))
        let timedOut = workoutVM.restTimerMode == .countdown && workoutVM.restTimerDidExpire

        return VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(timedOut ? "TIME'S UP" : "REST")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1)
                            .foregroundStyle(Color.appAccent)

                        Button {
                            workoutVM.restTimerMode = workoutVM.restTimerMode == .countUp ? .countdown : .countUp
                            workoutVM.restTimerDidExpire = false
                        } label: {
                            Text(workoutVM.restTimerMode == .countUp ? "COUNT UP" : "COUNTDOWN")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.15))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    Text(displayDate, style: .timer)
                        .font(.system(size: 28, weight: .medium))
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

            if workoutVM.restTimerMode == .countdown {
                HStack(spacing: 16) {
                    Button {
                        workoutVM.restTimerTargetSeconds = max(15, workoutVM.restTimerTargetSeconds - 15)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Text("Target: \(workoutVM.restTimerTargetSeconds)s")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appCardMaroonLight)

                    Button {
                        workoutVM.restTimerTargetSeconds += 15
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appCardMaroon)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sensoryFeedback(.impact, trigger: workoutVM.restTimerDidExpire) { _, isExpired in isExpired }
        .transition(.scale(scale: 0.95).combined(with: .opacity))
    }
}
