//
//  DogDetailNeedyController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 22/2/26.
//

import UIKit
import Helpers
import CoreLocation

class DogDetailNeedyController: UIViewController {

    @IBOutlet weak var labelTitleNav: UILabel!
    
    @IBOutlet weak var imageDog: UIImageView!
    
    @IBOutlet weak var viewNeedy: UIView!
    @IBOutlet weak var labelTitleNeedy: UILabel!
    
    @IBOutlet weak var viewDonateComplete: UIView!
    @IBOutlet weak var labelDonateComplete: UILabel!
    
    
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
        
        viewDonateComplete.applyCardStyle()
        viewDonateComplete.backgroundColor = Colors.yellow.withAlphaComponent(0.6)
        labelDonateComplete.config(text: "Se ha completado la donación!!!", style: StylesLabel.donationComplete)
        
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
        
        hideKeyboardWhenTappedAround()
        fillUI()
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
    
    private func reloadDogAndRefreshUI() async {
        guard let dogUUID = UUID(uuidString: dog.id) else { return }

        do {
            // OJO: ajusta el select a las columnas de tu DogRowDTO
            let dto: DogRowDTO = try await SupabaseManager.shared.client
                .from("dogs")
                .select("*")
                .eq("id", value: dogUUID.uuidString)
                .single()
                .execute()
                .value

            let updated = DogModel(dto: dto)

            await MainActor.run {
                self.dog = updated
                self.fillUI()
            }

        } catch {
            print("❌ reloadDogAndRefreshUI error:", error)
        }
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
        
        let goal = dog.donationGoalEur ?? 0
        let raised = dog.donationRaisedEur
        let rest = max(goal - raised, 0)
        
        let isDonationCompleted = goal > 0 && rest <= 0.0001
        viewDonateComplete.isHidden = !isDonationCompleted
        
        buttonDonate.isEnabled = !isDonationCompleted
        buttonDonate.isHidden = isDonationCompleted   // si prefieres ocultarlo del todo
        buttonDonate.alpha = isDonationCompleted ? 0.5 : 1.0

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
    
    
    @IBAction func donateClicked(_ sender: Any) {
        let goal = dog.donationGoalEur ?? 0
        let raised = dog.donationRaisedEur
        let rest = max(goal - raised, 0)

        // ✅ si ya no queda nada, no abrir
        guard rest > 0.0001 else {
            let alert = UIAlertController(
                title: "Donación completada",
                message: "Este perro ya ha alcanzado su objetivo. ¡Gracias!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let vc = DonateController(nibName: "DonateController", bundle: nil)
        vc.dogId = dog.id

        // ✅ pásale cuánto queda (en euros)
        vc.maxDonationEur = rest

        vc.onDonationSuccess = { [weak self] in
            guard let self else { return }
            Task { await self.reloadDogAndRefreshUI() }
        }

        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.largestUndimmedDetentIdentifier = .medium
        }

        present(vc, animated: true)
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

extension DogDetailNeedyController: CLLocationManagerDelegate {
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
