//
//  NewCell.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 23/2/26.
//

import UIKit
import SDWebImage

class NewCell: UITableViewCell {

    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var imageProfile: CircleImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var labelTextShort: UILabel!
    @IBOutlet weak var viewNew: UIView!
    @IBOutlet weak var imageNews: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()


        labelName.config(text: "", style: StylesLabel.title1Name)
        labelTime.config(text: "", style: StylesLabel.subtitleGray)
        labelTextShort.config(text: "", style: StylesLabel.subtitleGreen)

        imageNews.layer.cornerRadius = 5
        viewBackground.applyCardStyle()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageProfile.sd_cancelCurrentImageLoad()
        imageNews.sd_cancelCurrentImageLoad()

        imageProfile.image = UIImage(systemName: "person.circle")
        imageNews.image = nil
        imageNews.isHidden = false
    }

    func config(with news: NewsModel) {

        labelName.text = news.authorName
        labelTextShort.text = news.shortText
        labelTime.text = formattedDate(news.createdAt)

        // Imagen perfil
        if let avatarUrl = news.authorAvatarUrl, let url = URL(string: avatarUrl) {
            imageProfile.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "person.circle"),
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            )
        } else {
            imageProfile.image = UIImage(systemName: "person.circle")
        }

        // Imagen noticia
        if let imageUrl = news.imageUrl, let url = URL(string: imageUrl) {

            imageNews.isHidden = false
            imageNews.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "photo"),
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            )

        } else {
            imageNews.isHidden = true
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }

        let now = Date()
        let seconds = now.timeIntervalSince(date)
        if seconds < 0 { return "ahora" }

        let oneWeek: TimeInterval = 7 * 24 * 60 * 60
        if seconds >= oneWeek {
            let df = DateFormatter()
            df.locale = Locale(identifier: "es_ES")
            df.timeZone = .current
            df.dateFormat = "dd/MM/yyyy"
            return df.string(from: date)
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "es_ES")
            formatter.unitsStyle = .short
            return formatter.localizedString(for: date, relativeTo: now)
        }
    }
}
