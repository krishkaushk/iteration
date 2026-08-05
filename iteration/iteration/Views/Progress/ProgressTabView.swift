import SwiftUI
import Charts

struct ProgressTabView: View {
    @State private var progressVM = ProgressViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if progressVM.isLoading {
                    ProgressView().tint(Color.appText)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            strengthSection
                            volumeSection
                            bodyWeightSection
                        }
                        .padding(20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task { await progressVM.load() }
        }
    }

    // MARK: - Strength

    private var strengthSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("STRENGTH", subtitle: "Max weight per session")

            if progressVM.exerciseNames.isEmpty {
                emptyState("Complete workouts to see strength progress")
            } else {
                Picker("Exercise", selection: $progressVM.selectedExerciseName) {
                    ForEach(progressVM.exerciseNames, id: \.self) { name in
                        Text(name).tag(name)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.appPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

                if progressVM.strengthPoints.count < 2 {
                    emptyState("Log \(progressVM.selectedExerciseName) at least twice to see a trend")
                } else {
                    Chart(progressVM.strengthPoints) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("lbs", point.maxWeight)
                        )
                        .foregroundStyle(Color.appPrimary)
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("lbs", point.maxWeight)
                        )
                        .foregroundStyle(Color.appPrimary)
                        .symbolSize(36)
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(Color.appMuted)
                            AxisGridLine().foregroundStyle(Color.appBorder)
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))")
                                        .foregroundStyle(Color.appMuted)
                                }
                            }
                            AxisGridLine().foregroundStyle(Color.appBorder)
                        }
                    }
                    .frame(height: 200)
                }
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Volume

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("WEEKLY VOLUME", subtitle: "Total weight × reps per week")

            if progressVM.weeklyVolumeBars.isEmpty {
                emptyState("Complete workouts to see weekly volume")
            } else {
                Chart(progressVM.weeklyVolumeBars) { bar in
                    BarMark(
                        x: .value("Week", bar.weekStart, unit: .weekOfYear),
                        y: .value("Volume", bar.totalVolume)
                    )
                    .foregroundStyle(Color.appPrimary.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.appMuted)
                        AxisGridLine().foregroundStyle(Color.appBorder)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatVolume(v))
                                    .foregroundStyle(Color.appMuted)
                            }
                        }
                        AxisGridLine().foregroundStyle(Color.appBorder)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Body Weight

    private var bodyWeightSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("BODY WEIGHT", subtitle: "Logged in lbs")

            HStack(spacing: 10) {
                NumericField(placeholder: "Today's weight", value: $progressVM.newBodyWeight)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.appBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(maxWidth: .infinity)

                Button {
                    Task { await progressVM.logBodyWeight() }
                } label: {
                    Text("Log")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.appPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(progressVM.newBodyWeight <= 0)
                .opacity(progressVM.newBodyWeight > 0 ? 1 : 0.5)
            }

            if progressVM.bodyWeightChartData.count < 2 {
                emptyState("Log your weight at least twice to see a trend")
            } else {
                Chart(progressVM.bodyWeightChartData, id: \.date) { log in
                    LineMark(
                        x: .value("Date", log.date, unit: .day),
                        y: .value("lbs", log.weightLbs)
                    )
                    .foregroundStyle(Color.appAccent)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", log.date, unit: .day),
                        y: .value("lbs", log.weightLbs)
                    )
                    .foregroundStyle(Color.appAccent)
                    .symbolSize(36)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.appMuted)
                        AxisGridLine().foregroundStyle(Color.appBorder)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .foregroundStyle(Color.appMuted)
                            }
                        }
                        AxisGridLine().foregroundStyle(Color.appBorder)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1)
                .foregroundStyle(Color.appMuted)
            Text(subtitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.appText)
        }
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13))
            .foregroundStyle(Color.appMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.0fk", v / 1000)
        }
        return String(format: "%.0f", v)
    }
}
