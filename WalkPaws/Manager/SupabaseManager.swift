//
//  SupabaseManager.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 28/1/26.
//

import Foundation
import Supabase

final class SupabaseManager
{
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init()
    {
        let url = URL(string: "https://nbcxqbooivodgzjtmqgf.supabase.co")!
        let key = "sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A"

        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }
}
