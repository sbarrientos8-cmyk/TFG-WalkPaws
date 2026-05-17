//
//  Search.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 31/1/26.
//

import UIKit

final class SearchField: UIView
{
    private let backgroundView = UIView()
    private let textField = UITextField()
    private let iconView = UIImageView()

    private var onChange: ((String) -> Void)?
    private var onSubmit: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        // Fondo
        backgroundView.backgroundColor = Colors.white
        backgroundView.layer.cornerRadius = 10
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = Colors.greenField.cgColor
        backgroundView.layer.masksToBounds = true
        addSubview(backgroundView)

        // TextField
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.font = Fonts.figtreeRegular(16)
        textField.textColor = Colors.greenDark
        textField.tintColor = Colors.greenDark
        textField.autocorrectionType = .no
        textField.returnKeyType = .search
        textField.delegate = self
        backgroundView.addSubview(textField)

        iconView.image = UIImage(named: "search")?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = Colors.main
        iconView.contentMode = .scaleAspectFill
        backgroundView.addSubview(iconView)

        // Layout
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -14),
            iconView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            textField.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 14),
            textField.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -10),
            textField.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 10),
            textField.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -10)
        ])

        // Eventos
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    // MARK: - Public API
    func config(placeholder: String) {
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: Colors.greenField.withAlphaComponent(0.75),.font: Fonts.figtreeRegular(16)])
    }

    func setText(_ text: String) {
        textField.text = text
        onChange?(text)
    }

    func getText() -> String {
        textField.text ?? ""
    }

    func onTextChange(_ handler: @escaping (String) -> Void) {
        self.onChange = handler
    }

    func onSearch(_ handler: @escaping (String) -> Void) {
        self.onSubmit = handler
    }

    @objc private func textDidChange() {
        onChange?(textField.text ?? "")
    }
}

extension SearchField: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let text = textField.text ?? ""
        onSubmit?(text)
        textField.resignFirstResponder()
        return true
    }
}
