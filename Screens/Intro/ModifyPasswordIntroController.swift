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

        labelTitle.config(text: String(localized: "new_password"), style: StylesLabel.title)
        fieldCode.config(image: UIImage(named: "code"), placeholder: String(localized: "verification_code"))
        fieldPassword.config(image: UIImage(named: "lock"), placeholder: String(localized: "new_password"))
        fieldNewPassword.config(image: UIImage(named: "lock"), placeholder: String(localized: "confirm_password"))
        buttonSave.config(text: String(localized: "save"), style: StylesButton.primary)
        
        labelResendCode.config(text: String(localized: "didnt_receive_code_resend_code"), style: StylesLabel.subtitle)
        
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
                    self.showMessage(String(localized: "incorrect_verification_code"))
                }
            }
        }
    }

    @IBAction func resendCodeClicked(_ sender: Any) {
        let email = emailForRecovery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty else { return }

        otpVerified = false
        viewModify.isHidden = true
        showMessage(String(localized: "sending_code"))

        Task {
            do {
                try await SupabaseManager.shared.client.auth.signInWithOTP(email: email)

                await MainActor.run {
                    self.showMessage(String(localized: "code_resent_check_email"))
                }
            } catch {
                await MainActor.run {
                    self.showMessage(String(localized: "could_not_resend_code"))
                }
            }
        }
    }
    
    @IBAction func saveClicked(_ sender: Any) {
        guard otpVerified else {
            showMessage(String(localized: "enter_valid_code_first"))
            return
        }

        let pass1 = fieldPassword.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        let pass2 = fieldNewPassword.getText().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !pass1.isEmpty, !pass2.isEmpty else {
            showMessage(String(localized: "fill_both_passwords"))
            return
        }

        guard pass1 == pass2 else {
            showMessage(String(localized: "passwords_do_not_match"))
            return
        }

        // (Opcional) regla mínima
        guard pass1.count >= 6 else {
            showMessage(String(localized: "password_min_6_characters"))
            return
        }

        buttonSave.isEnabled = false
        showMessage(String(localized: "saving"))

        Task {
            do {
                try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(password: pass1)
                )

                await MainActor.run {
                    self.buttonSave.isEnabled = true
                    
                    let alert = UIAlertController(
                        title: String(localized: "password_changed"),
                        message: String(localized: "password_updated_successfully"),
                        preferredStyle: .alert
                    )

                    alert.addAction(UIAlertAction(title: String(localized: "accept"), style: .default) { [weak self] _ in
                        guard let self else { return }
                        let login = LoginController(nibName: "LoginController", bundle: nil)
                        self.navigationController?.setViewControllers([login], animated: true)
                    })

                    self.present(alert, animated: true)
                }

            } catch {
                await MainActor.run {
                    self.buttonSave.isEnabled = true
                    self.showMessage(String(localized: "could_not_update_password"))
                }
            }
        }
    }
    
    @IBAction func backClicked(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
    
}
