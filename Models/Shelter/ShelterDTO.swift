//
//  ShelterDTO.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 31/1/26.
//

import Foundation

struct ShelterDTO: Decodable
{
    let id: UUID
    let name: String
    let description: String?
    let photo_url: String?
    let country: String?
    let city: String?
    let postal_code: String?

    let phone: String?
    let contact_email: String?
    
    let latitude: Double?
    let longitude: Double?
    let formatted_address: String?
}
