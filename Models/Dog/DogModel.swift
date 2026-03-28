//
//  DogModel.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 19/2/26.
//

import Foundation
import CoreLocation

struct DogModel {
    let id: String
    let name: String
    let breed: String
    let city: String
    let age: Int?
    let description: String?
    let photoURL: String?
    let shelterId: String?
    let isDisabled: Bool
    let sex: String?
    let story: String?
    let isWalkable: Bool

    let donationGoalEur: Double?
    let donationRaisedEur: Double
    let disabilityDiagnosis: String?

    let breedEn: String?
    let descriptionEn: String?
    let storyEn: String?
    let disabilityDiagnosisEn: String?

    init(dto: DogRowDTO) {
        self.id = dto.id
        self.name = dto.name
        self.breed = dto.breed ?? "Sin especificar"
        self.age = dto.age_years
        self.description = dto.description
        self.photoURL = dto.photo_url
        self.shelterId = dto.shelter_id
        self.city = dto.shelter_city ?? "Sin ciudad"
        self.isDisabled = dto.is_disabled
        self.sex = dto.sex
        self.story = dto.story
        self.isWalkable = dto.isWalkable

        self.donationGoalEur = dto.donation_goal_eur
        self.donationRaisedEur = dto.donation_raised_eur ?? 0
        self.disabilityDiagnosis = dto.disability_diagnosis

        self.breedEn = dto.breed_en
        self.descriptionEn = dto.description_en
        self.storyEn = dto.story_en
        self.disabilityDiagnosisEn = dto.disability_diagnosis_en
    }

    var displayBreed: String {
        if AppLanguage.current == .en,
           let value = breedEn?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        return breed
    }

    var displayDescription: String? {
        if AppLanguage.current == .en,
           let value = descriptionEn?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        return description
    }

    var displayStory: String? {
        if AppLanguage.current == .en,
           let value = storyEn?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        return story
    }

    var displayDisabilityDiagnosis: String? {
        if AppLanguage.current == .en,
           let value = disabilityDiagnosisEn?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        return disabilityDiagnosis
    }

    var sexDisplayText: String {
        switch sex?.lowercased() {
        case "male": return L10n.tr("male")
        case "female": return L10n.tr("female")
        case "unknown": return L10n.tr("unknown")
        default: return L10n.tr("not_specified")
        }
    }
}
