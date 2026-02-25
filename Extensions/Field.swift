//
//  Field.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/1/26.
//

import UIKit

extension UIViewController
{
    func hideKeyboardWhenTappedAround()
    {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard()
    {
        view.endEditing(true)
    }
}
