//
//  DogDetailNormalController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 21/2/26.
//

import UIKit
import CoreLocation

class DogDetailNormalController: UIViewController {

    @IBOutlet weak var labelTitleNav: UILabel!
    @IBOutlet weak var imageDog: UIImageView!

    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelCharacter: UILabel!

    
    @IBOutlet weak var viewDescription: UIView!
    @IBOutlet weak var labelDescriptionT: UILabel!
    @IBOutlet weak var labelDescriptionD: UILabel!

    @IBOutlet weak var viewStory: UIView!
    @IBOutlet weak var labelStoryT: UILabel!
    @IBOutlet weak var labelStoryD: UILabel!
    
    @IBOutlet weak var viewBreed: UIView!
    @IBOutlet weak var labelBreed: UILabel!

    @IBOutlet weak var viewAge: UIView!
    @IBOutlet weak var labelAge: UILabel!

    @IBOutlet weak var viewSex: UIView!
    @IBOutlet weak var imageSex: UIImageView!
    @IBOutlet weak var labelSex: UILabel!

    @IBOutlet weak var buttonWalk: UIButton!

    var dog: DogModel!
    var shelterName: String = ""
    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private let maxDistanceMeters: Double = 1000
    private let imageLoadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        labelTitleNav.config(text: L10n.tr("dog_detail"), style: StylesLabel.titleNav)
        
        labelName.config(text: "", style: StylesLabel.title)
        labelCharacter.config(text: "", style: StylesLabel.subtitle)
        
        viewDescription.applyCardStyle()
        labelDescriptionT.config(text: L10n.tr("description"), style: StylesLabel.titleNav)
        labelDescriptionD.config(text: "", style: StylesLabel.description)
        
        viewStory.applyCardStyle()
        labelStoryT.config(text: L10n.tr("story"), style: StylesLabel.titleNav)
        labelStoryD.config(text: "", style: StylesLabel.description)

        viewBreed.applyCardStyle()
        labelBreed.config(text: "", style: StylesLabel.title1)

        viewAge.applyCardStyle()
        labelAge.config(text: "", style: StylesLabel.title1)

        viewSex.applyCardStyle()
        labelSex.config(text: "", style: StylesLabel.title1)

        buttonWalk.config(text: L10n.tr("walk"), style: StylesButton.primary)
        buttonWalk.applyShadow()

        imageDog.contentMode = .scaleAspectFill
        imageDog.layer.cornerRadius = 12
        imageDog.clipsToBounds = true

        setupImageLoadingIndicator()
        fillUI()
        hideKeyboardWhenTappedAround()
        setupLocation()
    }
    
    private func setupImageLoadingIndicator() {
        imageLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        imageLoadingIndicator.hidesWhenStopped = true

        imageDog.addSubview(imageLoadingIndicator)

        NSLayoutConstraint.activate([
            imageLoadingIndicator.centerXAnchor.constraint(equalTo: imageDog.centerXAnchor),
            imageLoadingIndicator.centerYAnchor.constraint(equalTo: imageDog.centerYAnchor)
        ])
    }
    
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default))
        present(alert, animated: true)
    }

    private func fillUI() {
        guard let dog = dog else { return }

        labelName.text = dog.name

        let ageText = dog.age != nil
            ? String(format: L10n.tr("dog_age_years"), String(dog.age!))
            : L10n.tr("unknown_age")

        labelCharacter.text = "\(dog.displayBreed) · \(ageText)"
        labelDescriptionD.text = dog.displayDescription ?? L10n.tr("no_description")

        labelBreed.text = dog.displayBreed
        labelAge.text = ageText
        
        buttonWalk.isHidden = !dog.isWalkable
        buttonWalk.isEnabled = dog.isWalkable

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
            imageDog.image = nil
            imageLoadingIndicator.startAnimating()
            loadImage(from: url)
        } else {
            imageLoadingIndicator.stopAnimating()
            imageDog.image = nil
        }
        
        labelStoryD.text = dog.displayStory
        
        print("LANG:", AppLanguage.current.rawValue)
        print("breed:", dog.breed)
        print("breedEn:", dog.breedEn ?? "nil")
        print("description:", dog.description ?? "nil")
        print("descriptionEn:", dog.descriptionEn ?? "nil")
        print("story:", dog.story ?? "nil")
        print("storyEn:", dog.storyEn ?? "nil")
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.imageLoadingIndicator.stopAnimating()
            }

            guard let data = data, let image = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                self.imageDog.image = image
            }
        }.resume()
    }

    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func walkClicked(_ sender: Any) {

        guard dog.isWalkable else { return }

        guard let dogUUID = UUID(uuidString: dog.id),
              let shelterIdStr = dog.shelterId,
              let shelterUUID = UUID(uuidString: shelterIdStr) else {
            print("❌ IDs inválidos")
            return
        }

        // ✅ BLOQUEO: si ya hay paseo activo, no permitir otro
        if WalkSession.shared.isActive {
            let alert = UIAlertController(
                title: L10n.tr("walk_already_in_progress"),
                message: L10n.tr("finish_current_walk_first"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default))
            present(alert, animated: true)
            return
        }

        Task { [weak self] in
            guard let self else { return }

            // 1) Necesitamos ubicación usuario
            guard let userLoc = self.lastLocation else {
                await MainActor.run {
                    self.showAlert(
                        title: L10n.tr("location_not_available"),
                        message: L10n.tr("enable_location_to_start_walk")
                    )
                }
                return
            }

            do {
                // 2) Traer coordenadas del refugio
                struct ShelterCoordDTO: Decodable {
                    let latitude: Double?
                    let longitude: Double?
                    let name: String?
                }

                let shelter: ShelterCoordDTO = try await SupabaseManager.shared.client
                    .from("shelters")
                    .select("latitude, longitude, name")
                    .eq("id", value: shelterUUID.uuidString)
                    .single()
                    .execute()
                    .value

                guard let lat = shelter.latitude, let lon = shelter.longitude else {
                    await MainActor.run {
                        self.showAlert(
                            title: L10n.tr("shelter_without_location"),
                            message: L10n.tr( "shelter_without_saved_coordinates")
                        )
                    }
                    return
                }

                // 3) Calcular distancia
                let shelterLoc = CLLocation(latitude: lat, longitude: lon)
                let distance = userLoc.distance(from: shelterLoc)

                // 4) Si está lejos, no dejar empezar
                if distance > self.maxDistanceMeters {
                    let km = distance / 1000.0
                    await MainActor.run {
                        self.showAlert(
                            title:L10n.tr("not_near_shelter"),
                            message: String(format: L10n.tr( "distance_too_far_to_start_walk"), km)
                        )
                    }
                    return
                }

                // 5) OK -> abrir WalkingController + activar sesión
                let shelterName = shelter.name ?? L10n.tr("shelter")

                await MainActor.run {
                    WalkSession.shared.start(
                        dogId: dogUUID,
                        shelterId: shelterUUID,
                        dogName: self.dog.name,
                        shelterName: shelterName
                    )

                    let vc = WalkingController(nibName: "WalkingController", bundle: nil)
                    vc.selectedDogId = dogUUID
                    vc.selectedShelterId = shelterUUID
                    vc.selectedDogName = self.dog.name
                    vc.selectedShelterName = shelterName
                    self.navigationController?.pushViewController(vc, animated: true)
                }

            } catch {
                print("❌ check distance / fetch shelter error:", error)
                await MainActor.run {
                    self.showAlert(
                        title: L10n.tr("error"),
                        message: L10n.tr( "could_not_check_shelter_location")
                    )
                }
            }
        }
    }
    
}

extension DogDetailNormalController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error:", error)
    }
}
