//
//  DonateModel.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 4/3/26.
//

import Foundation

struct DonateParams: Encodable {
    let p_dog_id: String   // lo mandamos como string
    let p_points: Int
}

struct DonateMoneyParams: Encodable {
    let p_dog_id: String
    let p_eur_amount: Double
    let p_card_last4: String
}
