//
//  DogCell.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 19/2/26.
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
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ImageDog.sd_cancelCurrentImageLoad()
        ImageDog.image = UIImage(systemName: "dog")
    }

    func config(with dog: DogModel, subtitle: DogCellSubtitle) {

        labelName.text = dog.name
        labelBreed.text = dog.breed

        switch subtitle {
        case .age:
            if let age = dog.age {
                labelDescription.text = "\(age) años"
            } else {
                labelDescription.text = "Edad desconocida"
            }

        case .city:
            labelDescription.text = dog.city
        }

        if let urlString = dog.photoURL,
           let url = URL(string: urlString) {

            ImageDog.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "dog"),
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            )
        } else {
            ImageDog.image = UIImage(systemName: "dog")
        }
    }
    
}
