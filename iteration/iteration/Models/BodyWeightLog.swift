import Foundation
import FirebaseFirestore

struct BodyWeightLog: Codable, Identifiable {
    @DocumentID var id: String?
    var date: Date
    var weightLbs: Double
    var notes: String?
}
