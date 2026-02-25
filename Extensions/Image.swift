//
//  Image.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/2/26.
//

import UIKit

extension UIView {

    func applyShadow(
        color: UIColor = .black,
        opacity: Float = 0.12,
        offset: CGSize = CGSize(width: 0, height: 6),
        radius: CGFloat = 12,
        cornerRadius: CGFloat? = nil
    ) {

        if let cornerRadius = cornerRadius {
            layer.cornerRadius = cornerRadius
        }

        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
    }

    func updateShadowPath() {
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: layer.cornerRadius
        ).cgPath
    }
}
