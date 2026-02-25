//
//  DogController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 21/2/26.
//

import UIKit

class DogController: UIViewController,
                     UICollectionViewDataSource,
                     UICollectionViewDelegate,
                     UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var labelTitleNav: UILabel!
    @IBOutlet weak var searchField: SearchField!
    @IBOutlet weak var viewButtons: UIView!
    @IBOutlet weak var buttonNormal: UIButton!
    @IBOutlet weak var buttonNeedy: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!

    var shelterId: UUID!

    private var allDogs: [DogModel] = []
    private var filteredDogs: [DogModel] = []
    private var showingNeedy = false   // false = normales (por defecto)

    override func viewDidLoad() {
        super.viewDidLoad()

        labelTitleNav.config(text: "Perros", style: StylesLabel.titleNav)
        searchField.config(placeholder: "Buscar perros")
        searchField.onTextChange { [weak self] text in
            self?.applyFilter(text)
        }
        viewButtons.layer.cornerRadius = 20

        // Collection setup
        collectionView.dataSource = self
        collectionView.delegate = self

        let nib = UINib(nibName: "DogCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "DogCell")

        // Estado inicial (Normal)
        setSelectedTab(isNeedy: false)

        loadDogs()
    }

    private func loadDogs() {
        guard let shelterId = shelterId else { return }

        fetchDogsByShelter(shelterId: shelterId.uuidString) { [weak self] models in
            DispatchQueue.main.async {
                self?.allDogs = models
                self?.applyFilter()
            }
        }
    }

    private func applyFilter() {
        if showingNeedy {
            filteredDogs = allDogs.filter { $0.isDisabled == true }
        } else {
            filteredDogs = allDogs.filter { $0.isDisabled == false }
        }
        collectionView.reloadData()
    }

    // MARK: - Buttons

    @IBAction func dogNormalClicked(_ sender: Any) {
        showingNeedy = false
        setSelectedTab(isNeedy: false)
        applyFilter()
    }

    @IBAction func dogNeedyClicked(_ sender: Any) {
        showingNeedy = true
        setSelectedTab(isNeedy: true)
        applyFilter()
    }

    private func setSelectedTab(isNeedy: Bool) {
        // Ajusta esto a tu diseño (colores/estilos)
        if isNeedy {
            buttonNeedy.isSelected = true
            buttonNormal.isSelected = false
        } else {
            buttonNeedy.isSelected = false
            buttonNormal.isSelected = true
        }

        // Si no usas estilos con isSelected, hazlo a mano:
        buttonNormal.alpha = isNeedy ? 0.5 : 1.0
        buttonNeedy.alpha = isNeedy ? 1.0 : 0.5
    }
    
    private func applyFilter(_ searchText: String? = nil) {

        // 1️⃣ Filtrado por estado (normal / necesitado)
        var baseDogs: [DogModel]

        if showingNeedy {
            baseDogs = allDogs.filter { $0.isDisabled }
        } else {
            baseDogs = allDogs.filter { !$0.isDisabled }
        }

        // 2️⃣ Filtrado por búsqueda
        guard let text = searchText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            filteredDogs = baseDogs
            collectionView.reloadData()
            return
        }

        let lowercasedText = text.lowercased()

        filteredDogs = baseDogs.filter {
            $0.name.lowercased().contains(lowercasedText) ||
            $0.breed.lowercased().contains(lowercasedText) ||
            $0.city.lowercased().contains(lowercasedText)
        }

        collectionView.reloadData()
    }

    // MARK: - Collection

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredDogs.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "DogCell",
            for: indexPath
        ) as? DogCell else { return UICollectionViewCell() }

        let dog = filteredDogs[indexPath.item]

        // En esta pantalla puedes mostrar edad o ciudad, como prefieras:
        cell.config(with: dog, subtitle: .age)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let padding: CGFloat = 12
        let totalSpacing = padding * 3
        let width = (collectionView.frame.width - totalSpacing) / 2
        let height = width + 60

        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { 12 }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat { 12 }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let dog = filteredDogs[indexPath.item]

        if dog.isDisabled {
            let needyVC = DogDetailNeedyController(nibName: "DogDetailNeedyController", bundle: nil)
            needyVC.dog = dog
            navigationController?.pushViewController(needyVC, animated: true)
        } else {
            let normalVC = DogDetailNormalController(nibName: "DogDetailNormalController", bundle: nil)
            normalVC.dog = dog
            navigationController?.pushViewController(normalVC, animated: true)
        }
    }
    
    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
