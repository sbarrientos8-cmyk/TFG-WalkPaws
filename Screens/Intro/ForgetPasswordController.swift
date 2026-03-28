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

        labelTitle.config(text: L10n.tr("recover_password"), style: StylesLabel.title)
        fieldEmail.config(image: UIImage(named: "email"), placeholder: L10n.tr("email"))
        buttonSendCode.config(text: L10n.tr("send_code"), style: StylesButton.primary)
        buttonSendCode.applyShadow()
        labelDescription.config(text: L10n.tr( "we_will_send_code_to_reset_password"), style: StylesLabel.subtitle)
        
        hideKeyboardWhenTappedAround()
    }
    
    private func showAlert(_ title: String, _ message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default))
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
            showAlert(L10n.tr("missing_email"), L10n.tr( "enter_your_email"))
            return
        }

        // (Opcional) valida formato rápido
        guard email.contains("@"), email.contains(".") else {
            showAlert(L10n.tr("invalid_email"), L10n.tr( "enter_valid_email"))
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
                        L10n.tr("error"),
                        "\(L10n.tr( "could_not_send_code_try_again"))\n\(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
}
