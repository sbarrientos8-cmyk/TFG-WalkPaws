//
//  DogDTO.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 19/2/26.
//

struct DogRowDTO: Decodable
{
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
    let sex: String?
    let story: String?

    let donation_goal_eur: Double?
    let donation_raised_eur: Double?
    let disability_diagnosis: String?
}
