//
//  ProfileDTO.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 12/2/26.
//

import Foundation

struct ProfileDTO: Decodable
{
    let name: String?
    let email: String?
    let avatar_url: String?
}
