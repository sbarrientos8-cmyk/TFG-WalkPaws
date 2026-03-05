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

        let routerVC = RouterController()
        routerVC.view.backgroundColor = .systemBackground  // ✅

        let nav = UINavigationController(rootViewController: routerVC)
        nav.view.backgroundColor = .systemBackground       // ✅

        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = .systemBackground        // ✅ MUY IMPORTANTE
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
    }
}
