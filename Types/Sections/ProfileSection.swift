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

    static var myWalks: ProfileSection {
        ProfileSection(
            title: L10n.tr("my_walks"),
            image: "footprint1",
            goSection: {
                MyWalksController()
            }
        )
    }

    static var myPosts: ProfileSection {
        ProfileSection(
            title: L10n.tr("my_posts"),
            image: "news_icn",
            goSection: {
                MyNewsController()
            }
        )
    }

    static var changeLanguage: ProfileSection {
        ProfileSection(
            title: L10n.tr("change_language"),
            image: "language",
            goSection: {
                ChangeLanguageController(nibName: "ChangeLanguageController", bundle: nil)
            }
        )
    }

    static var contact: ProfileSection {
        ProfileSection(
            title: L10n.tr("contact_us"),
            image: "contact1",
            goSection: {
                let vc = ContactShelterController(nibName: "ContactShelterController", bundle: nil)
                vc.shelter = ShelterContactInfo(
                    name: "WalkPaws",
                    email: "walkpaws@gmail.com",
                    photoURL: nil
                )
                return vc
            }
        )
    }
}
