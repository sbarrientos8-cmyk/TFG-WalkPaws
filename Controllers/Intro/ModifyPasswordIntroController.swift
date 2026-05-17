//
//  ModifyPasswordIntroController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 27/1/26.
//

import UIKit
import Supabase


class ModifyPasswordIntroController: UIViewController
{
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var fieldCode: LabelField!
    @IBOutlet weak var labelState: UILabel!
    @IBOutlet weak var viewModify: UIView!
    @IBOutlet weak var fieldPassword: LabelField!
    @IBOutlet weak var fieldNewPassword: LabelField!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var buttonResendCode: UIButton!
    @IBOutlet weak var labelResendCode: UILabel!
    
    var emailForRecovery: String = ""
    private var otpVerified = false
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        labelTitle.config(text: L10n.tr("new_password"), style: StylesLabel.title)
        fieldCode.config(image: UIImage(named: "code"), placeholder: L10n.tr("verification_code"))
        fieldPassword.config(image: UIImage(named: "lock"), placeholder: L10n.tr("new_password"))
        fieldNewPassword.config(image: UIImage(named: "lock"), placeholder: L10n.tr( "confirm_password"))
        buttonSave.config(text: L10n.tr("save"), style: StylesButton.primary)
        
        labelResendCode.config(text: L10n.tr( "didnt_receive_code_resend_code"), style: StylesLabel.subtitle)
        
        viewModify.isHidden = true
        labelState.text = ""

        fieldCode.onTextChange { [weak self] text in
            self?.validateCodeIfNeeded(text)
        }
        
        hideKeyboardWhenTappedAround()
    }
    
    private func showMessage(_ text: String)
    {
        labelState.text = text
    }

    // Verifica OTP cuando tenga una longitud razonable (ej 6)
    private func validateCodeIfNeeded(_ code: String)
    {
        let token = code.trimmingCharacters(in: .whitespacesAndNewlines)

        // Ajusta si tu OTP es de 6 dígitos (lo usual)
        guard token.count >= 6 else
        {
            otpVerified = false
            viewModify.isHidden = true
            labelState.text = ""
            return
        }

        // Evitar verificar 20 veces si el usuario sigue escribiendo
        if otpVerified { return }

        Task {
            do {
                // Verifica el código (OTP)
                try await SupabaseManager.shared.client.auth.verifyOTP(email: emailForRecovery, token: token, type: .email)

                await MainActor.run {
                    self.otpVerified = true
                    self.viewModify.isHidden = false
                    self.showMessage("")
                }
            } catch {
                await MainActor.run {
                    self.otpVerified = false
                    self.viewModify.isHidden = true
                    self.showMessage(L10n.tr( "incorrect_verification_code"))
                }
            }
        }
    }

    @IBAction func resendCodeClicked(_ sender: Any) {
        let email = emailForRecovery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty else { return }

        otpVerified = false
        viewModify.isHidden = true
        showMessage(L10n.tr("sending_code"))

        Task {
            do {
                try await SupabaseManager.shared.client.auth.signInWithOTP(email: email)

                await MainActor.run {
                    self.showMessage(L10n.tr("code_resent_check_email"))
                }
            } catch {
                await MainActor.run {
                    self.showMessage(L10n.tr("could_not_resend_code"))
                }
            }
        }
    }
    
    @IBAction func saveClicked(_ sender: Any) {
        guard otpVerified else {
            showMessage(L10n.tr("enter_valid_code_first"))
            return
        }

        let pass1 = fieldPassword.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        let pass2 = fieldNewPassword.getText().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !pass1.isEmpty, !pass2.isEmpty else {
            showMessage(L10n.tr("fill_both_passwords"))
            return
        }

        guard pass1 == pass2 else {
            showMessage(L10n.tr("passwords_do_not_match"))
            return
        }

        // (Opcional) regla mínima
        guard pass1.count >= 6 else {
            showMessage(L10n.tr("password_min_6_characters"))
            return
        }

        buttonSave.isEnabled = false
        showMessage(L10n.tr("saving"))

        Task {
            do {
                try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(password: pass1)
                )

                await MainActor.run {
                    self.buttonSave.isEnabled = true
                    
                    let alert = UIAlertController(
                        title: L10n.tr("password_changed"),
                        message: L10n.tr("password_updated_successfully"),
                        preferredStyle: .alert
                    )

                    alert.addAction(UIAlertAction(title: L10n.tr( "accept"), style: .default) { [weak self] _ in
                        guard let self else { return }
                        let login = LoginController(nibName: "LoginController", bundle: nil)
                        self.navigationController?.setViewControllers([login], animated: true)
                    })

                    self.present(alert, animated: true)
                }

            } catch {
                await MainActor.run {
                    self.buttonSave.isEnabled = true
                    self.showMessage(L10n.tr("could_not_update_password"))
                }
            }
        }
    }
    
    @IBAction func backClicked(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
    
}
