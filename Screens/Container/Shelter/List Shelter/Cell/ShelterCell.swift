//
//  ShelterCell.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 31/1/26.
//

import UIKit

class ShelterCell: UITableViewCell
{
    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var labelUbication: UILabel!
    
    private var currentImageURL: String?

    override func awakeFromNib()
    {
        super.awakeFromNib()

        viewBackground.layer.masksToBounds = true
        imageProfile.layer.cornerRadius = 10
        labelName.config(text: "", style: StylesLabel.title1)
        labelDescription.config(text: "", style: StylesLabel.description)
        labelUbication.config(text: "", style: StylesLabel.ubication)
    }

    override func prepareForReuse()
    {
        super.prepareForReuse()
        imageProfile.image = nil
        currentImageURL = nil
    }

    func config(with shelter: ShelterModel)
    {
        labelName.text = shelter.name
        labelDescription.text = shelter.description
        labelUbication.text = shelter.locationText
        
        guard let urlString = shelter.photoURL else { return }
            loadImage(from: urlString)
    }

    private func loadImage(from urlString: String)
    {
        currentImageURL = urlString

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }
            guard let data, let image = UIImage(data: data) else { return }

            guard self.currentImageURL == urlString else { return }
            
            DispatchQueue.main.async {
                self.imageProfile.image = image
            }
        }.resume()
    }
    
}
