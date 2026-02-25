//
//  ProfileService.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 12/2/26.
//

import Foundation

final class ProfileService
{

    func fetchMyProfile(email: String) async throws -> ProfileDTO? {
        let rows: [ProfileDTO] = try await SupabaseManager.shared.client
            .from("profiles")
            .select("name, email, avatar_url")
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        print("EMAIL AUTH:", email)
        print("ROWS:", rows)

        return rows.first
    }
}
