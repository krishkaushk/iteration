import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(WorkoutViewModel.self) private var workoutVM
    @Environment(\.selectedTab) private var selectedTab
    @Environment(\.activeBannerHeight) private var activeBannerHeight

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                sessionCard.padding(.top, 16)
                statsRow.padding(.top, 18)
                monthlyGoal.padding(.top, 18)
                weekActivity.padding(.top, 18)
                recentSection.padding(.top, 22)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .redacted(reason: workoutVM.isLoadingHomeData ? .placeholder : [])
        }
        .background(Color.appBackground)
        .task { await workoutVM.loadHomeData() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dateString)
                .font(.system(size: 12, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(Color.appPrimary)

            Text("Hey, \(firstName)")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(Color.appText)
        }
        // Explicit measured banner height, not `.safeAreaInset`'s own reservation
        // (confirmed unreliable on-device for this dynamically-appearing banner) —
        // plus a small fixed buffer so it never sits flush against the banner.
        .padding(.top, 16 + activeBannerHeight)
    }

    // MARK: - Session Card

    private var sessionCard: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardMaroon)

            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 140, height: 140)
                .offset(x: 220, y: -60)

            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 100, height: 100)
                .offset(x: 200, y: 50)

            VStack(alignment: .leading, spacing: 0) {
                Text("TODAY'S SESSION")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.8)
                    .foregroundStyle(Color.appCardMaroonLight)
                    .padding(.bottom, 4)

                Text(lastSessionTitle)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.bottom, 2)
                    .lineLimit(1)

                Text(lastSessionDetail)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appCardMaroonLight)
                    .padding(.bottom, 16)

                Button {
                    selectedTab.wrappedValue = .workout
                } label: {
                    HStack(spacing: 6) {
                        Text("Start workout")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("STREAK")
                    .font(.system(size: 11))
                    .tracking(0.6)
                    .foregroundStyle(Color.appMuted)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(workoutVM.workoutStreak)")
                        .font(.system(size: 38, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color.appText)
                    Text("days")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appAccent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading) {
                Text("PR'S THIS MO.")
                    .font(.system(size: 11))
                    .tracking(0.6)
                    .foregroundStyle(Color.appMuted)

                Spacer()

                Text("\(workoutVM.prsThisMonth)")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.appAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Monthly Goal

    private var monthlyGoal: some View {
        let goal = authViewModel.monthlyGoal
        let done = workoutVM.workoutsThisMonth
        let progress = min(Double(done) / Double(goal), 1.0)

        return VStack(spacing: 8) {
            HStack {
                Text("MONTHLY GOAL")
                    .font(.system(size: 11))
                    .tracking(0.6)
                    .foregroundStyle(Color.appMuted)

                Spacer()

                Text("\(done) / \(goal) sessions")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.appAccent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "222222"))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appAccent)
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Week Activity

    private var weekActivity: some View {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        let mask = workoutVM.workoutMaskThisWeek
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let todayIndex = (weekday + 5) % 7

        return VStack(spacing: 4) {
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { index in
                    weekBlock(
                        index: index,
                        hasWorkout: index < mask.count && mask[index],
                        isToday: index == todayIndex,
                        isPast: index < todayIndex
                    )
                }
            }

            HStack(spacing: 5) {
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appMuted)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func weekBlock(index: Int, hasWorkout: Bool, isToday: Bool, isPast: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(blockFill(hasWorkout: hasWorkout, isToday: isToday, isPast: isPast))

            if isToday && !hasWorkout {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(hex: "3A3A3A"), style: StrokeStyle(lineWidth: 1, dash: [4]))
            }

            if hasWorkout && (isPast || isToday) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
    }

    private func blockFill(hasWorkout: Bool, isToday: Bool, isPast: Bool) -> Color {
        if hasWorkout && (isPast || isToday) { return Color.appPrimary.opacity(0.2) }
        if !isPast && !isToday { return Color(hex: "1A1A1A") }
        return Color(hex: "222222")
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.appText)

                Spacer()

                Button {
                    selectedTab.wrappedValue = .history
                } label: {
                    Text("See all")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .padding(.bottom, 8)

            if workoutVM.recentWorkouts.isEmpty {
                Text("No workouts yet")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appMuted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(workoutVM.recentWorkouts.prefix(3)) { session in
                        recentRow(session)
                    }
                }
            }
        }
    }

    private func recentRow(_ session: WorkoutSession) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.appPrimary)
                .frame(width: 4, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(sessionTitle(session))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.appText)

                Text(relativeDate(session.startedAt))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appMuted)
            }

            Spacer()

            Text("\(session.exercises.count) ex")
                .font(.system(size: 13))
                .foregroundStyle(Color.appMuted)
        }
        .padding(12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private var firstName: String {
        authViewModel.user?.email?
            .components(separatedBy: "@").first?
            .components(separatedBy: ".").first ?? "there"
    }

    private var lastSessionTitle: String {
        guard let last = workoutVM.recentWorkouts.first else { return "First session!" }
        return last.gymName ?? last.exercises.prefix(2).map(\.exerciseName).joined(separator: " + ")
    }

    private var lastSessionDetail: String {
        guard let last = workoutVM.recentWorkouts.first else { return "No workouts logged yet" }
        let exCount = last.exercises.count
        let setCount = last.exercises.flatMap(\.sets).count
        return "\(exCount) exercises · \(setCount) sets"
    }

    private func sessionTitle(_ session: WorkoutSession) -> String {
        if let gym = session.gymName { return gym }
        return session.exercises.prefix(2).map(\.exerciseName).joined(separator: ", ")
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: Date()).uppercased()
    }
}

#Preview {
    HomeView()
}
