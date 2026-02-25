//
//  ShelterService.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 31/1/26.
//

import Foundation

final class ShelterService {
    func fetchActiveShelters() async throws -> [ShelterDTO] {
        try await SupabaseManager.shared.client
            .from("shelters")
            .select()
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
