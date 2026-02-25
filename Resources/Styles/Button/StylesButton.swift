//
//  StylesButton.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/1/26.
//

struct StylesButton {

    static let primary = StyleButton(
        font: Fonts.figtreeMedium(19),
        titleColor: Colors.white,
        backgroundColor: Colors.main,
        cornerRadius: 7,
        borderColor: nil,
        borderWidth: nil
    )
    
    static let primary2 = StyleButton(
        font: Fonts.figtreeMedium(16),
        titleColor: Colors.white,
        backgroundColor: Colors.main,
        cornerRadius: 7,
        borderColor: nil,
        borderWidth: nil
    )

    static let secondary = StyleButton(
        font: Fonts.figtreeRegular(14),
        titleColor: Colors.greenDark,
        backgroundColor: Colors.background,
        cornerRadius: 14,
        borderColor: nil,
        borderWidth: nil
    )
    
    static let secondaryDonate = StyleButton(
        font: Fonts.figtreeRegular(19),
        titleColor: Colors.greenDark,
        backgroundColor: Colors.background,
        cornerRadius: 14,
        borderColor: Colors.main,
        borderWidth: 1
    )
    
    static let secondaryGreen = StyleButton(
        font: Fonts.figtreeMedium(13),
        titleColor: Colors.white,
        backgroundColor: Colors.greenLight,
        cornerRadius: 7,
        borderColor: nil,
        borderWidth: nil
    )
    
    static let secondaryWhite = StyleButton(
        font: Fonts.figtreeMedium(13),
        titleColor: Colors.greenLight,
        backgroundColor: Colors.white,
        cornerRadius: 7,
        borderColor: nil,
        borderWidth: nil
    )

    static let alert = StyleButton(
        font: Fonts.figtreeRegular(14),
        titleColor: Colors.greenDark,
        backgroundColor: Colors.main,
        cornerRadius: 7,
        borderColor: nil,
        borderWidth: nil
    )

    static let alertButton = StyleButton(
        font: Fonts.figtreeRegular(14),
        titleColor: Colors.main,
        backgroundColor: Colors.white,
        cornerRadius: 7,
        borderColor: Colors.main,
        borderWidth: 1
    )
    
    static let edit = StyleButton(
        font: Fonts.figtreeRegular(14),
        titleColor: Colors.gray,
        backgroundColor: Colors.grayLight,
        cornerRadius: 7,
        borderColor: nil,
        borderWidth: nil
    )
}
