import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct WorkoutWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenWorkoutView(context: context)
                .activityBackgroundTint(Color.appBackground)
                .activitySystemActionForegroundColor(Color.appText)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.exerciseName)
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(Color.appText)
                            .lineLimit(1)
                        if let weight = context.state.lastWeight, let reps = context.state.lastReps {
                            Text("Set \(context.state.setNumber) · \(Int(weight)) × \(reps)")
                                .font(.caption2)
                                .foregroundStyle(Color.appMuted)
                        } else {
                            Text("Set \(context.state.setNumber)")
                                .font(.caption2)
                                .foregroundStyle(Color.appMuted)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isResting {
                        restTimerText(context: context, font: .title2)
                            .foregroundStyle(Color.appAccent)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isResting {
                        Button(intent: EndRestTimerIntent()) {
                            Text("DONE")
                                .font(.caption).fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .tint(Color.appPrimary)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isResting ? "timer" : "figure.strengthtraining.traditional")
                    .foregroundStyle(Color.appAccent)
            } compactTrailing: {
                if context.state.isResting {
                    restTimerText(context: context, font: .caption2)
                        .foregroundStyle(Color.appAccent)
                } else {
                    Text("\(context.state.setNumber)")
                        .font(.caption2)
                        .foregroundStyle(Color.appAccent)
                }
            } minimal: {
                Image(systemName: context.state.isResting ? "timer" : "figure.strengthtraining.traditional")
                    .foregroundStyle(Color.appAccent)
            }
        }
    }
}

// Mirrors WorkoutView.inlineRestTimer's displayDate trick: a future date makes
// Text(_:style:) count down automatically; a past date counts up.
private func displayDate(for context: ActivityViewContext<WorkoutActivityAttributes>) -> Date {
    guard let restStartedAt = context.state.restStartedAt else { return Date() }
    return context.state.restMode == .countUp
        ? restStartedAt
        : restStartedAt.addingTimeInterval(TimeInterval(context.state.restTargetSeconds))
}

private func restTimerText(context: ActivityViewContext<WorkoutActivityAttributes>, font: Font) -> some View {
    Text(displayDate(for: context), style: .timer)
        .font(font)
        .monospacedDigit()
}

private struct LockScreenWorkoutView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.isResting ? (context.state.restDidExpire ? "TIME'S UP" : "REST") : "WORKOUT")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(Color.appAccent)
                Text(context.state.exerciseName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appText)
                    .lineLimit(1)
                if let weight = context.state.lastWeight, let reps = context.state.lastReps {
                    Text("Set \(context.state.setNumber) · \(Int(weight)) lbs × \(reps)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                } else {
                    Text("Set \(context.state.setNumber)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appMuted)
                }
            }
            Spacer()
            if context.state.isResting {
                restTimerText(context: context, font: .system(size: 28, weight: .medium))
                    .foregroundStyle(Color.appText)
                Button(intent: EndRestTimerIntent()) {
                    Text("DONE")
                        .font(.system(size: 12, weight: .semibold))
                }
                .tint(Color.appPrimary)
            }
        }
        .padding(16)
    }
}
