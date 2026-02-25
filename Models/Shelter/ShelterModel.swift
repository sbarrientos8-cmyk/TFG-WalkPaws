//
//  ShelterModel.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 31/1/26.
//

import Foundation
import CoreLocation

struct ShelterModel
{
    let id: UUID
    let name: String
    let description: String
    let city: String
    let postalCode: String
    let photoURL: String?
    
    let phone: String?
    let email: String?

    let latitude: Double?
    let longitude: Double?
    let formattedAddress: String?

    var locationText: String {
        "\(city) · \(postalCode)"
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(dto: ShelterDTO)
    {
        self.id = dto.id
        self.name = dto.name
        self.description = dto.description ?? ""
        self.city = dto.city ?? ""
        self.postalCode = dto.postal_code ?? ""
        self.photoURL = dto.photo_url
        
        self.phone = dto.phone
        self.email = dto.contact_email

        self.latitude = dto.latitude
        self.longitude = dto.longitude
        self.formattedAddress = dto.formatted_address
    }
}

struct ShelterContactInfo
{
    let name: String
    let email: String
    let photoURL: String?
}
