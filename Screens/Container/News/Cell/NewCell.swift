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

    @IBOutlet weak var viewLine: UIView!
    @IBOutlet weak var buttonTrash: UIButton!
    
    private var lineTrailingToImageConstraint: NSLayoutConstraint?
    private var lineTrailingToBackgroundConstraint: NSLayoutConstraint?
    private var shortTrailingToImageConstraint: NSLayoutConstraint?
    private var shortTrailingToBackgroundConstraint: NSLayoutConstraint?
    
    var onTrashTapped: (() -> Void)?

    
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
        buttonTrash.isHidden = true
        onTrashTapped = nil
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
        if let imageUrl = news.imageUrl,
           !imageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: imageUrl) {

            imageNews.isHidden = false
            imageNews.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "photo"),
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            )

        } else {
            imageNews.sd_cancelCurrentImageLoad()
            imageNews.image = nil
            imageNews.isHidden = true
            
            setLineTrailingToBackground()
            setShortTrailingToBackground()
        }
    }
    
    private func findShortTrailingToImageConstraint() -> NSLayoutConstraint? {
        let all = contentView.constraints + viewBackground.constraints + constraints

        return all.first(where: { c in
            guard let first = c.firstItem as? UIView,
                  let second = c.secondItem as? UIView else { return false }

            return first == labelTextShort &&
                   c.firstAttribute == .trailing &&
                   second == imageNews &&
                   c.secondAttribute == .leading
        })
    }

    private func setShortTrailingToBackground() {
        if shortTrailingToImageConstraint == nil {
            shortTrailingToImageConstraint = findShortTrailingToImageConstraint()
        }
        shortTrailingToImageConstraint?.isActive = false

        if shortTrailingToBackgroundConstraint == nil {
            shortTrailingToBackgroundConstraint = labelTextShort.trailingAnchor.constraint(
                equalTo: viewBackground.trailingAnchor,
                constant: -10
            )
        }
        shortTrailingToBackgroundConstraint?.isActive = true
    }
    
    private func findTrailingToImageConstraint() -> NSLayoutConstraint? {
        // Busca una constraint donde:
        // firstItem = viewLine, firstAttr = trailing
        // secondItem = imageNews, secondAttr = leading
        let all = contentView.constraints + viewBackground.constraints + constraints

        return all.first(where: { c in
            guard let first = c.firstItem as? UIView,
                  let second = c.secondItem as? UIView else { return false }

            return first == viewLine &&
                   c.firstAttribute == .trailing &&
                   second == imageNews &&
                   c.secondAttribute == .leading
        })
    }

    private func setLineTrailingToBackground() {
        // 1) Apaga la constraint vieja (trailing a la imagen)
        if lineTrailingToImageConstraint == nil {
            lineTrailingToImageConstraint = findTrailingToImageConstraint()
        }
        lineTrailingToImageConstraint?.isActive = false

        // 2) Crea/activa trailing a background (-10)
        if lineTrailingToBackgroundConstraint == nil {
            lineTrailingToBackgroundConstraint = viewLine.trailingAnchor.constraint(
                equalTo: viewBackground.trailingAnchor,
                constant: -10
            )
        }
        lineTrailingToBackgroundConstraint?.isActive = true

        setNeedsLayout()
        layoutIfNeeded()
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
    
    func setTrashVisible(_ visible: Bool) {
        buttonTrash.isHidden = !visible
    }
    
    @IBAction func trashClicked(_ sender: Any) {
        onTrashTapped?()
    }
}
