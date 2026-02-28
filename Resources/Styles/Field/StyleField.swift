//
//  StyleField.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/1/26.
//

import UIKit

final class ShiftedTextField: UITextField {

    /// Si pones -2, el texto/placeholder sube 2pt.
    var verticalOffset: CGFloat = -2

    /// Padding horizontal estándar (puedes tocarlo si quieres)
    var horizontalInset: CGFloat = 0

    private func adjustedRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: horizontalInset, dy: 0).offsetBy(dx: 0, dy: verticalOffset)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        adjustedRect(forBounds: bounds)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        adjustedRect(forBounds: bounds)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        adjustedRect(forBounds: bounds)
    }
}

class LabelField: UIView {

    private let backgroundView = UIView()
    private let iconView = UIImageView()
    private let textField = ShiftedTextField()

    // MARK: - Constraints que vamos a alternar
    private var iconWidthConstraint: NSLayoutConstraint!
    private var textLeadingToIconConstraint: NSLayoutConstraint!
    private var textLeadingToBackgroundConstraint: NSLayoutConstraint!

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

        // 👇 Ajuste para “subir” placeholder/texto
        textField.verticalOffset = -2   // prueba -2 o -3 si lo quieres más arriba

        backgroundView.addSubview(textField)

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false

        // Constraints fijos
        iconWidthConstraint = iconView.widthAnchor.constraint(equalToConstant: 22)

        // Alternativas para el leading del textField:
        textLeadingToIconConstraint = textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10)
        textLeadingToBackgroundConstraint = textField.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 14)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

            iconView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            iconWidthConstraint,
            iconView.heightAnchor.constraint(equalToConstant: 22),

            textField.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -14),
            textField.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor)
        ])

        // Por defecto asumimos que hay icono
        textLeadingToIconConstraint.isActive = true
    }

    func config(image: UIImage?, placeholder: String, isSecure: Bool = false) {
        // Placeholder
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.figtreeMedium(18),
            .foregroundColor: Colors.textField
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
        textField.isSecureTextEntry = isSecure

        // Icono + constraints dinámicas
        if let img = image {
            iconView.isHidden = false
            iconView.image = img.withRenderingMode(.alwaysTemplate)

            iconWidthConstraint.constant = 22

            textLeadingToBackgroundConstraint.isActive = false
            textLeadingToIconConstraint.isActive = true

        } else {
            iconView.isHidden = true
            iconView.image = nil

            // quitamos el “hueco” del icono
            iconWidthConstraint.constant = 0

            textLeadingToIconConstraint.isActive = false
            textLeadingToBackgroundConstraint.isActive = true
        }

        // Aplica cambios sin “parpadeos”
        layoutIfNeeded()
    }

    func setCornerRadius(_ radius: CGFloat) {
        backgroundView.layer.cornerRadius = radius
    }

    func getText() -> String {
        textField.text ?? ""
    }

    func onTextChange(_ handler: @escaping (String) -> Void) {
        textField.addAction(UIAction { [weak self] _ in
            handler(self?.textField.text ?? "")
        }, for: .editingChanged)
    }

    func setText(_ text: String) {
        textField.text = text
    }
}


final class TextAreaField: UIView, UITextViewDelegate {

    private let backgroundView = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()

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

        backgroundView.backgroundColor = Colors.white
        backgroundView.layer.cornerRadius = 6
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.borderWidth = 2
        backgroundView.layer.borderColor = Colors.borderField.cgColor
        addSubview(backgroundView)

        textView.font = Fonts.figtreeRegular(18)
        textView.textColor = Colors.greenDark
        textView.tintColor = Colors.main
        textView.backgroundColor = .clear
        textView.delegate = self

        // ✅ Esto es lo que hace que el texto empiece ARRIBA
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        textView.textContainer.lineFragmentPadding = 0

        backgroundView.addSubview(textView)

        placeholderLabel.font = Fonts.figtreeMedium(18)
        placeholderLabel.textColor = Colors.textField
        backgroundView.addSubview(placeholderLabel)

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),

            textView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            textView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),

            // ✅ placeholder arriba a la izquierda (NO centerY)
            placeholderLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 14),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: backgroundView.trailingAnchor, constant: -14)
        ])
    }

    func config(placeholder: String) {
        placeholderLabel.text = placeholder
        placeholderLabel.isHidden = !getText().isEmpty
    }

    func getText() -> String {
        textView.text ?? ""
    }

    func setText(_ text: String) {
        textView.text = text
        placeholderLabel.isHidden = !text.isEmpty
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    func onTextChange(_ handler: @escaping (String) -> Void) {
        // opcional: si quieres callback
        // puedes llamar handler en textViewDidChange guardándolo en una variable
    }
}

/// Campo reutilizable: icono + texto + dropdown filtrable
final class DropdownFieldView: UIView {

    // MARK: UI
    private let iconView = UIImageView()
    private let textField = UITextField()
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.down"))

    private let tableView = UITableView()
    private var tableHeightConstraint: NSLayoutConstraint!

    // MARK: Data
    private var allItems: [String] = []
    private var filteredItems: [String] = []

    // Callbacks
    var onSelect: ((String) -> Void)?

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupTable()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupTable()
    }

    // MARK: Public API

    /// Configura icono y placeholder
    func config(imageName: String, placeholder: String) {
        iconView.image = UIImage(named: imageName) ?? UIImage(systemName: imageName)
        textField.placeholder = placeholder
    }

    /// Establece los elementos que tendrá el dropdown
    func setItems(_ items: [String]) {
        allItems = items
        filteredItems = items
        tableView.reloadData()
    }

    /// Obtiene el texto actual
    func getText() -> String {
        textField.text ?? ""
    }

    /// Set texto (por ejemplo al seleccionar)
    func setText(_ value: String) {
        textField.text = value
    }

    // MARK: UI Setup

    private func setupUI() {
        // Estilo base del contenedor (ajusta si quieres)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor
        backgroundColor = .systemBackground

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        chevronView.tintColor = .systemGray3
        chevronView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(textField)
        addSubview(chevronView)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            chevronView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            chevronView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 14),
            chevronView.heightAnchor.constraint(equalToConstant: 14),

            textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -10),
            textField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 46)
        ])
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true
        tableView.layer.cornerRadius = 12
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.systemGray5.cgColor
        tableView.rowHeight = 46
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)

        tableView.dataSource = self
        tableView.delegate = self

        // IMPORTANTE: el dropdown NO va dentro del campo, va al superview (para que "flote")
        // Si el campo aún no tiene superview en init, lo insertamos en didMoveToSuperview.
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let parent = superview else { return }

        if tableView.superview == nil {
            parent.addSubview(tableView)

            // Dropdown debajo del campo
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: bottomAnchor, constant: 6),
                tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])

            tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
            tableHeightConstraint.isActive = true
        }
    }

    private func showDropdown() {
        filteredItems = filterItems(query: textField.text ?? "")
        tableView.reloadData()

        let count = min(filteredItems.count, 5) // máximo 5 filas visibles
        tableHeightConstraint.constant = CGFloat(count) * tableView.rowHeight

        tableView.isHidden = filteredItems.isEmpty
        tableView.superview?.bringSubviewToFront(tableView)
    }

    private func hideDropdown() {
        tableHeightConstraint.constant = 0
        tableView.isHidden = true
    }

    private func filterItems(query: String) -> [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return allItems }
        return allItems.filter { $0.lowercased().contains(q) }
    }

    @objc private func textDidChange() {
        showDropdown()
    }
}

// MARK: - UITextFieldDelegate
extension DropdownFieldView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        showDropdown()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // Pequeño delay por si justo se está tocando una celda
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.hideDropdown()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Table
extension DropdownFieldView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: id)
            ?? UITableViewCell(style: .default, reuseIdentifier: id)

        cell.textLabel?.text = filteredItems[indexPath.row]
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = filteredItems[indexPath.row]
        textField.text = selected
        onSelect?(selected)

        // cerrar
        textField.resignFirstResponder()
        hideDropdown()
    }
}
