//
//  SectionProfileCell.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 12/2/26.
//

import UIKit

class SectionProfileCell: UITableViewCell
{

    @IBOutlet weak var labelSection: UILabel!
    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var imageSection: UIImageView!
    
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        viewBackground.layer.cornerRadius = 12
        labelSection.config(text: "", style: StylesLabel.title1)
    }
    
    func config(with section: ProfileSection)
    {
        labelSection.text = section.title
        imageSection.image = UIImage(named: section.image)
    }
    
    @IBAction func sectionClicked(_ sender: Any)
    {
        
    }
}
