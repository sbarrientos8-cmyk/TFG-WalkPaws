//
//  MyNewsController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 26/2/26.
//

import UIKit
import Supabase

class MyNewsController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var labelTitleNav: UILabel!
    @IBOutlet weak var tableNews: UITableView!
    @IBOutlet weak var emptyView: EmptyView!
    
    private var news: [NewsModel] = []
    private let profileService = ProfileService()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelTitleNav.config(text: L10n.tr("my_posts"), style: StylesLabel.titleNav)
        tableNews.showsVerticalScrollIndicator = false

        emptyView.backgroundColor = Colors.background
        emptyView.isHidden = true
        
        setupTable()
        hideKeyboardWhenTappedAround()
        setupLoadingIndicator()
        loadMyNews()
    }

    private func setupTable() {
        tableNews.dataSource = self
        tableNews.delegate = self

        let nib = UINib(nibName: "NewCell", bundle: nil)
        tableNews.register(nib, forCellReuseIdentifier: "NewCell")

        tableNews.rowHeight = UITableView.automaticDimension
        tableNews.estimatedRowHeight = 140
        tableNews.backgroundColor = .clear
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
        tableNews.isHidden = true
        emptyView.isHidden = true
    }
    
    private func hideLoading() {
        loadingIndicator.stopAnimating()
    }
    
    private func updateEmptyState() {
        let isEmpty = news.isEmpty

        emptyView.isHidden = !isEmpty
        tableNews.isHidden = isEmpty

        if isEmpty {
            emptyView.config(
                image: UIImage(named: "new_empty"),
                title: L10n.tr("no_posts_yet"),
                description: L10n.tr("posts_will_appear_here")
            )
        }
    }

    private func loadMyNews() {
        Task { [weak self] in
            guard let self else { return }
            
            await MainActor.run {
                self.showLoading()
            }
            
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let email = session.user.email ?? ""
                guard !email.isEmpty else {
                    await MainActor.run {
                        self.hideLoading()
                        self.news = []
                        self.updateEmptyState()
                    }
                    return
                }

                guard let profile = try await profileService.fetchMyProfile(email: email),
                      let profileId = profile.id else {
                    print("❌ No profile / id")
                    await MainActor.run {
                        self.hideLoading()
                        self.news = []
                        self.updateEmptyState()
                    }
                    return
                }

                let rows: [NewsRowDTO] = try await SupabaseManager.shared.client
                    .from("news_with_author")
                    .select("*")
                    .eq("profile_id", value: profileId.uuidString)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                let models = rows.map { NewsModel(dto: $0) }

                await MainActor.run {
                    self.hideLoading()
                    self.news = models
                    self.updateEmptyState()
                    self.tableNews.reloadData()
                }

            } catch {
                await MainActor.run {
                    self.hideLoading()
                    self.news = []
                    self.updateEmptyState()
                }
                print("❌ loadMyNews error:", error)
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        news.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewCell", for: indexPath) as? NewCell else {
            return UITableViewCell()
        }

        let item = news[indexPath.row]
        cell.selectionStyle = .none
        cell.config(with: item)

        cell.setTrashVisible(true)

        cell.onTrashTapped = { [weak self] in
            self?.confirmDelete(at: indexPath)
        }

        return cell
    }

    // MARK: - Delete

    private func confirmDelete(at indexPath: IndexPath) {
        let item = news[indexPath.row]

        let alert = UIAlertController(
            title: L10n.tr("delete_post"),
            message: L10n.tr("confirm_delete_post"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("delete"), style: .destructive) { [weak self] _ in
            self?.deleteNews(item, at: indexPath)
        })

        present(alert, animated: true)
    }

    private func deleteNews(_ item: NewsModel, at indexPath: IndexPath) {
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await SupabaseManager.shared.client
                    .from("news")
                    .delete()
                    .eq("id", value: item.id)
                    .execute()

                if let urlString = item.imageUrl,
                   let path = extractStoragePath(fromPublicUrl: urlString, bucket: "news") {
                    _ = try await SupabaseManager.shared.client.storage
                        .from("news")
                        .remove(paths: [path])
                }

                await MainActor.run {
                    self.news.remove(at: indexPath.row)
                    self.updateEmptyState()
                    
                    if self.news.isEmpty {
                        self.tableNews.reloadData()
                    } else {
                        self.tableNews.deleteRows(at: [indexPath], with: .automatic)
                    }
                }

            } catch {
                print("❌ deleteNews error:", error)
            }
        }
    }

    private func extractStoragePath(fromPublicUrl url: String, bucket: String) -> String? {
        guard let range = url.range(of: "/storage/v1/object/public/\(bucket)/") else { return nil }
        let path = String(url[range.upperBound...])
        return path.isEmpty ? nil : path
    }

    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
