import SwiftUI
import FirebaseFirestore

struct HistoryView: View {
    @Environment(WorkoutViewModel.self) private var workoutVM
    @Environment(\.selectedTab) private var selectedTab
    @State private var workouts: [WorkoutSession] = []
    @State private var isLoading = false
    @State private var expandedId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isLoading && workouts.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { _ in sessionCardPlaceholder }
                        }
                        .padding(20)
                    }
                    .redacted(reason: .placeholder)
                } else if workouts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.appMuted)
                        Text("No workouts yet")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.appMuted)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(workouts) { session in
                                sessionCard(session)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadWorkouts()
            }
            .refreshable {
                await loadWorkouts()
            }
        }
    }

    private func loadWorkouts() async {
        // Cache-first paint: shows last-known data instantly instead of blocking on
        // the server round trip, which can be slow on a cold Firestore connection.
        if let cached = try? await FirestoreService.shared.fetchWorkouts(source: .cache),
           !cached.isEmpty {
            workouts = cached
        }
        isLoading = workouts.isEmpty
        do {
            workouts = try await FirestoreService.shared.fetchWorkouts(source: .server)
        } catch {}
        isLoading = false
    }

    private var sessionCardPlaceholder: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.appPrimary)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Gym Name")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appText)
                Text("2 days ago · 45 min")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMuted)
            }

            Spacer()

            Text("5 ex")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.appMuted)
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sessionCard(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedId = expandedId == session.id ? nil : session.id
                }
            } label: {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.appPrimary)
                        .frame(width: 4, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(sessionTitle(session))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.appText)

                        HStack(spacing: 4) {
                            Text(formatDate(session.startedAt))
                            if let duration = sessionDuration(session) {
                                Text("·")
                                Text(duration)
                            }
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                    }

                    Spacer()

                    Text("\(session.exercises.count) ex")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appMuted)

                    Image(systemName: expandedId == session.id ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                }
                .padding(16)
            }

            if expandedId == session.id {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(session.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.exerciseName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.appText)

                            ForEach(exercise.sets) { set in
                                HStack(spacing: 8) {
                                    Text("Set \(set.setNumber)")
                                        .frame(width: 44, alignment: .leading)
                                        .foregroundStyle(Color.appMuted)
                                    Text("\(String(format: "%.1f", set.weight)) lbs")
                                        .foregroundStyle(Color.appText)
                                    Text("×")
                                        .foregroundStyle(Color.appMuted)
                                    Text("\(set.reps) reps")
                                        .foregroundStyle(Color.appText)
                                }
                                .font(.system(size: 13))
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        workoutVM.repeatWorkout(from: session)
                        selectedTab.wrappedValue = .workout
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("Repeat workout")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.appPrimary.opacity(0.15))
                        .foregroundStyle(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sessionTitle(_ session: WorkoutSession) -> String {
        if let gymName = session.gymName {
            return gymName
        }
        let exerciseNames = session.exercises.prefix(2).map(\.exerciseName)
        return exerciseNames.isEmpty ? "Workout" : exerciseNames.joined(separator: ", ")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func sessionDuration(_ session: WorkoutSession) -> String? {
        guard let end = session.endedAt else { return nil }
        let minutes = Int(end.timeIntervalSince(session.startedAt) / 60)
        return "\(minutes) min"
    }
}
