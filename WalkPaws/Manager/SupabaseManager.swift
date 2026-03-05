//
//  SupabaseManager.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 28/1/26.
//

import Foundation
import Supabase
import Auth

final class SupabaseManager {
    static let shared = SupabaseManager()
    let client: SupabaseClient

    private init() {
        let url = URL(string: "https://nbcxqbooivodgzjtmqgf.supabase.co")!
        let key = "sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A"

        let options = SupabaseClientOptions(
            auth: .init(
                storage: KeychainLocalStorage(),
                emitLocalSessionAsInitialSession: true
            )
        )

        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key, options: options)
    }
}
