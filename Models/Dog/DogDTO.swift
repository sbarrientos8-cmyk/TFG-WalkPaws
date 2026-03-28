//
//  DogDTO.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 19/2/26.
//

struct DogRowDTO: Decodable {
    let id: String
    let shelter_id: String
    let name: String
    let breed: String?
    let age_years: Int?
    let description: String?
    let photo_url: String?
    let shelter_city: String?
    let shelter_name: String?
    let is_disabled: Bool
    let isWalkable: Bool
    let sex: String?
    let story: String?

    let donation_goal_eur: Double?
    let donation_raised_eur: Double?
    let disability_diagnosis: String?

    let breed_en: String?
    let description_en: String?
    let story_en: String?
    let disability_diagnosis_en: String?

    enum CodingKeys: String, CodingKey {
        case id, shelter_id, name, breed, age_years, description, photo_url
        case shelter_city, shelter_name, is_disabled, sex, story
        case donation_goal_eur, donation_raised_eur, disability_diagnosis
        case breed_en, description_en, story_en, disability_diagnosis_en
        case isWalkable = "is_walkable"
    }
}
