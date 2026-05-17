//
//  RouterController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 4/3/26.
//

import UIKit

final class RouterController: UIViewController {

    private var didRoute = false
    private var listener: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Entrar funcion router")
        Task { [weak self] in
            guard let self else { return }

            self.listener = await SupabaseManager.shared.client.auth.onAuthStateChange { [weak self] event, session in
                guard let self else { return }

                Task { @MainActor in
                    guard !self.didRoute else { return }
                    self.didRoute = true

                    if let session, !session.isExpired {
                        self.goHome()
                        print("✅ SESSION OK:", session.user.id)
                    } else {
                        self.goLogin()
                        print("✅ NO SESSION")
                    }
                }
            }
        }
    }

    @MainActor private func goHome() {
        let home = HomeController(nibName: "HomeController", bundle: nil)
        navigationController?.setViewControllers([home], animated: false)
    }

    @MainActor private func goLogin() {
        let login = LoginController(nibName: "LoginController", bundle: nil)
        navigationController?.setViewControllers([login], animated: false)
    }
}
