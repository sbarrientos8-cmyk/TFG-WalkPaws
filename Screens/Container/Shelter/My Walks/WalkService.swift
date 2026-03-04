//
//  WalkService.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 1/3/26.
//

import Foundation

final class WalksService {
    func fetchMyWalks(profileId: UUID) async throws -> [WalkListRowDTO] {
        try await SupabaseManager.shared.client
            .from("walks_with_details")
            .select("*")
            .eq("profile_id", value: profileId.uuidString) // si profile_id está en la view; si no, añádelo a la view
            .order("started_at", ascending: false)
            .execute()
            .value
    }
}
