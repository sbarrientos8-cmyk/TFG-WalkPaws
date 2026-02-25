//
//  LoginController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 23/1/26.
//

import UIKit
import Supabase

class LoginController: UIViewController
{

    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var fieldEmail: LabelField!
    @IBOutlet weak var fieldPassword: LabelField!
    @IBOutlet weak var labelForgetPassword: UILabel!
    
    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var buttonRegister: UIButton!
    @IBOutlet weak var labelRegister: UILabel!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        labelTitle.config(text: "Iniciar Sesión", style: StylesLabel.title)
        
        fieldEmail.setText("sofybr29@gmail.com")
        fieldPassword.setText("holahola")
        
        fieldEmail.config(image: UIImage(named: "email"), placeholder: "Correo electrónico")
        fieldPassword.config(image: UIImage(named: "lock"), placeholder: "Contraseña", isSecure: true)
        labelForgetPassword.config(text: "He olvidado mi contraseña", style: StylesLabel.subtitle)
         
        buttonLogin.config(text: "Iniciar Sesión", style: StylesButton.primary)
        buttonLogin.applyShadow()
        labelRegister.config(text: "¿No tienes cuenta? Registrate", style: StylesLabel.subtitle)
        
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @IBAction func registerClicked(_ sender: Any)
    {
        let registerVC = RegisterController(nibName: "RegisterController", bundle: nil)
        navigationController?.pushViewController(registerVC, animated: true)
        
    }
    
    @IBAction func loginClicked(_ sender: Any)
    {
        let email = fieldEmail.getText()
        let password = fieldPassword.getText()

        Task {
            do {
                try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
                
                await MainActor.run
                {
                    let listVC = HomeController(nibName: "HomeController", bundle: nil)
                    self.navigationController?.pushViewController(listVC, animated: true)
                }
            } catch
            {
                await MainActor.run { print("ERROR AL LOGIN") }
            }
        }
    }
    
    @IBAction func forgetPasswordClicked(_ sender: Any)
    {
        let forgetPasswordVC = ForgetPasswordController(nibName: "ForgetPasswordController", bundle: nil)
        navigationController?.pushViewController(forgetPasswordVC, animated: true)
    }
    
}
