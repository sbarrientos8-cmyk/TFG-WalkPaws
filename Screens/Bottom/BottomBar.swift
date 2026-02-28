//
//  BottomBar.swift
//  WalkPaws
//
//  Created by Sojfia Barrientos Raszkowska on 16/2/26.
//

import UIKit

enum Section {
    case user
    case shelter
    case home
    case news
    case walk
}

struct BottomBarItem {
    let button: UIButton
    let iconName: String
    let makeController: (() -> UIViewController)?
}


class BottomBar: UIView {
    
    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var buttonHome: UIButton!
    @IBOutlet weak var buttonShelter: UIButton!
    @IBOutlet weak var buttonWalk: UIButton!
    @IBOutlet weak var buttonNews: UIButton!
    @IBOutlet weak var buttonUser: UIButton!

    private var items: [BottomBarItem] = []

    private func commonInit() {

        let nib = UINib(nibName: "BottomBar", bundle: .main)
        let objects = nib.instantiate(withOwner: self, options: nil)

        guard let content = objects.first as? UIView else { return }

        content.frame = bounds
        content.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(content)

        configureButtons()
        setupBackground()
    }
    
    private func setupBackground() {
        viewBackground.layer.cornerRadius = 20
        viewBackground.layer.masksToBounds = false

        viewBackground.layer.shadowColor = UIColor.black.cgColor
        viewBackground.layer.shadowOpacity = 0.1
        viewBackground.layer.shadowRadius = 5
        viewBackground.layer.shadowOffset = CGSize(width: 0, height: -4)
    }

    private func configureButtons() {

        items = [
            BottomBarItem(button: buttonHome, iconName: "home_icn", makeController: { HomeController() }),
            BottomBarItem(button: buttonShelter, iconName: "shelter_icn", makeController: { ListShelterController() }),
            BottomBarItem(button: buttonWalk, iconName: "walkDog_icn", makeController: { StartWalkController()}),
            BottomBarItem(button: buttonNews, iconName: "news_icn", makeController: { NewsController() }),
            BottomBarItem(button: buttonUser, iconName: "user_icn", makeController: { ProfileUserController() }),
        ]

        for item in items {
            item.button.setImage(UIImage(named: item.iconName), for: .normal)
            item.button.tintColor = .clear
            item.button.backgroundColor = .clear
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func navigate(to item: BottomBarItem, sectionToSelect: Section?) {

        guard let makeController = item.makeController else { return }

        if let section = sectionToSelect {
            selectSection(section)
        }

        let vc = makeController()

        guard let parent = self.parentViewController else { return }

        if let nav = parent.navigationController {
            nav.pushViewController(vc, animated: false)
        } else {
            parent.present(vc, animated: true)
        }
    }
    
    private func activate(button: UIButton, baseName: String) {

        button.setImage(UIImage(named: "\(baseName)_white"), for: .normal)
        
        button.imageEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)

        // quitar círculo previo si existe
        button.viewWithTag(999)?.removeFromSuperview()

        let circleSize: CGFloat = 44

        let circleView = UIView(frame: CGRect(
            x: (button.bounds.width - circleSize) / 2,
            y: (button.bounds.height - circleSize) / 2,
            width: circleSize,
            height: circleSize
        ))
        circleView.backgroundColor = Colors.greenBottom
        circleView.layer.cornerRadius = circleSize / 2
        circleView.isUserInteractionEnabled = false
        circleView.tag = 999

        button.addSubview(circleView)

        button.sendSubviewToBack(circleView)
        if let img = button.imageView {
            button.bringSubviewToFront(img)
        }
    }
    
    private func resetButtons() {

        for item in items {
            item.button.setImage(UIImage(named: item.iconName), for: .normal)

            if let circle = item.button.viewWithTag(999) {
                circle.removeFromSuperview()
            }
        }
    }
    
    func selectSection(_ section: Section) {
        
        resetButtons()
        
        switch section {
            
        case .user:
            activate(button: buttonUser, baseName: "user_icn")
            
        case .shelter:
            activate(button: buttonShelter, baseName: "shelter_icn")
            
        case .home:
            activate(button: buttonHome, baseName: "home_icn")
            
        case .news:
            activate(button: buttonNews, baseName: "news_icn")
            
        case .walk:
            activate(button: buttonWalk, baseName: "walkDog_icn")
            
        }
        
        
    }
    
    
    //Button Methods
    @IBAction func goHome(_ sender: Any) {
        if let item = items.first(where: { $0.button == buttonHome }) {
                navigate(to: item, sectionToSelect: nil)
            }
    }
    
    @IBAction func goShelter(_ sender: Any) {
        if let item = items.first(where: { $0.button == buttonShelter }) {
                navigate(to: item, sectionToSelect: nil)
            }
    }
    
    @IBAction func goWalk(_ sender: Any) {
        if let item = items.first(where: { $0.button == buttonWalk }) {
                navigate(to: item, sectionToSelect: nil)
            }
    }
    
    @IBAction func goNews(_ sender: Any) {
        if let item = items.first(where: { $0.button == buttonNews }) {
                navigate(to: item, sectionToSelect: nil)
            }
    }
    
    @IBAction func goUser(_ sender: Any) {
        if let item = items.first(where: { $0.button == buttonUser }) {
                navigate(to: item, sectionToSelect: nil)
            }
    }
    
}
