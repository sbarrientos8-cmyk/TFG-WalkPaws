//
//  MyWalksController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 1/3/26.
//

import UIKit

class MyWalksController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var labelTitleNav: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: EmptyView!
    
    private let service = WalksService()
    private var walks: [WalkListRowDTO] = []
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        labelTitleNav.config(text: L10n.tr("my_walks"), style: StylesLabel.titleNav)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.register(UINib(nibName: "MyWalkCell", bundle: nil), forCellReuseIdentifier: "MyWalkCell")

        emptyView.backgroundColor = Colors.background
        emptyView.isHidden = true
        
        setupLoadingIndicator()
        
        hideKeyboardWhenTappedAround()
        loadMyWalks()
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func showLoading() {
        loadingIndicator.startAnimating()
        tableView.isHidden = true
        emptyView.isHidden = true
    }
    
    private func hideLoading() {
        loadingIndicator.stopAnimating()
    }
    
    private func updateEmptyState() {
        let isEmpty = walks.isEmpty

        emptyView.isHidden = !isEmpty
        tableView.isHidden = isEmpty

        if isEmpty {
            emptyView.config(
                image: UIImage(named: "walking_empty"),
                title: L10n.tr("no_walks_yet"),
                description: L10n.tr("first_walk_will_appear_here")
            )
        }
    }

    private func loadMyWalks() {
        Task { [weak self] in
            guard let self else { return }
            
            await MainActor.run {
                self.showLoading()
            }

            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let profileId = session.user.id

                let rows = try await service.fetchMyWalks(profileId: profileId)

                await MainActor.run {
                    self.hideLoading()
                    self.walks = rows
                    self.tableView.reloadData()
                    self.updateEmptyState()
                    print("✅ Mis paseos cargados:", rows.count)
                }

            } catch {
                await MainActor.run {
                    self.hideLoading()
                    self.walks = []
                    self.tableView.reloadData()
                    self.updateEmptyState()
                }
                print("❌ loadMyWalks error:", error)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        walks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyWalkCell", for: indexPath) as? MyWalkCell else {
            return UITableViewCell()
        }
        
        let w = walks[indexPath.row]

        cell.config(
            walk: WalkRowDTO(
                id: w.id,
                started_at: w.started_at,
                ended_at: w.ended_at,
                duration_seconds: w.duration_seconds,
                distance_km: w.distance_km,
                points_earned: w.points_earned,
                route_simplified: w.route_simplified
            ),
            shelterName: w.shelter_name,
            dogName: w.dog_name,
            city: w.shelter_city,
            country: w.shelter_country,
            dogPhotoURL: w.dog_photo_url
        )
        
        return cell
    }
    
    @IBAction func backClicked(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
}
