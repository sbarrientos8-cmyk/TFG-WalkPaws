//
//  StartWalkController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 27/2/26.
//

import UIKit

class StartWalkController: UIViewController {

    @IBOutlet weak var imageBackground: UIImageView!
    @IBOutlet weak var viewForm: UIView!
    @IBOutlet weak var fieldShelter: DropdownFieldView!
    @IBOutlet weak var fieldDog: DropdownFieldView!
    @IBOutlet weak var buttonWalk: UIButton!

    private var shelters: [String] = []
    private var dogs: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        fieldShelter.config(imageName: "house.fill", placeholder: "Selecciona un refugio")
        fieldDog.config(imageName: "pawprint.fill", placeholder: "Selecciona un perro")

        // Ejemplo: cuando seleccionas refugio -> cambias lista de perros
        fieldShelter.onSelect = { [weak self] shelterName in
            guard let self else { return }
            // aquí normalmente filtras perros por refugio
            // por ahora: mock
            self.dogs = ["Rosie", "Toby", "Finn"]
            self.fieldDog.setItems(self.dogs)
            self.fieldDog.setText("") // limpia selección anterior
        }

        fieldDog.onSelect = { dogName in
            // aquí guardas el perro seleccionado si quieres
            print("🐶 Seleccionado:", dogName)
        }

        // Carga inicial (mock)
        shelters = ["Refuge Horizon", "Huellas Solidarias", "Paws Home"]
        fieldShelter.setItems(shelters)

        fieldDog.setItems([]) // vacío hasta elegir refugio
    }

    @IBAction func startWalkClicked(_ sender: Any) {
        let shelter = fieldShelter.getText()
        let dog = fieldDog.getText()

        print("✅ Start walk con:", shelter, dog)
    }
}
