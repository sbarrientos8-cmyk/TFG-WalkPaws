//
//  ProfileUserController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 4/2/26.
//

import UIKit

class ProfileUserController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var navBar: NavBarView!
    @IBOutlet weak var viewProfile: UIView!
    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelGmail: UILabel!
    @IBOutlet weak var labelPoints: UILabel!
    @IBOutlet weak var viewLine: UIView!
    @IBOutlet weak var buttonEdit: UIButton!
    @IBOutlet weak var tableWidgets: UITableView!
    @IBOutlet weak var bottomBar: BottomBar!
    
    private let sections: [ProfileSection] = [
        .myWalks,
        .myPosts,
        .changeLanguage,
        .contact
    ]
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageProfile.layer.cornerRadius = imageProfile.frame.width / 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        print("nibName:", self.nibName as Any)
        print("view:", type(of: self.view as Any))
        
        navBar.config(with: NavBarButtonType(
            type: .logout,
            action: { [weak self] in self?.logout() })
        )
        
        viewProfile.layer.cornerRadius = 15
        
        // Añadir sombra
        viewProfile.applyCardStyle()
        
        tableWidgets.applyCardStyle()

        labelName.font = Fonts.figtreeRegular(17)
        labelGmail.font = Fonts.figtreeLight(15)
        viewLine.backgroundColor = Colors.grayLight
        buttonEdit.config(text: "Editar Perfil", style: StylesButton.edit)
        labelPoints.config(text: "", style: StylesLabel.subtitleGray)
        
        tableWidgets.dataSource = self
        tableWidgets.delegate = self

        let nib = UINib(nibName: "SectionProfileCell", bundle: nil)
        tableWidgets.register(nib, forCellReuseIdentifier: "SectionProfileCell")
        
        bottomBar.selectSection(.user)

        setupDefaultAvatar()
        loadUserProfile()
        
        navigationItem.hidesBackButton = true
        hideKeyboardWhenTappedAround()
    }

    private func setupDefaultAvatar() {
        imageProfile.image = UIImage(systemName: "person.circle.fill") // default
        imageProfile.contentMode = .scaleAspectFill
        imageProfile.clipsToBounds = true
    }

    private let profileService = ProfileService()

    private func loadUserProfile() {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let email = session.user.email ?? ""

                await MainActor.run {
                    self.labelGmail.text = email
                }

                guard let dto = try await profileService.fetchMyProfile(email: email) else {
                    await MainActor.run {
                        self.labelName.text = email.components(separatedBy: "@").first ?? "Usuario"
                    }
                    return
                }

                let profile = ProfileModel(dto: dto)

                await MainActor.run {
                    self.labelName.text = profile.name
                    self.labelGmail.text = profile.email.isEmpty ? email : profile.email
                    self.labelPoints.text = "\(profile.points ?? 0) puntos"
                }
                

                if let urlString = profile.avatarURL, let url = URL(string: urlString) {
                    self.loadImage(from: url)
                }

            } catch {
                print("Error loading profile:", error)
            }
        }
    }

    private func loadImage(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let img = UIImage(data: data)
                await MainActor.run {
                    if let img { self.imageProfile.image = img }
                }
            } catch {
                print("Error loading avatar:", error)
            }
        }
    }

    private func logout() {
        let alert = UIAlertController(
            title: "Cerrar sesión",
            message: "¿Seguro que quieres cerrar sesión?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        alert.addAction(UIAlertAction(title: "Cerrar sesión", style: .destructive) { [weak self] _ in
            guard let self else { return }

            Task {
                do {
                    try await SupabaseManager.shared.client.auth.signOut()

                    await MainActor.run {
                        let login = LoginController(nibName: "LoginController", bundle: nil)
                        self.navigationController?.setViewControllers([login], animated: true)
                    }
                } catch {
                    await MainActor.run {
                        let err = UIAlertController(
                            title: "Error",
                            message: "No se pudo cerrar sesión. Inténtalo de nuevo.",
                            preferredStyle: .alert
                        )
                        err.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(err, animated: true)
                    }
                    print("❌ logout error:", error)
                }
            }
        })

        present(alert, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 70
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return sections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SectionProfileCell", for: indexPath) as? SectionProfileCell else {
            return UITableViewCell()
        }

        let section = sections[indexPath.row]
        cell.config(with: section)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {

        let section = sections[indexPath.row]
        let vc = section.goSection()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func editProfileClicked(_ sender: Any) {
        let vc = EditProfileController(nibName: "EditProfileController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}
