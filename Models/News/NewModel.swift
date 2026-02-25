//
//  NewModel.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 23/2/26.
//


import Foundation

struct NewsModel {
    let id: String
    let title: String
    let shortText: String
    let description: String
    let imageUrl: String?
    let createdAt: Date?

    let authorType: String
    let authorName: String
    let authorAvatarUrl: String?

    init(dto: NewsRowDTO) {
        self.id = dto.id
        self.title = dto.title
        self.shortText = dto.short_text
        self.description = dto.description
        self.imageUrl = dto.image_url

        self.authorType = dto.author_type
        self.authorName = dto.shelter_name ?? dto.profile_name ?? "Desconocido"
        self.authorAvatarUrl = dto.avatar_url

        self.createdAt = NewsModel.parseSupabaseDate(dto.created_at)
    }

    private static func parseSupabaseDate(_ iso: String) -> Date? {
        // 1) ISO8601 con fracción
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: iso) { return d }

        // 2) ISO8601 sin fracción
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        if let d = f2.date(from: iso) { return d }

        // 3) DateFormatter manual (por si viene con 5-6 decimales)
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)

        // Prueba varias precisiones de microsegundos
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSS"
        ]

        for format in formats {
            df.dateFormat = format
            if let d = df.date(from: iso) { return d }
        }

        return nil
    }
}
