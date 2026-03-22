//
//  WalkModel.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 1/3/26.
//

import Foundation

struct WalkInsertRow: Encodable {
    let shelter_id: UUID
    let dog_id: UUID
    let profile_id: UUID

    let status: String              // "finished"
    let started_at: String          // ISO8601
    let ended_at: String?           // ISO8601

    let duration_seconds: Int
    let distance_km: Double
    let points_earned: Int

    let route_simplified: RouteSimplified?
}

struct RouteSimplified: Encodable {
    let type: String = "LineString"
    let coords: [[Double]] // [[lon, lat], ...]
}

struct WalkPointInsertRow: Encodable {
    let walk_id: UUID
    let seq: Int
    let lat: Double
    let lon: Double
}

struct WalkCreatedDTO: Decodable {
    let id: UUID
}

struct WalkRowDTO: Decodable {
    let id: UUID
    let started_at: String
    let ended_at: String?
    let duration_seconds: Int?
    let distance_km: Double
    let points_earned: Int
    let route_simplified: RouteSimplifiedDTO?
}

struct RouteSimplifiedDTO: Decodable {
    let type: String
    let coords: [[Double]]   // [[lon, lat], ...]
}

struct WalkListRowDTO: Decodable {
    let id: UUID
    let started_at: String
    let ended_at: String?
    let duration_seconds: Int?
    let distance_km: Double
    let points_earned: Int
    let route_simplified: RouteSimplifiedDTO?

    let dog_name: String
    let dog_photo_url: String?
    let shelter_name: String
    let shelter_city: String?
    let shelter_country: String?
}


final class WalkSession {

    static let shared = WalkSession()
    private init() {}

    private(set) var isActive: Bool = false
    private(set) var dogId: UUID?
    private(set) var shelterId: UUID?
    private(set) var dogName: String = ""
    private(set) var shelterName: String = ""
    private(set) var startedAt: Date?

    func start(dogId: UUID, shelterId: UUID, dogName: String, shelterName: String) {
        self.isActive = true
        self.dogId = dogId
        self.shelterId = shelterId
        self.dogName = dogName
        self.shelterName = shelterName
        self.startedAt = Date()
    }

    func end() {
        self.isActive = false
        self.dogId = nil
        self.shelterId = nil
        self.dogName = ""
        self.shelterName = ""
        self.startedAt = nil
    }
}
