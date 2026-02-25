//
//  View.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 14/2/26.
//

import UIKit

extension UIView {

    func applyCardStyle(
        cornerRadius: CGFloat = 12,
        shadowOpacity: Float = 0.1,
        shadowOffset: CGSize = CGSize(width: 0, height: 6),
        shadowRadius: CGFloat = 12
    ) {
        layer.cornerRadius = cornerRadius

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
        layer.masksToBounds = false
    }

    func updateShadowPath(cornerRadius: CGFloat) {
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: cornerRadius
        ).cgPath
    }
    
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}

open class CircleImageView: UIImageView {

    public override func layoutSubviews() {
        super.layoutSubviews()

        layer.masksToBounds = true
        layer.cornerRadius = frame.height / 2
    }
}
