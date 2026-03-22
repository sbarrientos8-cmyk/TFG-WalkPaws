//
//  ForgetPasswordController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 27/1/26.
//

import UIKit
import Supabase

class ForgetPasswordController: UIViewController
{

    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var fieldEmail: LabelField!
    @IBOutlet weak var buttonSendCode: UIButton!
    @IBOutlet weak var labelDescription: UILabel!
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        labelTitle.config(text: String(localized: "recover_password"), style: StylesLabel.title)
        fieldEmail.config(image: UIImage(named: "email"), placeholder: String(localized: "email"))
        buttonSendCode.config(text: String(localized: "send_code"), style: StylesButton.primary)
        buttonSendCode.applyShadow()
        labelDescription.config(text: String(localized: "we_will_send_code_to_reset_password"), style: StylesLabel.subtitle)
        
        hideKeyboardWhenTappedAround()
    }
    
    private func showAlert(_ title: String, _ message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "ok"), style: .default))
        present(alert, animated: true)
    }

    @IBAction func backClicked(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sendCodeClicked(_ sender: Any) {
        let email = fieldEmail.getText()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !email.isEmpty else {
            showAlert(String(localized: "missing_email"), String(localized: "enter_your_email"))
            return
        }

        // (Opcional) valida formato rápido
        guard email.contains("@"), email.contains(".") else {
            showAlert(String(localized: "invalid_email"), String(localized: "enter_valid_email"))
            return
        }

        buttonSendCode.isEnabled = false

        Task {
            do {
                // ENVÍA EL OTP (tu plantilla Magic Link lo mostrará como código)
                try await SupabaseManager.shared.client.auth.signInWithOTP(email: email)

                await MainActor.run {
                    self.buttonSendCode.isEnabled = true

                    // Ir a pantalla de introducir código + nueva contraseña
                    let vc = ModifyPasswordIntroController(nibName: "ModifyPasswordIntroController", bundle: nil)
                    vc.emailForRecovery = email
                    self.navigationController?.pushViewController(vc, animated: true)
                }

            } catch {
                await MainActor.run {
                    self.buttonSendCode.isEnabled = true
                    self.showAlert(
                        String(localized: "error"),
                        "\(String(localized: "could_not_send_code_try_again"))\n\(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
}
