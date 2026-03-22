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

    override func viewDidLoad() {
        super.viewDidLoad()
        labelTitleNav.config(text: String(localized: "my_posts"), style: StylesLabel.titleNav)
        tableNews.showsVerticalScrollIndicator = false

        emptyView.backgroundColor = Colors.background
        emptyView.isHidden = true
        
        setupTable()
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
    
    private func updateEmptyState() {
        let isEmpty = news.isEmpty

        emptyView.isHidden = !isEmpty
        tableNews.isHidden = isEmpty

        if isEmpty {
            emptyView.config(
                image: UIImage(named: "new_empty"),
                title: String(localized: "no_posts_yet"),
                description: String(localized: "posts_will_appear_here")
            )
        }
    }

    private func loadMyNews() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let email = session.user.email ?? ""
                guard !email.isEmpty else { return }

                guard let profile = try await profileService.fetchMyProfile(email: email),
                      let profileId = profile.id else {
                    print("❌ No profile / id")
                    return
                }

                // Opción A (recomendada): leer de la tabla `news` filtrando por profile_id
                // Ajusta el select a lo que uses en tu NewsModel/DTO.
                let rows: [NewsRowDTO] = try await SupabaseManager.shared.client
                    .from("news_with_author") // si tienes esta VIEW como en fetchNews
                    .select("*")
                    .eq("profile_id", value: profileId.uuidString)
                    .order("created_at", ascending: false)
                    .execute()
                    .value

                let models = rows.map { NewsModel(dto: $0) }

                await MainActor.run {
                    self.news = models
                    self.updateEmptyState()
                    self.tableNews.reloadData()
                }

            } catch {
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

        // ✅ En MIS news, se ve el trash
        cell.setTrashVisible(true)

        // ✅ Acción del trash
        cell.onTrashTapped = { [weak self] in
            self?.confirmDelete(at: indexPath)
        }

        return cell
    }

    // MARK: - Delete

    private func confirmDelete(at indexPath: IndexPath) {
        let item = news[indexPath.row]

        let alert = UIAlertController(
            title: String(localized: "delete_post"),
            message: String(localized: "confirm_delete_post"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "delete"), style: .destructive) { [weak self] _ in
            self?.deleteNews(item, at: indexPath)
        })

        present(alert, animated: true)
    }

    private func deleteNews(_ item: NewsModel, at indexPath: IndexPath) {
        Task { [weak self] in
            guard let self else { return }
            do {
                // 1) Borrar fila en tabla news
                _ = try await SupabaseManager.shared.client
                    .from("news")
                    .delete()
                    .eq("id", value: item.id) // <- si `id` no es UUID, dime el tipo
                    .execute()

                // 2) (Opcional) borrar imagen del bucket si existe
                if let urlString = item.imageUrl,
                   let path = extractStoragePath(fromPublicUrl: urlString, bucket: "news") {
                    // path debería ser el nombre del archivo o carpeta/archivo
                    _ = try await SupabaseManager.shared.client.storage
                        .from("news")
                        .remove(paths: [path])
                }

                await MainActor.run {
                    self.news.remove(at: indexPath.row)
                    self.updateEmptyState()
                    self.tableNews.deleteRows(at: [indexPath], with: .automatic)
                }

            } catch {
                print("❌ deleteNews error:", error)
            }
        }
    }

    // Convierte una public URL del estilo:
    // .../storage/v1/object/public/news/<PATH>
    private func extractStoragePath(fromPublicUrl url: String, bucket: String) -> String? {
        guard let range = url.range(of: "/storage/v1/object/public/\(bucket)/") else { return nil }
        let path = String(url[range.upperBound...])
        return path.isEmpty ? nil : path
    }

    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
