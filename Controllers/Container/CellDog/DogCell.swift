//
//  DogCell.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 27/1/26.
//


import UIKit
import SDWebImage

enum DogCellSubtitle {
    case age
    case city
}

class DogCell: UICollectionViewCell {

    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var ImageDog: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var labelBreed: UILabel!

    private let imageLoadingIndicator = UIActivityIndicatorView(style: .medium)

    override func awakeFromNib() {
        super.awakeFromNib()

        labelName.config(text: "", style: StylesLabel.titleHi)
        labelDescription.config(text: "", style: StylesLabel.subtitle)
        labelBreed.config(text: "", style: StylesLabel.subtitleGray)

        ImageDog.contentMode = .scaleAspectFill
        ImageDog.clipsToBounds = true
        ImageDog.layer.cornerRadius = 10

        viewBackground.layer.cornerRadius = 12

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        setupLoadingIndicator()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ImageDog.sd_cancelCurrentImageLoad()
        ImageDog.image = nil
        imageLoadingIndicator.stopAnimating()
    }

    private func setupLoadingIndicator() {
        imageLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        imageLoadingIndicator.hidesWhenStopped = true

        ImageDog.addSubview(imageLoadingIndicator)

        NSLayoutConstraint.activate([
            imageLoadingIndicator.centerXAnchor.constraint(equalTo: ImageDog.centerXAnchor),
            imageLoadingIndicator.centerYAnchor.constraint(equalTo: ImageDog.centerYAnchor)
        ])
    }

    func config(with dog: DogModel, subtitle: DogCellSubtitle) {
        labelName.text = dog.name
        labelBreed.text = dog.breed

        switch subtitle {
        case .age:
            if let age = dog.age {
                labelDescription.text = String(
                    format: L10n.tr("dog_age_years"),
                    String(age)
                )
            } else {
                labelDescription.text = L10n.tr("unknown_age")
            }

        case .city:
            labelDescription.text = dog.city
        }

        if let urlString = dog.photoURL,
           let url = URL(string: urlString) {

            ImageDog.image = nil
            imageLoadingIndicator.startAnimating()

            ImageDog.sd_setImage(
                with: url,
                placeholderImage: nil,
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            ) { [weak self] _, _, _, _ in
                self?.imageLoadingIndicator.stopAnimating()
            }

        } else {
            ImageDog.image = nil
            imageLoadingIndicator.stopAnimating()
        }
    }
}
