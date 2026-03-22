//
//  ConnectApi.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 19/2/26.
//

import Foundation

func fetchDogs(completion: @escaping ([DogModel]) -> Void) {
    let url = URL(string: "https://nbcxqbooivodgzjtmqgf.supabase.co/rest/v1/dogs_with_shelter?select=*")!

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A", forHTTPHeaderField: "apikey")
    request.setValue("Bearer sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept") // importante
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { data, response, error in

        if let error = error {
            print("❌ fetchDogs error:", error)
            completion([])
            return
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("🌐 fetchDogs status:", status)

        guard let data = data else {
            print("❌ fetchDogs: no data")
            completion([])
            return
        }

        // Si NO es 200, imprime el body (aquí verás el error real de Supabase)
        if status != 200 {
            print("❌ fetchDogs server error body:", String(data: data, encoding: .utf8) ?? "nil")
            completion([])
            return
        }

        do {
            let dtos = try JSONDecoder().decode([DogRowDTO].self, from: data)
            completion(dtos.map { DogModel(dto: $0) })
        } catch {
            print("❌ decode error:", error)
            print("RAW JSON:", String(data: data, encoding: .utf8) ?? "nil")
            completion([])
        }

    }.resume()
    
}

func fetchDogsByShelter(shelterId: String, completion: @escaping ([DogModel]) -> Void) {

    let urlString = "https://nbcxqbooivodgzjtmqgf.supabase.co/rest/v1/dogs_with_shelter?select=*&shelter_id=eq.\(shelterId)"
    guard let url = URL(string: urlString) else {
        completion([])
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A", forHTTPHeaderField: "apikey")
    request.setValue("Bearer sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { data, response, error in

        if let error = error {
            print("❌ fetchDogsByShelter error:", error)
            completion([])
            return
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("🌐 fetchDogsByShelter status:", status)

        guard let data = data else {
            completion([])
            return
        }
        
        print("RAW JSON:", String(data: data, encoding: .utf8) ?? "nil")

        if status != 200 {
            print("❌ server error body:", String(data: data, encoding: .utf8) ?? "nil")
            completion([])
            return
        }

        do {
            let dtos = try JSONDecoder().decode([DogRowDTO].self, from: data)
            completion(dtos.map { DogModel(dto: $0) })
        } catch {
            print("❌ decode error:", error)
            print("RAW JSON:", String(data: data, encoding: .utf8) ?? "nil")
            completion([])
        }

    }.resume()
}

func fetchNews(completion: @escaping ([NewsModel]) -> Void) {

    let urlString = "https://nbcxqbooivodgzjtmqgf.supabase.co/rest/v1/news_with_author?select=*&order=created_at.desc"
    guard let url = URL(string: urlString) else {
        completion([])
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A", forHTTPHeaderField: "apikey")
    request.setValue("Bearer sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(with: request) { data, response, error in

        if let error = error {
            print("❌ fetchNews error:", error)
            completion([])
            return
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("🌐 fetchNews status:", status)

        guard let data = data else {
            print("❌ fetchNews: no data")
            completion([])
            return
        }

        print("RAW JSON:", String(data: data, encoding: .utf8) ?? "nil")

        if status != 200 {
            print("❌ fetchNews server error body:", String(data: data, encoding: .utf8) ?? "nil")
            completion([])
            return
        }

        do {
            let dtos = try JSONDecoder().decode([NewsRowDTO].self, from: data)
            completion(dtos.map { NewsModel(dto: $0) })
        } catch {
            print("❌ fetchNews decode error:", error)
            completion([])
        }

    }.resume()
}


func fetchMyPoints() async throws -> Int {
    let session = try await SupabaseManager.shared.client.auth.session
    let userId = session.user.id

    struct PointsDTO: Decodable { let points: Int }

    let dto: PointsDTO = try await SupabaseManager.shared.client
        .from("profiles")
        .select("points")
        .eq("id", value: userId.uuidString)
        .single()
        .execute()
        .value

    return dto.points
}

func fetchMyProfile(email: String) async throws -> ProfileDTO? {
        let rows: [ProfileDTO] = try await SupabaseManager.shared.client
            .from("profiles")
            .select("id, name, email, avatar_url, points")  // ✅ AÑADE points
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value

        return rows.first
    }
