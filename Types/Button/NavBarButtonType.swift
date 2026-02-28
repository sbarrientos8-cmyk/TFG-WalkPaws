//
//  ButtonType.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 12/2/26.
//

import UIKit

enum NavBarButtonKind
{
    case logout
    case back
    case plus
}

struct NavBarButtonType
{
    let type: NavBarButtonKind
    let action: (() -> Void)?

    var image: UIImage?
    {
        switch type
        {
        case .logout:
            return UIImage(named: "logout")
        case .back:
            return UIImage(named: "back")
        case .plus:
            return UIImage(named: "plus")
        }
    }
}
