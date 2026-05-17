//
//  ChangeLanguageController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 28/3/26.
//

import UIKit

class ChangeLanguageController: UIViewController {
    
    @IBOutlet weak var labelTitleNav: UILabel!
    
    @IBOutlet weak var viewSpain: UIView!
    @IBOutlet weak var switchSpain: UISwitch!
    @IBOutlet weak var labelSpain: UILabel!
    
    @IBOutlet weak var viewEnglish: UIView!
    @IBOutlet weak var switchEnglish: UISwitch!
    @IBOutlet weak var labelEnglish: UILabel!
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        viewSpain.applyCardStyle()
        viewEnglish.applyCardStyle()

        hideKeyboardWhenTappedAround()
        updateTexts()
        updateSelection()
    }
    
    private func updateTexts() {
        labelTitleNav.config(text: L10n.tr("change_language"), style: StylesLabel.titleNav)
        labelSpain.config(text: L10n.tr("spanish"), style: StylesLabel.subtitle)
        labelEnglish.config(text: L10n.tr("english"), style: StylesLabel.subtitle)
    }
    
    private func updateSelection() {
        let current = AppLanguage.current
        switchSpain.setOn(current == .es, animated: false)
        switchEnglish.setOn(current == .en, animated: false)
    }
    
    private func applyLanguage(_ language: AppLanguage) {
        AppLanguage.set(language)
        updateTexts()
        updateSelection()
    }
    
    @IBAction func changeSpain(_ sender: Any) {
        applyLanguage(.es)
    }
    
    @IBAction func changeEnglish(_ sender: Any) {
        applyLanguage(.en)
    }
    
    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
