//
//  RegisterController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 26/1/26.
//

import UIKit

class RegisterController: UIViewController
{

    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var fieldEmail: LabelField!
    @IBOutlet weak var fieldName: LabelField!
    @IBOutlet weak var fieldPassword: LabelField!
    @IBOutlet weak var fieldPasswordConfirm: LabelField!
    @IBOutlet weak var buttonRegister: UIButton!
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        labelTitle.config(text: "Registrarse", style: StylesLabel.title)
        
        fieldEmail.config(image: UIImage(named: "email"), placeholder: "Correo electrónico")
        fieldName.config(image: UIImage(named: "user"), placeholder: "Nombre completo")
        fieldPassword.config(image: UIImage(named: "lock"), placeholder: "Contraseña")
        fieldPasswordConfirm.config(image: UIImage(named: "lock"), placeholder: "Confirmar Contraseña")
        
        buttonRegister.config(text: "Registrarse", style: StylesButton.primary)
        buttonRegister.applyShadow()
        
        hideKeyboardWhenTappedAround()
    }
    
    func showAlert(title: String, message: String, onOk: (() -> Void)? = nil)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in onOk?() })
        present(alert, animated: true)
    }
    
    @IBAction func backClicked(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
    

    @IBAction func registerClicked(_ sender: Any)
    {
        let email = fieldEmail.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        let name = fieldName.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        let password = fieldPassword.getText()
        let confirm = fieldPasswordConfirm.getText()

        guard !email.isEmpty, !name.isEmpty, !password.isEmpty, !confirm.isEmpty else
        {
            showAlert(title: "Error", message: "Rellena todos los campos.")
            return
        }

        guard password == confirm else
        {
            showAlert(title: "Error", message: "Las contraseñas no coinciden.")
            return
        }

        guard password.count >= 6 else
        {
            showAlert(title: "Error", message: "La contraseña debe tener al menos 6 caracteres.")
            return
        }

        Task {
            do {
                try await SupabaseManager.shared.client.auth.signUp(email: email, password: password, data: [ "name": .string(name)])

                await MainActor.run
                {
                    // TODO ir al HomeController
                }

            } catch {
                await MainActor.run
                {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
}
