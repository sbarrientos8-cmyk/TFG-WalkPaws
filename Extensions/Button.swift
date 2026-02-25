//
//  Button.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/1/26.
//

import UIKit

extension UIButton
{
    func config(text: String, style: StyleButton)
    {
        setTitle(text, for: .normal)
        titleLabel?.font = style.font
        setTitleColor(style.titleColor, for: .normal)
        backgroundColor = style.backgroundColor
        layer.cornerRadius = style.cornerRadius ?? 0

        layer.borderColor = style.borderColor?.cgColor
        layer.borderWidth = style.borderWidth ?? 0
    }
    
    func configWithIcon(
        text: String,
        image: UIImage?,
        style: StyleButton,
        imagePlacement: NSDirectionalRectEdge = .leading,
        imagePadding: CGFloat = 3,
        iconSize: CGSize = CGSize(width: 18, height: 18), withShadow: Bool = false
    ) {
        backgroundColor = style.backgroundColor
        layer.cornerRadius = style.cornerRadius ?? 0
        layer.borderColor = style.borderColor?.cgColor
        layer.borderWidth = style.borderWidth ?? 0

        var config = UIButton.Configuration.plain()

        var attrs = AttributeContainer()
        attrs.font = style.font
        attrs.foregroundColor = style.titleColor
        config.attributedTitle = AttributedString(text, attributes: attrs)

        config.image = resizedImage(image, size: iconSize)
        config.imagePlacement = imagePlacement
        config.imagePadding = imagePadding
        config.titleLineBreakMode = .byTruncatingTail

        self.configuration = config

        self.tintColor = style.titleColor

        self.titleLabel?.numberOfLines = 1
        
        if withShadow
        {
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.15
            layer.shadowOffset = CGSize(width: 0, height: 4)
            layer.shadowRadius = 8
            layer.masksToBounds = false
        } else {
            layer.shadowOpacity = 0
            layer.shadowRadius = 0
            layer.shadowOffset = .zero
        }
    }

    private func resizedImage(_ image: UIImage?, size: CGSize) -> UIImage? {
        guard let image else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysTemplate)
    }
    
    func applyShadow(
        opacity: Float = 0.15,
        offset: CGSize = CGSize(width: 0, height: 4),
        radius: CGFloat = 8,
        color: UIColor = .black
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
}
