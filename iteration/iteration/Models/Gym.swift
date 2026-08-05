import Foundation
import FirebaseFirestore

struct Gym: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String
    var location: String
    var createdAt: Date
}
