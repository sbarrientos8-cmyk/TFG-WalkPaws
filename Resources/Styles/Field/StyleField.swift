//
//  StyleField.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/1/26.
//

import UIKit

class LabelField: UIView
{

    private let backgroundView = UIView()
    private let iconView = UIImageView()
    private let textField = UITextField()

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI()
    {
        backgroundColor = .clear

        backgroundView.backgroundColor = Colors.white
        backgroundView.layer.cornerRadius = 6
        backgroundView.layer.masksToBounds = true
        
        backgroundView.layer.borderWidth = 2
        backgroundView.layer.borderColor = Colors.borderField.cgColor
        addSubview(backgroundView)

        iconView.contentMode = .scaleAspectFill
        iconView.tintColor = Colors.greenField
        backgroundView.addSubview(iconView)

        textField.font = Fonts.figtreeRegular(18)
        textField.textColor = Colors.greenDark
        textField.tintColor = Colors.main
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        backgroundView.addSubview(textField)

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -14),
            textField.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
        ])
    }

    func config(image: UIImage?, placeholder: String, isSecure: Bool = false)
    {
        iconView.image = image?.withRenderingMode(.alwaysTemplate)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.figtreeMedium(18),
            .foregroundColor: Colors.textField
        ]

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: attributes
        )

        textField.isSecureTextEntry = isSecure
    }

    func setCornerRadius(_ radius: CGFloat)
    {
        backgroundView.layer.cornerRadius = radius
    }
    
    func getText() -> String
    {
        return textField.text ?? ""
    }

    func onTextChange(_ handler: @escaping (String) -> Void)
    {
        textField.addAction(UIAction { [weak self] _ in
            handler(self?.textField.text ?? "")
        }, for: .editingChanged)
    }
    
    func setText(_ text: String) {
        textField.text = text
    }
}
