import Foundation
import SwiftData

@Model
class BirdStat {
    var speciesCode: String
    var commonName: String
    var scientificName: String
    var correctCount: Int
    var incorrectCount: Int
    var lastAttemptedAt: Date

    init(speciesCode: String, commonName: String, scientificName: String) {
        self.speciesCode = speciesCode
        self.commonName = commonName
        self.scientificName = scientificName
        self.correctCount = 0
        self.incorrectCount = 0
        self.lastAttemptedAt = Date()
    }

    var totalAttempts: Int { correctCount + incorrectCount }

    var correctRate: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctCount) / Double(totalAttempts)
    }
}
