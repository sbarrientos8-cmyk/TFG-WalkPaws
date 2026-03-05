//
//  DonateController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 5/3/26.
//

import UIKit

class DonateController: UIViewController
{

    var dogId: String = "" // UUID string del perro
    var onDonationSuccess: (() -> Void)?

    @IBOutlet weak var labelTitle: UILabel!

    @IBOutlet weak var viewFormPoints: UIView!
    @IBOutlet weak var labelTitle1: UILabel!
    @IBOutlet weak var labelDescription1: UILabel!
    @IBOutlet weak var fieldPoints: LabelField!
    @IBOutlet weak var buttonDonatePoints: UIButton!

    @IBOutlet weak var viewFormMoney: UIView!
    @IBOutlet weak var labelTitle2: UILabel!
    @IBOutlet weak var labelDescription2: UILabel!
    @IBOutlet weak var fieldNumber: LabelField!
    @IBOutlet weak var fieldName: LabelField!
    @IBOutlet weak var fieldDate: LabelField!
    @IBOutlet weak var fieldCVC: LabelField!
    @IBOutlet weak var fieldMoney: LabelField!
    @IBOutlet weak var buttonDonateMoney: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Aquí pon tus estilos si quieres (no te los toco)
        labelTitle.config(text: "Realizar donación", style: StylesLabel.titleHi)
        
        labelTitle1.config(text: "Donar con puntos", style: StylesLabel.titleMap)
        
        Task { [weak self] in
            guard let self else { return }
            do {
                let points = try await fetchMyPoints()
                let euros = Double(points) / 10.0

                let text = "Tienes \(points) puntos que equivale a \(String(format: "%.2f", euros))€"

                await MainActor.run {
                    self.labelDescription1.config(text: text, style: StylesLabel.description)
                }
            } catch {
                print("❌ fetchMyPoints error:", error)
            }
        }
        
        buttonDonatePoints.config(text: "Donar", style: StylesButton.secondaryGreen2)
        buttonDonatePoints.applyShadow(cornerRadius: 20)
        
        labelTitle2.config(text: "Donar con tarjeta", style: StylesLabel.titleMap)
        labelDescription2.config(text: "Añadir los datos de tu tarjeta y el importe que quieres donar", style: StylesLabel.description)
        buttonDonateMoney.config(text: "Donar", style: StylesButton.secondaryGreen2)
        buttonDonateMoney.applyShadow(cornerRadius: 20)

        // Placeholder
        fieldPoints.config(image: nil, placeholder: "Puntos")
        fieldMoney.config(image: nil, placeholder: "Euros")
        fieldNumber.config(image: nil, placeholder: "Número tarjeta")
        fieldName.config(image: nil, placeholder: "Nombre titular")
        fieldDate.config(image: nil, placeholder: "MM/AA")
        fieldDate.onTextChange { [weak self] text in
            guard let self else { return }

            // Solo dígitos, máximo 4 (MMYY)
            var digits = self.digitsOnly(text)
            if digits.count > 4 { digits = String(digits.prefix(4)) }

            // Reescribir el campo sin que el user ponga "/"
            self.fieldDate.setText(digits)

            // (Opcional) si quieres mostrar "MM/YY" visualmente en el field:
            // si digits.count >= 3, conviértelo a "MM/YY"
            if digits.count >= 3 {
                let mm = String(digits.prefix(2))
                let rest = String(digits.dropFirst(2))
                self.fieldDate.setText(mm + "/" + rest) // se verá el slash, pero el user no lo escribe
            }
        }
        
        
        fieldCVC.config(image: nil, placeholder: "CVC")
        
        viewFormPoints.applyCardStyle()
        viewFormMoney.applyCardStyle()
    }

    // MARK: - Donar puntos (usa tu RPC donate_points)
    @IBAction func donatePointsClicked(_ sender: Any) {
        guard let points = validatePointsDonation() else { return }
        guard let dogUUID = UUID(uuidString: dogId) else {
            showError("DogId inválido.")
            return
        }

        Task {
            do {
                // (Opcional) comprobar puntos reales aquí antes de donar:
                let totalPoints = try await fetchMyPoints()
                if points > totalPoints {
                    await MainActor.run {
                        self.showError("No tienes suficientes puntos. Tienes \(totalPoints).")
                    }
                    return
                }

                let params = DonateParams(p_dog_id: dogUUID.uuidString, p_points: points)
                _ = try await SupabaseManager.shared.client
                    .rpc("donate_points", params: params)
                    .execute()

                await MainActor.run {
                    self.onDonationSuccess?()
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run { self.showError("Error al donar puntos. Inténtalo de nuevo.") }
                print("❌ donate_points error:", error)
            }
        }
    }

    // MARK: - Donar dinero (tarjeta ficticia) -> RPC donate_money
    @IBAction func donateMoneyClicked(_ sender: Any) {
        guard let result = validateMoneyDonation() else { return }
        guard let dogUUID = UUID(uuidString: dogId) else {
            showError("DogId inválido.")
            return
        }

        Task {
            do {
                let params = DonateMoneyParams(
                    p_dog_id: dogUUID.uuidString,
                    p_eur_amount: result.eur,
                    p_card_last4: result.last4
                )

                _ = try await SupabaseManager.shared.client
                    .rpc("donate_money", params: params)
                    .execute()

                await MainActor.run {
                    self.onDonationSuccess?()
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run { self.showError("Error al donar con tarjeta. Inténtalo de nuevo.") }
                print("❌ donate_money error:", error)
            }
        }
    }
    
    
    
    
    
    
    
    private func validateMoneyDonation() -> (eur: Double, last4: String)? {
        // euros
        let moneyText = fieldMoney.getText()
        if moneyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Introduce el importe en euros.")
            return nil
        }

        guard let eur = parseEur(moneyText), eur > 0 else {
            showError("El importe debe ser un número válido mayor que 0. Ejemplo: 10 o 10,50")
            return nil
        }

        // tarjeta
        let numberRaw = fieldNumber.getText()
        let number = digitsOnly(numberRaw)

        if number.isEmpty {
            showError("Introduce el número de tarjeta.")
            return nil
        }

        if !isValidCardNumber(number) {
            showError("Número de tarjeta no válido.")
            return nil
        }

        // nombre
        let name = fieldName.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            showError("Introduce el nombre del titular.")
            return nil
        }

        // fecha MMYY -> MM/YY
        let dateRaw = fieldDate.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        if dateRaw.isEmpty {
            showError("Introduce la fecha de caducidad.")
            return nil
        }

        guard let _ = formatMMYY(dateRaw) else {
            showError("Fecha no válida. Usa formato MMYY (ej: 0728).")
            return nil
        }

        // cvc
        let cvcRaw = fieldCVC.getText()
        if cvcRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Introduce el CVC.")
            return nil
        }

        if !isValidCVC(cvcRaw) {
            showError("CVC no válido. Debe tener 3 o 4 dígitos.")
            return nil
        }

        return (eur: eur, last4: String(number.suffix(4)))
    }
    
    private func validatePointsDonation() -> Int? {
        let raw = fieldPoints.getText().trimmingCharacters(in: .whitespacesAndNewlines)

        if raw.isEmpty {
            showError("Introduce los puntos que quieres donar.")
            return nil
        }

        guard let points = Int(raw), points > 0 else {
            showError("Los puntos deben ser un número mayor que 0.")
            return nil
        }

        return points
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Revisa los datos", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func digitsOnly(_ text: String) -> String {
        text.filter { $0.isNumber }
    }

    private func isValidCardNumber(_ number: String) -> Bool {
        // Luhn check (básico)
        let digits = number.compactMap { Int(String($0)) }
        guard digits.count >= 13 && digits.count <= 19 else { return false }

        var sum = 0
        let reversed = digits.reversed()
        for (idx, d) in reversed.enumerated() {
            if idx % 2 == 1 {
                let doubled = d * 2
                sum += (doubled > 9) ? (doubled - 9) : doubled
            } else {
                sum += d
            }
        }
        return sum % 10 == 0
    }

    private func parseMMYY(_ raw: String) -> (mm: Int, yy: Int)? {
        // raw debe venir como "MMYY" (4 dígitos)
        let d = digitsOnly(raw)
        guard d.count == 4 else { return nil }

        let mmStr = String(d.prefix(2))
        let yyStr = String(d.suffix(2))
        guard let mm = Int(mmStr), let yy = Int(yyStr) else { return nil }
        guard (1...12).contains(mm) else { return nil }

        // Validar expiración (mes actual vs año actual)
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now) % 100 // ej: 26
        let currentMonth = calendar.component(.month, from: now)

        // Si está en el pasado -> inválida
        if yy < currentYear { return nil }
        if yy == currentYear && mm < currentMonth { return nil }

        return (mm, yy)
    }

    private func formatMMYY(_ raw: String) -> String? {
        guard let p = parseMMYY(raw) else { return nil }
        return String(format: "%02d/%02d", p.mm, p.yy)
    }

    private func isValidCVC(_ cvc: String) -> Bool {
        let d = digitsOnly(cvc)
        return d.count == 3 || d.count == 4
    }

    private func parseEur(_ text: String) -> Double? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }
}
