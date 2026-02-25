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

        labelTitle.config(text: "Nueva Contraseña", style: StylesLabel.title)
        fieldCode.config(image: UIImage(named: "code"), placeholder: "Código de verificación")
        fieldPassword.config(image: UIImage(named: "lock"), placeholder: "Nueva contraseña")
        fieldNewPassword.config(image: UIImage(named: "lock"), placeholder: "Confirmar contraseña")
        buttonSave.config(text: "Guardar", style: StylesButton.primary)
        
        labelResendCode.config(text: "¿No recibiste el código? Reenviar código", style: StylesLabel.subtitle)
        
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
                    self.showMessage("El código no es correcto")
                }
            }
        }
    }

    @IBAction func resendCodeClicked(_ sender: Any) {
        let email = emailForRecovery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty else { return }

        otpVerified = false
        viewModify.isHidden = true
        showMessage("Enviando código...")

        Task {
            do {
                try await SupabaseManager.shared.client.auth.signInWithOTP(email: email)

                await MainActor.run {
                    self.showMessage("Código reenviado. Revisa tu correo.")
                }
            } catch {
                await MainActor.run {
                    self.showMessage("No se pudo reenviar el código.")
                }
            }
        }
    }
    
    @IBAction func saveClicked(_ sender: Any) {
        guard otpVerified else {
            showMessage("Primero introduce un código válido.")
            return
        }

        let pass1 = fieldPassword.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        let pass2 = fieldNewPassword.getText().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !pass1.isEmpty, !pass2.isEmpty else {
            showMessage("Rellena ambas contraseñas.")
            return
        }

        guard pass1 == pass2 else {
            showMessage("Las contraseñas no coinciden.")
            return
        }

        // (Opcional) regla mínima
        guard pass1.count >= 6 else {
            showMessage("La contraseña debe tener al menos 6 caracteres.")
            return
        }

        buttonSave.isEnabled = false
        showMessage("Guardando...")

        Task {
            do {
                try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(password: pass1)
                )

                await MainActor.run {
                    self.buttonSave.isEnabled = true
                    Alert.show(on: self, image: UIImage(named: "icn_ok"), title: "Contraseña actualizada") { self.navigationController?.popToRootViewController(animated: true) }
                }

            } catch {
                await MainActor.run {
                    self.buttonSave.isEnabled = true
                    self.showMessage("No se pudo actualizar la contraseña.")
                }
            }
        }
    }
    
    @IBAction func backClicked(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
    
}
