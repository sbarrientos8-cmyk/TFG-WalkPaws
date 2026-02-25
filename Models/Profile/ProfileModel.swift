//
//  ProfileModel.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 12/2/26.
//

import Foundation

struct ProfileModel
{
    let name: String
    let email: String
    let avatarURL: String?

    init(dto: ProfileDTO) {
        self.name = dto.name ?? "Usuario"
        self.email = dto.email ?? ""
        self.avatarURL = dto.avatar_url
    }
}

enum ProfileRole {
    case user
    case worker
}
