//
//  Label.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/1/26.
//

import UIKit

extension UILabel
{
    func config(text: String?, style: StyleLabel)
    {
        self.text = text
        self.font = style.font
        self.textColor = style.color
    }
}
