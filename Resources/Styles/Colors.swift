//
//  Colors.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/1/26.
//

import UIKit

class Colors
{
    static let main = color(36, 76, 57)
    static let second = color(220, 226, 216)
    
    static let background = color(249, 248, 244)
    static let greenDark = color(46, 59, 49)
    static let greenField = color(98, 108, 97)
    static let greenLight = color(124, 146, 125)
    static let greenBottom = color(109, 154, 86)
    static let white = color(255, 255, 255)
    static let borderField = color(220, 222, 210)
    static let textField = color(138, 144, 134)
    static let blue = color(64, 181, 214)
    static let black = color(0, 0, 0)
    
    static let grayLight = color(242, 241, 239)
    static let gray = color(120, 120, 120)
    
    static let flesh = color(244, 222, 199)
    
    static let brown = color(118, 93, 63)
    
    static func color(_ red: Int, _ green: Int, _ blue: Int) -> UIColor
    {
        UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
}
