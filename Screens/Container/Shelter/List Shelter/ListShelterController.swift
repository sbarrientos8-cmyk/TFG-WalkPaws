//
//  ListShelterController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 31/1/26.
//

import UIKit

class ListShelterController: UIViewController, UITableViewDataSource, UITableViewDelegate
{

    @IBOutlet weak var searchField: SearchField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bottomBar: BottomBar!
    
    private let service = ShelterService()
    private var allShelters: [ShelterModel] = []
    private var shelters: [ShelterModel] = []
    private let loading = UIActivityIndicatorView(style: .medium)
    private let emptyLabel = UILabel()
    var shelter: ShelterModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchField.config(placeholder: "Buscar refugio, ciudad...")
        searchField.onTextChange { [weak self] text in
            self?.applyFilter(text)
        }
        
        tableView.layer.cornerRadius = 16
        tableView.layer.shadowColor = UIColor.black.cgColor
        tableView.layer.shadowOpacity = 0.08
        tableView.layer.shadowOffset = CGSize(width: 0, height: 6)
        tableView.layer.shadowRadius = 12
        
        bottomBar.selectSection(.shelter)

        setupTable()
        setupEmptyState()
        setupLoading()
        loadShelters()
        
        print("NAV:", navigationController as Any)
        
        navigationItem.hidesBackButton = true
        hideKeyboardWhenTappedAround()
    }

    private func setupTable()
    {
        tableView.dataSource = self
        tableView.delegate = self

        let nib = UINib(nibName: "ShelterCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "ShelterCell")

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
    }

    private func loadShelters() {
        
        loading.startAnimating()
        emptyLabel.isHidden = true

        Task {
            do {
                let dtos = try await service.fetchActiveShelters()
                let mapped = dtos.map { ShelterModel(dto: $0) }

                await MainActor.run
                {
                    self.allShelters = mapped
                    self.shelters = mapped
                    self.tableView.reloadData()

                    self.loading.stopAnimating()
                    self.emptyLabel.isHidden = !mapped.isEmpty
                }
            } catch {
                await MainActor.run {
                    self.loading.stopAnimating()
                    self.emptyLabel.text = "Error cargando refugios."
                    self.emptyLabel.isHidden = false
                }
                print("❌ Error cargando shelters:", error)
            }
        }
    }
    
    private func setupLoading() {
        loading.hidesWhenStopped = true
        view.addSubview(loading)
        loading.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loading.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyLabel.text = "No hay refugios disponibles."
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    private func applyFilter(_ text: String) {
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if q.isEmpty {
            shelters = allShelters
        } else {
            shelters = allShelters.filter { s in
                let name = s.name.lowercased()
                let desc = (s.description ?? "").lowercased()
                let loc  = s.locationText.lowercased()
                return name.contains(q) || desc.contains(q) || loc.contains(q)
            }
        }
        
        emptyLabel.text = q.isEmpty ? "No hay refugios disponibles." : "No hay resultados para “\(text)”"
        emptyLabel.isHidden = !shelters.isEmpty

        tableView.reloadData()
    }

    // MARK: Methods Tableview
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        shelters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ShelterCell", for: indexPath) as? ShelterCell else
        {
            return UITableViewCell()
        }

        cell.config(with: shelters[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shelter = shelters[indexPath.row]

        let vc = ProfileShelterController(nibName: "ProfileShelterController", bundle: nil)
        vc.shelter = shelter
        navigationController?.pushViewController(vc, animated: true)
    }

}
