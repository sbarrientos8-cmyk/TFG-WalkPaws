//
//  AlertModel.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 2/2/26.
//

import UIKit

enum Alert
{
    static func show(on vc: UIViewController, image: UIImage?, title: String, buttonTitle: String = "Aceptar", onAccept: (() -> Void)? = nil)
    {
        let alertVC = AlertView(nibName: "AlertView", bundle: nil)
        alertVC.loadViewIfNeeded()

        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve

        alertVC.config(image: image, title: title, buttonTitle: buttonTitle, onAccept: onAccept)

        vc.present(alertVC, animated: true)
    }
}
