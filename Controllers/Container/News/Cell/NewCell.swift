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

    private let profileLoadingIndicator = UIActivityIndicatorView(style: .medium)
    private let newsLoadingIndicator = UIActivityIndicatorView(style: .medium)

    var onTrashTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        labelName.config(text: "", style: StylesLabel.title1Name)
        labelTime.config(text: "", style: StylesLabel.subtitleGray)
        labelTextShort.config(text: "", style: StylesLabel.subtitleGreen)

        imageNews.layer.cornerRadius = 5
        imageNews.clipsToBounds = true

        viewBackground.applyCardStyle()

        setupLoadingIndicators()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageProfile.sd_cancelCurrentImageLoad()
        imageNews.sd_cancelCurrentImageLoad()

        imageProfile.image = nil
        imageNews.image = nil

        profileLoadingIndicator.stopAnimating()
        newsLoadingIndicator.stopAnimating()

        imageNews.isHidden = false
        buttonTrash.isHidden = true
        onTrashTapped = nil

        shortTrailingToBackgroundConstraint?.isActive = false
        lineTrailingToBackgroundConstraint?.isActive = false
        shortTrailingToImageConstraint?.isActive = true
        lineTrailingToImageConstraint?.isActive = true
    }

    private func setupLoadingIndicators() {
        profileLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        profileLoadingIndicator.hidesWhenStopped = true
        imageProfile.addSubview(profileLoadingIndicator)

        newsLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        newsLoadingIndicator.hidesWhenStopped = true
        imageNews.addSubview(newsLoadingIndicator)

        NSLayoutConstraint.activate([
            profileLoadingIndicator.centerXAnchor.constraint(equalTo: imageProfile.centerXAnchor),
            profileLoadingIndicator.centerYAnchor.constraint(equalTo: imageProfile.centerYAnchor),

            newsLoadingIndicator.centerXAnchor.constraint(equalTo: imageNews.centerXAnchor),
            newsLoadingIndicator.centerYAnchor.constraint(equalTo: imageNews.centerYAnchor)
        ])
    }

    func config(with news: NewsModel) {
        labelName.text = news.authorName
        labelTextShort.text = news.displayTitle
        labelTime.text = formattedDate(news.createdAt)

        if let avatarUrl = news.authorAvatarUrl,
           let url = URL(string: avatarUrl) {

            imageProfile.image = nil
            profileLoadingIndicator.startAnimating()

            imageProfile.sd_setImage(
                with: url,
                placeholderImage: nil,
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            ) { [weak self] _, _, _, _ in
                self?.profileLoadingIndicator.stopAnimating()
            }

        } else {
            imageProfile.image = nil
            profileLoadingIndicator.stopAnimating()
        }

        if let imageUrl = news.imageUrl,
           !imageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: imageUrl) {

            imageNews.isHidden = false
            imageNews.image = nil
            newsLoadingIndicator.startAnimating()

            shortTrailingToBackgroundConstraint?.isActive = false
            lineTrailingToBackgroundConstraint?.isActive = false

            if shortTrailingToImageConstraint == nil {
                shortTrailingToImageConstraint = findShortTrailingToImageConstraint()
            }
            if lineTrailingToImageConstraint == nil {
                lineTrailingToImageConstraint = findTrailingToImageConstraint()
            }

            shortTrailingToImageConstraint?.isActive = true
            lineTrailingToImageConstraint?.isActive = true

            imageNews.sd_setImage(
                with: url,
                placeholderImage: nil,
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            ) { [weak self] _, _, _, _ in
                self?.newsLoadingIndicator.stopAnimating()
            }

        } else {
            imageNews.sd_cancelCurrentImageLoad()
            imageNews.image = nil
            imageNews.isHidden = true
            newsLoadingIndicator.stopAnimating()

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
        if lineTrailingToImageConstraint == nil {
            lineTrailingToImageConstraint = findTrailingToImageConstraint()
        }
        lineTrailingToImageConstraint?.isActive = false

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
        if seconds < 0 { return L10n.tr("now") }

        let oneWeek: TimeInterval = 7 * 24 * 60 * 60
        if seconds >= oneWeek {
            let df = DateFormatter()
            df.locale = Locale.current
            df.timeZone = .current
            df.dateFormat = "dd/MM/yyyy"
            return df.string(from: date)
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale.current
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
