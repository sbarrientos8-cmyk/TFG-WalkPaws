//
//  HomeController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 17/2/26.
//

import UIKit

class HomeController: UIViewController,
                      UICollectionViewDataSource,
                      UICollectionViewDelegate,
                      UICollectionViewDelegateFlowLayout
{

    @IBOutlet weak var labelHi: UILabel!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var viewImage: UIView!
    @IBOutlet weak var imageTopWalk: UIImageView!
    
    @IBOutlet weak var labelQuestion: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var buttonWalk: UIButton!
    
    @IBOutlet weak var viewSHelter: UIView!
    @IBOutlet weak var labelShelter: UILabel!
    
    @IBOutlet weak var viewNews: UIView!
    @IBOutlet weak var labelNews: UILabel!
    
    @IBOutlet weak var viewInfo: UIView!
    @IBOutlet weak var labelInfo: UILabel!
    
    @IBOutlet weak var imageMap: UIImageView!
    @IBOutlet weak var viewMap: UIView!
    @IBOutlet weak var labelTitleMap: UILabel!
    @IBOutlet weak var labelDescriptionMap: UILabel!
    @IBOutlet weak var buttonShelter: UIButton!
    
    @IBOutlet weak var labelTitleDogs: UILabel!
    @IBOutlet weak var labelDescriptionDogs: UILabel!
    
    
    @IBOutlet weak var collectionDogs: UICollectionView!
    @IBOutlet weak var bottomBar: BottomBar!
    
    private var dogs: [DogModel] = []
    private let profileService = ProfileService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ HomeController DID APPEAR")
        
        imageTopWalk.layer.cornerRadius = 15
        labelHi.config(text: L10n.tr("hello"), style: StylesLabel.titleHi)
        labelName.config(text: "\(L10n.tr("user")) 👋🏼", style: StylesLabel.titleName)
        viewImage.applyCardStyle()
        
        labelQuestion.config(text: L10n.tr("ready_to_walk"), style: StylesLabel.titleWhite)
        labelDescription.config(text: L10n.tr( "make_a_shelter_dog_happy"), style: StylesLabel.descriptionWhite)
        buttonWalk.config(text: L10n.tr("walk"), style: StylesButton.primary)
        
        viewSHelter.layer.cornerRadius = 12
        viewSHelter.applyCardStyle()
        viewNews.layer.cornerRadius = 12
        viewNews.applyCardStyle()
        viewInfo.layer.cornerRadius = 12
        viewInfo.applyCardStyle()
        
        labelShelter.config(text: L10n.tr("view_shelters"), style: StylesLabel.descriptionGreen)
        labelNews.config(text: L10n.tr("view_news"), style: StylesLabel.descriptionGreen)
        labelInfo.config(text: L10n.tr("contact_walkpaws"), style: StylesLabel.descriptionGreen)
        
        imageMap.layer.cornerRadius = 20
        viewMap.layer.cornerRadius = 20
        
        viewMap.applyCardStyle()
        labelTitleMap.config(text: L10n.tr("find_shelters"), style: StylesLabel.titleMap)
        labelDescriptionMap.config(text: L10n.tr( "explore_dog_shelters_in_your_area"), style: StylesLabel.description)
        buttonShelter.config(text: L10n.tr("view_shelters"), style: StylesButton.primary2)
        
        labelTitleDogs.config(text: L10n.tr("dogs_available_for_walks"), style: StylesLabel.titleHi)
        labelDescriptionDogs.config(text: L10n.tr( "dogs_need_your_company"), style: StylesLabel.subtitleGray)
        labelDescriptionDogs.font = labelDescriptionDogs.font.withSize(17)
        
        collectionDogs.dataSource = self
        collectionDogs.delegate = self
        collectionDogs.isScrollEnabled = false

        let nib = UINib(nibName: "DogCell", bundle: nil)
        collectionDogs.register(nib, forCellWithReuseIdentifier: "DogCell")
        collectionDogs.layer.cornerRadius = 12
        
        bottomBar.selectSection(.home)
        
        navigationItem.hidesBackButton = true
        hideKeyboardWhenTappedAround()
        
        fetchDogs { [weak self] models in
            DispatchQueue.main.async {
                self?.dogs = models
                print("✅ dogs loaded:", models.count)
                self?.collectionDogs.reloadData()
            }
        }
        
        loadMyProfileName()
    }
    
    private func loadMyProfileName() {

        Task { [weak self] in
            guard let self else { return }

            do {
                let session = try await SupabaseManager.shared.client.auth.session

                let email = session.user.email ?? ""
                    if email.isEmpty {
                        await MainActor.run {
                            self.labelName.config(text: "\(L10n.tr( "user")) 👋🏼", style: StylesLabel.titleName)
                    }
                    return
                }

                let dto = try await profileService.fetchMyProfile(email: email)
                let fullName = dto?.name ?? L10n.tr("user")
                let firstName = fullName.components(separatedBy: " ").first ?? fullName

                self.labelName.config(text: "\(firstName) 👋🏼", style: StylesLabel.titleName)

            } catch {
                print("❌ loadMyProfileName error:", error)
                await MainActor.run {
                    self.labelName.config(text: "\(L10n.tr("user")) 👋🏼", style: StylesLabel.titleName)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return min(dogs.count, 4)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let padding: CGFloat = 12
        let totalSpacing = padding * 3 // izquierda + centro + derecha
        
        let width = (collectionView.frame.width - totalSpacing) / 2
        let height = width + 60 // un poco más alto para textos
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let dog = dogs[indexPath.item]

        if dog.isDisabled == true {
            let vc = DogDetailNeedyController(nibName: "DogDetailNeedyController", bundle: nil)
            vc.dog = dog
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = DogDetailNormalController(nibName: "DogDetailNormalController", bundle: nil)
            vc.dog = dog
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "DogCell",
            for: indexPath
        ) as? DogCell else {
            return UICollectionViewCell()
        }

        let dog = dogs[indexPath.item]

        cell.config(with: dog, subtitle: .city)
        print("DOG HOME: \(dog.city)")

        return cell
    }
    
    @IBAction func shelterWidgetClicked(_ sender: Any)
    {
        let vc = ListShelterController(nibName: "ListShelterController", bundle: nil)
            navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func shelterMapClicked(_ sender: Any)
    {
        let vc = ListShelterController(nibName: "ListShelterController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func newsWidgetClicked(_ sender: Any)
    {
        let vc = NewsController(nibName: "NewsController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func infoWidgetClicked(_ sender: Any)
    {
        let vc = ContactShelterController(nibName: "ContactShelterController", bundle: nil)

        // “refugio” fijo = WalkPaws
        vc.shelter = ShelterContactInfo(
            name: "WalkPaws",
            email: "walkpaws@gmail.com",
            photoURL: nil // usaremos logo local
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}
