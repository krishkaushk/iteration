import Foundation
import FirebaseFirestore

struct UserSettings: Codable, Hashable {
    var monthlyGoal: Int = 20
}
