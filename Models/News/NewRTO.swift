//
//  NewRTO.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 23/2/26.
//

import Foundation

struct NewsRowDTO: Decodable {

    let id: String
    let title: String
    let short_text: String
    let description: String
    let image_url: String?
    let author_type: String
    let profile_id: String?
    let shelter_id: String?
    let created_at: String

    let profile_name: String?
    let avatar_url: String?
    let role: String?
    let shelter_name: String?
}
