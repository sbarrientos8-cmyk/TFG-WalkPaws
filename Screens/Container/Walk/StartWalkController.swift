//
//  StartWalkController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 27/2/26.
//

import UIKit
import CoreImage
import CoreLocation
import CoreImage.CIFilterBuiltins

class StartWalkController: UIViewController {

    @IBOutlet weak var imageBackground: UIImageView!
    @IBOutlet weak var viewForm: UIView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelShelter: UILabel!
    @IBOutlet weak var labelDog: UILabel!
    @IBOutlet weak var fieldShelter: DropdownFieldView!
    @IBOutlet weak var fieldDog: DropdownFieldView!
    @IBOutlet weak var buttonWalk: UIButton!
    @IBOutlet weak var bottomBar: BottomBar!
    
    private var dogs: [String] = []
    private var allDogs: [DogModel] = []

    private var shelters: [(id: String, name: String)] = []
    private var dogsForSelectedShelter: [DogModel] = []

    private var selectedShelterId: String? = nil
    private var selectedDogId: String? = nil
    
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private let maxDistanceMeters: Double = 1000
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func blurImageView(_ imageView: UIImageView, radius: Double) {
        guard let uiImage = imageView.image else { return }

        let context = CIContext()
        guard let ciInput = CIImage(image: uiImage) else { return }

        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciInput
        filter.radius = Float(radius)

        guard let ciOutput = filter.outputImage else { return }

        // Importante: el blur “agranda” la imagen, recortamos al tamaño original
        let rect = ciInput.extent
        guard let cgImage = context.createCGImage(ciOutput, from: rect) else { return }

        imageView.image = UIImage(cgImage: cgImage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewForm.layer.cornerRadius = 12
        viewForm.applyCardStyle()
        
        labelTitle.config(text: String(localized: "walk_details_title"), style: StylesLabel.title2Name)
        labelShelter.config(text: String(localized: "shelter"), style: StylesLabel.subtitle)
        labelDog.config(text: String(localized: "dog"), style: StylesLabel.subtitle)
        buttonWalk.config(text: String(localized: "start_walk"), style: StylesButton.primary)
        
        //blurImageView(imageBackground, radius: 15.0) // menos blur
        let darkOverlay = UIView(frame: imageBackground.bounds)
        darkOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.1) // prueba 0.12 - 0.30
        darkOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageBackground.addSubview(darkOverlay)
        
        
        fieldShelter.config(imageName: "shelter_icn", placeholder: String(localized: "select_shelter"))
        fieldDog.config(imageName: "footprint1", placeholder: String(localized: "select_dog"))

        fieldDog.setItems([])

        fieldShelter.onSelect = { [weak self] shelterName in
            guard let self else { return }

            self.selectedShelterId = self.shelters.first(where: { $0.name == shelterName })?.id
            self.selectedDogId = nil

            self.fieldDog.setText("")
            self.fieldDog.setItems([])

            guard let sid = self.selectedShelterId else { return }

            self.dogsForSelectedShelter = self.allDogs.filter { $0.shelterId == sid }
            self.fieldDog.setItems(self.dogsForSelectedShelter.map { $0.name })
        }

        fieldDog.onSelect = { [weak self] dogName in
            guard let self else { return }
            self.selectedDogId = self.dogsForSelectedShelter.first(where: { $0.name == dogName })?.id
            print("🐶 Seleccionado:", dogName)
        }
        
        bottomBar.selectSection(.walk)
        
        setupLocation()
        loadSheltersWithDogs()
        hideKeyboardWhenTappedAround()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    @IBAction func startWalkClicked(_ sender: Any) {
        let shelterName = fieldShelter.getText()
        let dogName = fieldDog.getText()

        guard let shelterIdString = selectedShelterId,
              let dogIdString = selectedDogId,
              let shelterUUID = UUID(uuidString: shelterIdString),
              let dogUUID = UUID(uuidString: dogIdString),
              !shelterName.isEmpty,
              !dogName.isEmpty else {
            showAlert(
                title: String(localized: "missing_data"),
                message: String(localized: "select_shelter_and_dog")
            )
            return
        }

        Task { [weak self] in
            guard let self else { return }

            // 1) Necesitamos ubicación usuario
            guard let userLoc = self.lastLocation else {
                await MainActor.run {
                    self.showAlert(
                        title: String(localized: "location_not_available"),
                        message: String(localized: "enable_location_to_start_walk")
                    )
                }
                return
            }

            do {
                // 2) Traer coordenadas del refugio
                struct ShelterCoordDTO: Decodable {
                    let latitude: Double?
                    let longitude: Double?
                }

                let shelter: ShelterCoordDTO = try await SupabaseManager.shared.client
                    .from("shelters")
                    .select("latitude, longitude")
                    .eq("id", value: shelterUUID.uuidString)
                    .single()
                    .execute()
                    .value

                guard let lat = shelter.latitude, let lon = shelter.longitude else {
                    await MainActor.run {
                        self.showAlert(
                            title: String(localized: "shelter_without_location"),
                            message: String(localized: "shelter_without_saved_coordinates")
                        )
                    }
                    return
                }

                // 3) Calcular distancia
                let shelterLoc = CLLocation(latitude: lat, longitude: lon)
                let distance = userLoc.distance(from: shelterLoc) // metros

                // 4) Si está lejos, no dejar empezar
                if distance > self.maxDistanceMeters {
                    let km = distance / 1000.0
                    await MainActor.run {
                        self.showAlert(
                            title: String(localized: "not_near_shelter"),
                            message: String(format: String(localized: "distance_too_far_to_start_walk"), km)
                        )
                    }
                    return
                }

                // 5) OK -> empezar paseo
                await MainActor.run {
                    let vc = WalkingController(nibName: nil, bundle: nil)
                    vc.selectedShelterName = shelterName
                    vc.selectedDogName = dogName
                    vc.selectedShelterId = shelterUUID
                    vc.selectedDogId = dogUUID

                    WalkSession.shared.start(
                        dogId: dogUUID,
                        shelterId: shelterUUID,
                        dogName: dogName,
                        shelterName: shelterName
                    )

                    self.navigationController?.pushViewController(vc, animated: true)
                }

            } catch {
                print("❌ fetch shelter coords error:", error)
                await MainActor.run {
                    self.showAlert(
                        title: String(localized: "error"),
                        message: String(localized: "could_not_check_shelter_location")
                    )
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "ok"), style: .default))
        present(alert, animated: true)
    }
    
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func loadSheltersWithDogs() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let rows: [DogRowDTO] = try await SupabaseManager.shared.client
                    .from("dogs_with_shelter")
                    .select("*")
                    .execute()
                    .value

                let models = rows.map { DogModel(dto: $0) }

                // Si quieres filtrar “paseables”, aquí pondrías condición,
                // pero ahora mismo en tu DTO no hay campo de disponibilidad.
                // Ejemplo: models.filter { $0.isDisabled == false } (si quisieras)
                self.allDogs = models

                // Refugios únicos desde dogs
                var dict: [String: String] = [:] // shelter_id -> shelter_name
                for d in models {
                    if let sid = d.shelterId, !sid.isEmpty {
                        dict[sid] = d.city.isEmpty ? (rows.first(where: { $0.shelter_id == sid })?.shelter_name ?? String(localized: "shelter")) : (rows.first(where: { $0.shelter_id == sid })?.shelter_name ?? String(localized: "shelter"))
                        // Realmente lo importante es shelter_name:
                        // pero DogModel no guarda shelter_name, solo city.
                    }
                }

                // Mejor: sacarlo directamente de los DTO
                var dict2: [String: String] = [:]
                for r in rows {
                    dict2[r.shelter_id] = r.shelter_name ?? String(localized: "shelter")
                }

                let list = dict2.map { (id: $0.key, name: $0.value) }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

                await MainActor.run {
                    self.shelters = list
                    self.fieldShelter.setItems(list.map { $0.name })
                    self.fieldShelter.setText("")
                    self.fieldDog.setItems([])
                    self.fieldDog.setText("")
                }

            } catch {
                print("❌ loadSheltersWithDogs error:", error)
            }
        }
    }
}


extension StartWalkController: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            break
        case .notDetermined:
            break
        @unknown default:
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
