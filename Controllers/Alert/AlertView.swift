//
//  AlertView.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 2/2/26.
//

import UIKit

final class AlertView: UIViewController
{

    @IBOutlet weak var viewAlert: UIView!
    @IBOutlet weak var imageAlert: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var buttonAccept: UIButton!

    private var onAccept: (() -> Void)?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.40)

        viewAlert.backgroundColor = Colors.white
        viewAlert.layer.cornerRadius = 6
        imageAlert.layer.cornerRadius = 10

        labelTitle.font = StylesLabel.alertTitle.font
        
        buttonAccept.config(text: "", style: StylesButton.alertButton)
        
    }

    func config(image: UIImage?, title: String, buttonTitle: String = "Aceptar", onAccept: (() -> Void)? = nil)
    {
        self.imageAlert.image = image
        self.labelTitle.text = title
        self.buttonAccept.setTitle(buttonTitle, for: .normal)
        self.onAccept = onAccept
    }
    

    @IBAction func aceptClicked(_ sender: Any)
    {
        dismiss(animated: true) { [weak self] in
            self?.onAccept?()
        }
    }
}
