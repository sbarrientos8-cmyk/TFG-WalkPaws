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
    let description: String
    let imageUrl: String?
    let createdAt: Date?

    let titleEn: String?
    let descriptionEn: String?

    let authorType: String
    let authorName: String
    let authorAvatarUrl: String?

    init(dto: NewsRowDTO) {
        self.id = dto.id
        self.title = dto.title
        self.description = dto.description
        self.imageUrl = dto.image_url

        self.titleEn = dto.title_en
        self.descriptionEn = dto.description_en

        self.authorType = dto.author_type
        self.authorName = dto.shelter_name ?? dto.profile_name ?? "Desconocido"
        self.authorAvatarUrl = dto.avatar_url ?? dto.shelter_photo_url

        self.createdAt = NewsModel.parseSupabaseDate(dto.created_at)
    }

    var displayTitle: String {
        if AppLanguage.current == .en,
           let value = titleEn?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        return title
    }

    var displayDescription: String {
        if AppLanguage.current == .en,
           let value = descriptionEn?.trimmingCharacters(in: .whitespacesAndNewlines),
           !value.isEmpty {
            return value
        }
        return description
    }

    private static func parseSupabaseDate(_ iso: String) -> Date? {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: iso) { return d }

        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        if let d = f2.date(from: iso) { return d }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)

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
struct NewsInsert: Encodable
{
    let title: String
    let description: String
    let image_url: String?
    let author_type: String
    let profile_id: UUID?
    let shelter_id: UUID?
}
