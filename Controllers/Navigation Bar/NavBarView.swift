//
//  NavBarController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 31/1/26.
//

import UIKit

final class NavBarView: UIView
{
    
    @IBOutlet weak var buttonType: UIButton!
    
    private var action: (() -> Void)?
    
    private func commonInit()
    {
        let nib = UINib(nibName: "NavBarView", bundle: .main)
        guard let content = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            return
        }

        content.frame = bounds
        content.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(content)
    }

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        commonInit()
    }
    
    func config(with type: NavBarButtonType)
    {
        buttonType.setImage(type.image, for: .normal)
        self.action = type.action
    }
    
    @IBAction func buttonClicked(_ sender: Any)
    {
        action?()
    }
}
