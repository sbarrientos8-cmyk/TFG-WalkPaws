//
//  ProfileModel.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 12/2/26.
//

import Foundation

struct ProfileModel {
    let id: UUID?
    let name: String
    let email: String
    let avatarURL: String?

    init(dto: ProfileDTO) {
        self.id = dto.id
        self.name = dto.name ?? "Usuario"
        self.email = dto.email ?? ""
        self.avatarURL = dto.avatar_url
    }
}

enum ProfileRole {
    case user
    case worker
}


struct ProfileUpdate: Encodable
{
    let name: String?
    let email: String?
    let avatar_url: String?
}
