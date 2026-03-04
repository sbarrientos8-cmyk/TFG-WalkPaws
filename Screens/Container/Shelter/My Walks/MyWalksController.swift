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
    
    private let service = WalksService()
    private var walks: [WalkListRowDTO] = []
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        labelTitleNav.config(text: "Mis Paseos", style: StylesLabel.titleNav)
        
        tableView.dataSource = self
        tableView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear
        
        tableView.register(UINib(nibName: "MyWalkCell", bundle: nil), forCellReuseIdentifier: "MyWalkCell")

        hideKeyboardWhenTappedAround()
        loadMyWalks()
    }

    private func loadMyWalks() {
        Task { [weak self] in
            guard let self else { return }

            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let profileId = session.user.id

                let rows = try await service.fetchMyWalks(profileId: profileId)

                await MainActor.run {
                    self.walks = rows
                    self.tableView.reloadData()
                    print("✅ Mis paseos cargados:", rows.count)
                }

            } catch {
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
