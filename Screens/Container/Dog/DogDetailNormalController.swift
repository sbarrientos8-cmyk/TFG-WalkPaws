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
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        labelTitleNav.config(text: "Detalle del Perro", style: StylesLabel.titleNav)
        
        labelName.config(text: "", style: StylesLabel.title)
        labelCharacter.config(text: "", style: StylesLabel.subtitle)
        
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

        buttonWalk.config(text: "Pasear", style: StylesButton.primary)
        buttonWalk.applyShadow()

        imageDog.contentMode = .scaleAspectFill
        imageDog.layer.cornerRadius = 12
        imageDog.clipsToBounds = true

        fillUI()
        hideKeyboardWhenTappedAround()
        setupLocation()
    }
    
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func fillUI() {
        guard let dog = dog else { return }

        labelName.text = dog.name

        let ageText = dog.age != nil ? "\(dog.age!) años" : "Edad desconocida"
        labelCharacter.text = "\(dog.breed) · \(ageText)"

        labelDescriptionD.text = dog.description ?? "Sin descripción"

        labelBreed.text = "\(dog.breed)"
        labelAge.text = "\(ageText)"
        
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
            loadImage(from: url)
        } else {
            imageDog.image = UIImage(systemName: "dog")
        }
        
        labelStoryD.text = dog.story
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
                title: "Ya tienes un paseo en curso",
                message: "No puedes empezar otro paseo hasta que termines el actual.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        Task { [weak self] in
            guard let self else { return }

            // 1) Necesitamos ubicación usuario
            guard let userLoc = self.lastLocation else {
                await MainActor.run {
                    self.showAlert(
                        title: "Ubicación no disponible",
                        message: "Activa la ubicación para empezar el paseo."
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
                            title: "Refugio sin ubicación",
                            message: "Este refugio no tiene coordenadas guardadas."
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
                            title: "No estás cerca del refugio",
                            message: String(format: "Estás a %.2f km. Acércate un poco más (≈ 1 km) para empezar el paseo.", km)
                        )
                    }
                    return
                }

                // 5) OK -> abrir WalkingController + activar sesión
                let shelterName = shelter.name ?? "Refugio"

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
                    self.showAlert(title: "Error", message: "No se pudo comprobar la ubicación del refugio.")
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
