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
    var maxDonationEur: Double = 0   // lo setea DogDetailNeedyController

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
        labelTitle.config(text: L10n.tr("make_donation"), style: StylesLabel.titleHi)
        labelTitle1.config(text: L10n.tr("donate_with_points"), style: StylesLabel.titleMap)

        
        Task { [weak self] in
            guard let self else { return }
            do {
                let points = try await fetchMyPoints()
                let euros = Double(points) / 10.0

                // ✅ lo que falta por donar en euros (lo pasas desde DogDetailNeedyController)
                let restEur = max(0, self.maxDonationEur)

                // ✅ puntos necesarios para completar (redondeo hacia arriba)
                let pointsToComplete = Int(ceil(restEur * 10.0))

                var extraLine = ""
                if restEur > 0 {
                    if points >= pointsToComplete {
                        extraLine = "\n" + String(
                            format: L10n.tr("donate_points_to_complete"),
                            pointsToComplete
                        )
                    } else {
                        extraLine = "\n" + String(
                            format: L10n.tr( "points_missing_to_complete_donation"),
                            pointsToComplete - points
                        )
                    }
                }

                let euroText = String(format: "%.2f", euros)
                let text = String(
                    format: L10n.tr("you_have_points_equivalent_eur"),
                    points,
                    euroText
                ) + extraLine

                await MainActor.run {
                    self.labelDescription1.config(text: text, style: StylesLabel.description)
                }
            } catch {
                print("❌ fetchMyPoints error:", error)
            }
        }
        
        buttonDonatePoints.config(text: L10n.tr("donate"), style: StylesButton.secondaryGreen2)
        buttonDonatePoints.applyShadow(cornerRadius: 20)
        
        labelTitle2.config(text: L10n.tr("donate_with_card"), style: StylesLabel.titleMap)
        labelDescription2.config(text: L10n.tr("enter_card_details_and_amount"), style: StylesLabel.description)
        buttonDonateMoney.config(text: L10n.tr("donate"), style: StylesButton.secondaryGreen2)
        buttonDonateMoney.applyShadow(cornerRadius: 20)

        // Placeholder
        fieldPoints.config(image: nil, placeholder: L10n.tr( "points_placeholder"))
        fieldMoney.config(image: nil, placeholder: L10n.tr("euros"))
        fieldNumber.config(image: nil, placeholder: L10n.tr( "card_number"))
        fieldName.config(image: nil, placeholder: L10n.tr( "cardholder_name"))
        fieldDate.config(image: nil, placeholder: L10n.tr("mm_yy"))
        fieldCVC.config(image: nil, placeholder: L10n.tr("cvc"))
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
            showError(L10n.tr("invalid_dog_id"))
            return
        }

        Task {
            do {
                // (Opcional) comprobar puntos reales aquí antes de donar:
                let totalPoints = try await fetchMyPoints()
                if points > totalPoints {
                    await MainActor.run {
                        self.showError(String(format: L10n.tr( "not_enough_points_you_have"), totalPoints))
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
                await MainActor.run { self.showError(L10n.tr( "error_donating_points_try_again")) }
                print("❌ donate_points error:", error)
            }
        }
    }

    // MARK: - Donar dinero (tarjeta ficticia) -> RPC donate_money
    @IBAction func donateMoneyClicked(_ sender: Any) {
        guard let result = validateMoneyDonation() else { return }
        guard let dogUUID = UUID(uuidString: dogId) else {
            showError(L10n.tr("invalid_dog_id"))
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
                await MainActor.run { self.showError(L10n.tr( "error_donating_by_card_try_again")) }
                print("❌ donate_money error:", error)
            }
        }
    }
    
    
    
    
    
    
    
    private func validateMoneyDonation() -> (eur: Double, last4: String)? {
        // euros
        let moneyText = fieldMoney.getText()
        if moneyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(L10n.tr("enter_amount_in_euros"))
            return nil
        }

        guard let eur = parseEur(moneyText), eur > 0 else {
            showError(L10n.tr("amount_must_be_valid_greater_than_zero"))
            return nil
        }

        if maxDonationEur > 0, eur > maxDonationEur + 0.0001 {
            showError(String(format: L10n.tr( "cannot_donate_more_than_eur"), maxDonationEur))
            return nil
        }

        // tarjeta
        let numberRaw = fieldNumber.getText()
        let number = digitsOnly(numberRaw)

        if number.isEmpty {
            showError(L10n.tr("enter_card_number"))
            return nil
        }

        if !isValidCardNumber(number) {
            showError(L10n.tr("invalid_card_number"))
            return nil
        }

        // nombre
        let name = fieldName.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            showError(L10n.tr("enter_cardholder_name"))
            return nil
        }

        // fecha MMYY -> MM/YY
        let dateRaw = fieldDate.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        if dateRaw.isEmpty {
            showError(L10n.tr("enter_expiration_date"))
            return nil
        }

        guard let _ = formatMMYY(dateRaw) else {
            showError(L10n.tr("invalid_date_use_mmyy"))
            return nil
        }

        // cvc
        let cvcRaw = fieldCVC.getText()
        if cvcRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(L10n.tr("enter_cvc"))
            return nil
        }

        if !isValidCVC(cvcRaw) {
            showError(L10n.tr("invalid_cvc"))
            return nil
        }

        return (eur: eur, last4: String(number.suffix(4)))
    }
    
    private func validatePointsDonation() -> Int? {
        let raw = fieldPoints.getText().trimmingCharacters(in: .whitespacesAndNewlines)

        if raw.isEmpty {
            showError(L10n.tr("enter_points_to_donate"))
            return nil
        }

        guard let points = Int(raw), points > 0 else {
            showError(L10n.tr("points_must_be_greater_than_zero"))
            return nil
        }

        // ✅ Límite por lo que falta donar
        // 10 puntos = 1€
        if maxDonationEur > 0 {
            let maxPoints = Int(ceil(maxDonationEur * 10.0))   // redondeo hacia arriba
            if points > maxPoints {
                showError(String(format: L10n.tr( "cannot_donate_more_than_points"), maxPoints))
                return nil
            }
        }

        return points
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: L10n.tr("check_your_data"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default))
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
