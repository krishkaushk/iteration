import Foundation
import FirebaseFirestore

struct Exercise: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String
    var category: String
    var equipmentType: String
    var isCustom: Bool

    enum Category: String, CaseIterable {
        case chest, back, legs, shoulders, arms, core
    }

    enum EquipmentType: String, CaseIterable {
        case barbell, dumbbell, machine, cable, bodyweight
    }
}
