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

        labelTitle.config(text: L10n.tr("sign_up"), style: StylesLabel.title)
        
        fieldEmail.config(image: UIImage(named: "email"), placeholder: L10n.tr("email"))
        fieldName.config(image: UIImage(named: "user"), placeholder: L10n.tr("full_name"))
        fieldPassword.config(image: UIImage(named: "lock"), placeholder: L10n.tr("password"))
        fieldPasswordConfirm.config(image: UIImage(named: "lock"), placeholder: L10n.tr("confirm_password"))
        
        buttonRegister.config(text: L10n.tr("sign_up"), style: StylesButton.primary)
        buttonRegister.applyShadow()
        
        hideKeyboardWhenTappedAround()
    }
    
    func showAlert(title: String, message: String, onOk: (() -> Void)? = nil)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default) { _ in onOk?() })
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
            showAlert(title: L10n.tr("error"), message: L10n.tr( "fill_all_fields"))
            return
        }

        guard password == confirm else
        {
            showAlert(title: L10n.tr("error"), message: L10n.tr( "passwords_do_not_match"))
            return
        }

        guard password.count >= 6 else
        {
            showAlert(title: L10n.tr("error"), message: L10n.tr( "password_min_6_characters"))
            return
        }

        Task {
            do {
                let authResponse = try await SupabaseManager.shared.client.auth
                    .signUp(email: email, password: password, data: ["name": .string(name)])

                // ✅ id NO es optional
                let userId = authResponse.user.id

                let row = ProfileInsert(
                    id: userId.uuidString,
                    name: name,
                    email: email,
                    points: 0,
                    avatar_url: nil
                )

                _ = try await SupabaseManager.shared.client
                    .from("profiles")
                    .upsert(row)
                    .execute()

                await MainActor.run {
                    let home = HomeController(nibName: "HomeController", bundle: nil)
                    self.navigationController?.setViewControllers([home], animated: true)
                }

            } catch {
                await MainActor.run {
                    self.showAlert(title: L10n.tr("error"), message: error.localizedDescription)
                }
            }
        }
    }
    
}
