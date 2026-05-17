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
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewEmpty: EmptyView!

    var shelterId: UUID!

    private var allDogs: [DogModel] = []
    private var filteredDogs: [DogModel] = []
    private var showingNeedy = false

    override func viewDidLoad() {
        super.viewDidLoad()

        labelTitleNav.config(text: L10n.tr("dogs"), style: StylesLabel.titleNav)
        searchField.config(placeholder: L10n.tr("search_dogs"))
        searchField.onTextChange { [weak self] text in
            self?.applyFilter(text)
        }

        collectionView.dataSource = self
        collectionView.delegate = self

        let nib = UINib(nibName: "DogCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "DogCell")

        viewButtons.applyCardStyle(cornerRadius: 20)
        viewEmpty.backgroundColor = Colors.background

        loadingIndicator.hidesWhenStopped = true

        showingNeedy = false
        updateTabStyles()
        loadDogs()
    }

    private func showLoading() {
        loadingIndicator.startAnimating()
        collectionView.isHidden = true
        viewEmpty.isHidden = true
    }

    private func hideLoading() {
        loadingIndicator.stopAnimating()
    }

    private func loadDogs() {
        guard let shelterId = shelterId else { return }

        showLoading()

        fetchDogsByShelter(shelterId: shelterId.uuidString) { [weak self] models in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.hideLoading()
                self.allDogs = models
                self.applyFilter()
            }
        }
    }

    private func updateEmptyState() {
        let isEmpty = filteredDogs.isEmpty

        viewEmpty.isHidden = !isEmpty
        collectionView.isHidden = isEmpty

        if isEmpty {
            if showingNeedy {
                viewEmpty.config(
                    image: UIImage(named: "footprint_empty"),
                    title: L10n.tr("no_needy_dogs"),
                    description: L10n.tr( "no_special_needs_dogs_in_shelter")
                )
            } else {
                viewEmpty.config(
                    image: UIImage(named: "footprint_empty"),
                    title: L10n.tr("no_stable_dogs"),
                    description: L10n.tr("no_dogs_available_in_category")
                )
            }
        }
    }

    private func applyFilter(_ searchText: String? = nil) {
        var baseDogs: [DogModel]

        if showingNeedy {
            baseDogs = allDogs.filter { $0.isDisabled }
        } else {
            baseDogs = allDogs.filter { !$0.isDisabled }
        }

        guard let text = searchText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            filteredDogs = baseDogs
            updateEmptyState()
            collectionView.reloadData()
            return
        }

        let lowercasedText = text.lowercased()

        filteredDogs = baseDogs.filter {
            $0.name.lowercased().contains(lowercasedText) ||
            $0.breed.lowercased().contains(lowercasedText) ||
            $0.city.lowercased().contains(lowercasedText)
        }

        updateEmptyState()
        collectionView.reloadData()
    }

    private func updateTabStyles() {
        if showingNeedy {
            buttonNeedy.config(
                text: buttonNeedy.title(for: .normal) ?? L10n.tr( "need_support"),
                style: StylesButton.secondaryGreen2
            )

            buttonNormal.config(
                text: buttonNormal.title(for: .normal) ?? L10n.tr( "stable"),
                style: StylesButton.secondaryWhite2
            )
        } else {
            buttonNormal.config(
                text: buttonNormal.title(for: .normal) ?? L10n.tr( "stable"),
                style: StylesButton.secondaryGreen2
            )

            buttonNeedy.config(
                text: buttonNeedy.title(for: .normal) ?? L10n.tr( "need_support"),
                style: StylesButton.secondaryWhite2
            )
        }
    }

    @IBAction func dogNormalClicked(_ sender: Any) {
        showingNeedy = false
        updateTabStyles()
        applyFilter(searchField.getText())
    }

    @IBAction func dogNeedyClicked(_ sender: Any) {
        showingNeedy = true
        updateTabStyles()
        applyFilter(searchField.getText())
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredDogs.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "DogCell",
            for: indexPath
        ) as? DogCell else {
            return UICollectionViewCell()
        }

        let dog = filteredDogs[indexPath.item]
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
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        12
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        12
    }

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
