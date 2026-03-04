//
//  StartWalkController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 27/2/26.
//

import UIKit
import CoreImage
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

    private var dogs: [String] = []
    private var allDogs: [DogModel] = []

    private var shelters: [(id: String, name: String)] = []
    private var dogsForSelectedShelter: [DogModel] = []

    private var selectedShelterId: String? = nil
    private var selectedDogId: String? = nil
    
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
        
        labelTitle.config(text: "DATOS DEL PASEO: ", style: StylesLabel.title2Name)
        labelShelter.config(text: "Refugio", style: StylesLabel.subtitle)
        labelDog.config(text: "Perro", style: StylesLabel.subtitle)
        buttonWalk.config(text: "Comenzar paseo", style: StylesButton.primary)
        
        //blurImageView(imageBackground, radius: 15.0) // menos blur
        let darkOverlay = UIView(frame: imageBackground.bounds)
        darkOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.1) // prueba 0.12 - 0.30
        darkOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageBackground.addSubview(darkOverlay)
        
        
        fieldShelter.config(imageName: "shelter_icn", placeholder: "Selecciona un refugio")
        fieldDog.config(imageName: "footprint1", placeholder: "Selecciona un perro")

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

        loadSheltersWithDogs()
        hideKeyboardWhenTappedAround()
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
            print("⚠️ Falta seleccionar refugio o perro (o IDs inválidos)")
            return
        }

        let vc = WalkingController(nibName: nil, bundle: nil)
        vc.selectedShelterName = shelterName
        vc.selectedDogName = dogName
        vc.selectedShelterId = shelterUUID
        vc.selectedDogId = dogUUID

        navigationController?.pushViewController(vc, animated: true)
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
                        dict[sid] = d.city.isEmpty ? (rows.first(where: { $0.shelter_id == sid })?.shelter_name ?? "Refugio") : (rows.first(where: { $0.shelter_id == sid })?.shelter_name ?? "Refugio")
                        // Realmente lo importante es shelter_name:
                        // pero DogModel no guarda shelter_name, solo city.
                    }
                }

                // Mejor: sacarlo directamente de los DTO
                var dict2: [String: String] = [:]
                for r in rows {
                    dict2[r.shelter_id] = r.shelter_name ?? "Refugio"
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
