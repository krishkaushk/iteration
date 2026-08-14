import SwiftUI

struct MainTabView: View {
    @Environment(\.selectedTab) private var selectedTab
    @Environment(WorkoutViewModel.self) private var workoutVM
    // Driven explicitly via `updateBannerVisibility()` rather than computed inline in
    // the `.safeAreaInset` closure below — that closure could lag a render behind a
    // fresh `workoutVM.isActive` flip (e.g. starting a workout while already on the
    // Workout tab showed the banner until switching tabs away and back forced a
    // refresh). `.onChange` reliably fires on every actual transition instead.
    @State private var showBanner = false
    // Measured directly from the banner's own rendered size — `.safeAreaInset` is
    // supposed to push sibling scroll content down by exactly this much on its own,
    // but with dynamically-appearing (and animated) inset content that reservation
    // doesn't reliably happen — confirmed on-device (Home's greeting rendered flush
    // against the banner, its date label hidden underneath). Screens read this value
    // directly and add it as explicit padding instead of trusting the inset alone.
    @State private var bannerHeight: CGFloat = 0

    var body: some View {
        TabView(selection: selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            WorkoutView()
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
                .tag(AppTab.workout)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(AppTab.history)

            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.progress)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(AppTab.profile)
        }
        .tint(Color.appPrimary)
        .preferredColorScheme(.dark)
        .environment(\.activeBannerHeight, showBanner ? bannerHeight : 0)
        .safeAreaInset(edge: .top) {
            if showBanner {
                activeWorkoutBanner
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { bannerHeight = geo.size.height }
                                .onChange(of: geo.size.height) { _, newValue in bannerHeight = newValue }
                        }
                    )
            }
        }
        .onAppear { updateBannerVisibility() }
        .onChange(of: workoutVM.isActive) { _, _ in updateBannerVisibility() }
        .onChange(of: selectedTab.wrappedValue) { _, _ in updateBannerVisibility() }
    }

    private func updateBannerVisibility() {
        let shouldShow = workoutVM.isActive && selectedTab.wrappedValue != .workout
        guard shouldShow != showBanner else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            showBanner = shouldShow
        }
    }

    private var activeWorkoutBanner: some View {
        Button {
            selectedTab.wrappedValue = .workout
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 1) {
                    Text(workoutVM.currentSession?.gymName ?? "Workout in progress")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    if let startedAt = workoutVM.currentSession?.startedAt {
                        Text(startedAt, style: .timer)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appCardMaroonLight)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appCardMaroonLight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appCardMaroon)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 8)
            // A visible shadow reads as a distinct floating layer above the tab's own
            // content — actual non-overlap is enforced explicitly via
            // `activeBannerHeight` (see below), not assumed from `.safeAreaInset` alone.
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// Real measured height of the active-workout banner (0 when not showing). Screens
// whose top content needs to visibly clear the banner should add this as explicit
// top padding rather than relying on `.safeAreaInset` to push them down on its own —
// confirmed on-device that reservation doesn't reliably happen for this banner, since
// its appearance is both conditional (`showBanner`) and animated.
private struct ActiveBannerHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var activeBannerHeight: CGFloat {
        get { self[ActiveBannerHeightKey.self] }
        set { self[ActiveBannerHeightKey.self] = newValue }
    }
}
