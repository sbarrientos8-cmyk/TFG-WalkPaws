//
//  DogDetailNeedyController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 22/2/26.
//

import UIKit

class DogDetailNeedyController: UIViewController {

    @IBOutlet weak var labelTitleNav: UILabel!
    
    @IBOutlet weak var imageDog: UIImageView!
    
    @IBOutlet weak var viewNeedy: UIView!
    @IBOutlet weak var labelTitleNeedy: UILabel!
    
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelCharacter: UILabel!
    
    @IBOutlet weak var viewCollect: UIView!
    @IBOutlet weak var labelNeeds: UILabel!
    
    @IBOutlet weak var progressCollect: UIProgressView!
    @IBOutlet weak var labelCollected: UILabel!
    @IBOutlet weak var labelRest: UILabel!
    
    @IBOutlet weak var viewDescription: UIView!
    @IBOutlet weak var labelDescriptionT: UILabel!
    @IBOutlet weak var labelDescriptionD: UILabel!
    
    @IBOutlet weak var viewBreed: UIView!
    @IBOutlet weak var labelBreed: UILabel!
    
    @IBOutlet weak var viewAge: UIView!
    @IBOutlet weak var labelAge: UILabel!
    
    @IBOutlet weak var viewSex: UIView!
    @IBOutlet weak var imageSex: UIImageView!
    @IBOutlet weak var labelSex: UILabel!
    
    @IBOutlet weak var viewStory: UIView!
    @IBOutlet weak var labelStoryT: UILabel!
    @IBOutlet weak var labelStoryD: UILabel!
    
    @IBOutlet weak var buttonDonate: UIButton!
    @IBOutlet weak var buttonWalk: UIButton!

    var dog: DogModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        labelTitleNav.config(text: "Detalle del Perro", style: StylesLabel.titleNav)
        
        viewNeedy.layer.cornerRadius = 20
        viewNeedy.backgroundColor = Colors.flesh
        labelTitleNeedy.config(text: "Necesita apoyo", style: StylesLabel.descriptionBrown)
        
        labelName.config(text: "", style: StylesLabel.title)
        labelCharacter.config(text: "", style: StylesLabel.subtitle)
        
        viewCollect.backgroundColor = Colors.flesh
        viewCollect.applyCardStyle()
        labelNeeds.config(text: "", style: StylesLabel.descriptionBrown)
        
        progressCollect.progressTintColor = Colors.main
        progressCollect.trackTintColor = Colors.flesh
        labelCollected.config(text: "", style: StylesLabel.title1)
        labelRest.config(text: "", style: StylesLabel.title1)
        labelRest.alpha = 0.6
        
        viewDescription.applyCardStyle()
        labelDescriptionT.config(text: "Descripción", style: StylesLabel.titleNav)
        labelDescriptionD.config(text: "", style: StylesLabel.description)
        
        viewStory.applyCardStyle()
        labelStoryT.config(text: "Historia", style: StylesLabel.titleNav)
        labelStoryD.config(text: "", style: StylesLabel.description)

        viewBreed.applyCardStyle()
        labelBreed.config(text: "", style: StylesLabel.title1)

        viewAge.applyCardStyle()
        labelAge.config(text: "", style: StylesLabel.title1)

        viewSex.applyCardStyle()
        labelSex.config(text: "", style: StylesLabel.title1)

        buttonDonate.config(text: "Donar", style: StylesButton.secondaryDonate)
        buttonDonate.applyShadow()
        buttonWalk.config(text: "Pasear", style: StylesButton.primary)
        buttonWalk.applyShadow()

        imageDog.contentMode = .scaleAspectFill
        imageDog.layer.cornerRadius = 12
        imageDog.clipsToBounds = true
        
        fillUI()
    }

    private func fillUI() {
        guard let dog = dog else { return }

        labelName.text = dog.name

        let ageText = dog.age != nil ? "\(dog.age!) años" : "Edad desconocida"
        labelCharacter.text = "\(dog.breed) · \(ageText)"

        labelDescriptionD.text = dog.description ?? "Sin descripción"

        labelBreed.text = "\(dog.breed)"
        labelAge.text = "\(ageText)"

        let sexText = dog.sexDisplayText // te lo pongo abajo
        labelSex.text = "\(sexText)"
        if let sex = dog.sex?.lowercased() {
            switch sex {
            case "male":
                imageSex.image = UIImage(named: "male")
            case "female":
                imageSex.image = UIImage(named: "female")
            default:
                imageSex.image = UIImage(named: "unknown") // opcional
            }
        }

        if let urlString = dog.photoURL, let url = URL(string: urlString) {
            loadImage(from: url)
        } else {
            imageDog.image = UIImage(systemName: "dog")
        }
        
        labelStoryD.text = dog.story
        
        let goal = dog.donationGoalEur ?? 0
        let raised = dog.donationRaisedEur
        let rest = max(goal - raised, 0)

        // Progreso (0...1)
        let progress: Float = goal > 0 ? Float(min(raised / goal, 1)) : 0
        progressCollect.progress = progress

        // Texto (formato €)
        let raisedText = String(format: "%.0f€", raised)
        let restText = String(format: "%.0f€", rest)

        labelNeeds.text = (dog.disability_diagnosis?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        ? dog.disability_diagnosis
        : "Sin diagnóstico"
        labelCollected.text = "Recaudado: \(raisedText)"
        labelRest.text = "Faltan: \(restText)"
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.imageDog.image = image
            }
        }.resume()
    }
    
    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
