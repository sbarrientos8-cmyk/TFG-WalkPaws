//
//  ProfileSection.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 12/2/26.
//

import UIKit

struct ProfileSection
{
    let title: String
    let image: String
    let goSection: () -> UIViewController
    
    static let myWalks = ProfileSection(
            title: "Mis paseos",
            image: "footprint1",
            goSection: {
                return HomeController()
            }
        )

        static let myPosts = ProfileSection(
            title: "Mis publicaciones",
            image: "news_icn",
            goSection: {
                return MyNewsController()
            }
        )

        static let changeLanguage = ProfileSection(
            title: "Cambiar idioma",
            image: "language",
            goSection: {
                return HomeController()
            }
        )

        static let contact = ProfileSection(
            title: "Contactar con nosotros",
            image: "contact1",
            goSection: {
                return HomeController()
            }
        )
}
