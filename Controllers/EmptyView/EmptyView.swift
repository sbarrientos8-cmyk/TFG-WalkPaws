//
//  EmptyView.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 5/3/26.
//

import UIKit


class EmptyView: UIView {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var labelTitle: UILabel!
    @IBOutlet private weak var labelDescription: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        labelTitle.config(text: "", style: StylesLabel.titleMap)
        labelDescription.config(text: "", style: StylesLabel.descriptionGreen)
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let nib = UINib(nibName: "EmptyView", bundle: .main)
        let content = nib.instantiate(withOwner: self, options: nil).first as! UIView
        content.frame = bounds
        content.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(content)
    }

    // MARK: - Config
    func config(image: UIImage?, title: String, description: String) {
        imageView.image = image
        labelTitle.text = title
        labelDescription.text = description
    }
}


enum EmptyType {
    case noDogs
    case noPosts
    case noShelters
    case noWalks
}
