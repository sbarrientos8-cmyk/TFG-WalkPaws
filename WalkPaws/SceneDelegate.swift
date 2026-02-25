//
//  SceneDelegate.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 23/1/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let loginVC = LoginController(nibName: "LoginController", bundle: nil)
        let nav = UINavigationController(rootViewController: loginVC)

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }
}
