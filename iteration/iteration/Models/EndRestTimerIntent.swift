import AppIntents
import ActivityKit

struct EndRestTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End Rest Timer"

    func perform() async throws -> some IntentResult {
        for activity in Activity<WorkoutActivityAttributes>.activities {
            var state = activity.content.state
            state.isResting = false
            state.restStartedAt = nil
            state.restDidExpire = false
            await activity.update(.init(state: state, staleDate: nil))
        }
        NotificationCenter.default.post(name: .restTimerDismissedFromLiveActivity, object: nil)
        return .result()
    }
}

extension Notification.Name {
    static let restTimerDismissedFromLiveActivity = Notification.Name("restTimerDismissedFromLiveActivity")
}
