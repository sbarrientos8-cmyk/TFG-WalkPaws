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

    let donationGoalEur: Double?
    let donationRaisedEur: Double
    let disability_diagnosis: String?

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

        self.donationGoalEur = dto.donation_goal_eur
        self.donationRaisedEur = dto.donation_raised_eur ?? 0
        self.disability_diagnosis = dto.disability_diagnosis
    }

    var sexDisplayText: String {
        switch sex?.lowercased() {
        case "male": return "Macho"
        case "female": return "Hembra"
        case "unknown": return "Desconocido"
        default: return "No especificado"
        }
    }
}
