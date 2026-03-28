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
    
    private var sections: [ProfileSection] {
        [
            .myWalks,
            .myPosts,
            .changeLanguage,
            .contact
        ]
    }
    
    private let profileService = ProfileService()
    private let profileLoadingIndicator = UIActivityIndicatorView(style: .medium)
    
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
        viewProfile.applyCardStyle()
        tableWidgets.applyCardStyle()

        labelName.font = Fonts.figtreeRegular(17)
        labelGmail.font = Fonts.figtreeLight(15)
        viewLine.backgroundColor = Colors.grayLight
        buttonEdit.config(text: L10n.tr("edit_profile"), style: StylesButton.edit)
        labelPoints.config(text: "", style: StylesLabel.subtitleGray)
        
        tableWidgets.dataSource = self
        tableWidgets.delegate = self

        let nib = UINib(nibName: "SectionProfileCell", bundle: nil)
        tableWidgets.register(nib, forCellReuseIdentifier: "SectionProfileCell")
        
        bottomBar.selectSection(.user)

        setupAvatarView()
        setupProfileLoadingIndicator()
        setLoadingTexts()
        loadUserProfile()
        
        navigationItem.hidesBackButton = true
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

        buttonEdit.config(text: L10n.tr("edit_profile"), style: StylesButton.edit)
        tableWidgets.reloadData()
        loadUserProfile()
    }

    private func setupAvatarView() {
        imageProfile.image = nil
        imageProfile.contentMode = .scaleAspectFill
        imageProfile.clipsToBounds = true
    }
    
    private func setupProfileLoadingIndicator() {
        profileLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        profileLoadingIndicator.hidesWhenStopped = true
        
        imageProfile.addSubview(profileLoadingIndicator)
        
        NSLayoutConstraint.activate([
            profileLoadingIndicator.centerXAnchor.constraint(equalTo: imageProfile.centerXAnchor),
            profileLoadingIndicator.centerYAnchor.constraint(equalTo: imageProfile.centerYAnchor)
        ])
    }
    
    private func setLoadingTexts() {
        labelName.text = L10n.tr("loading")
        labelGmail.text = L10n.tr("loading")
        labelPoints.text = L10n.tr("loading")
    }

    private func loadUserProfile() {
        Task {
            await MainActor.run {
                self.imageProfile.image = nil
                self.profileLoadingIndicator.startAnimating()
                self.setLoadingTexts()
            }
            
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let email = session.user.email ?? ""

                await MainActor.run {
                    self.labelGmail.text = email
                }

                guard let dto = try await profileService.fetchMyProfile(email: email) else {
                    await MainActor.run {
                        self.labelName.text = email.components(separatedBy: "@").first ?? L10n.tr("user")
                        self.labelGmail.text = email
                        self.labelPoints.text = "0 \(L10n.tr("points"))"
                        self.profileLoadingIndicator.stopAnimating()
                    }
                    return
                }

                let profile = ProfileModel(dto: dto)

                await MainActor.run {
                    self.labelName.text = profile.name.isEmpty ? (email.components(separatedBy: "@").first ?? L10n.tr("user")) : profile.name
                    self.labelGmail.text = profile.email.isEmpty ? email : profile.email
                    self.labelPoints.text = "\(profile.points ?? 0) \(L10n.tr("points"))"
                }

                if let urlString = profile.avatarURL,
                   let url = URL(string: urlString) {
                    await self.loadImage(from: url)
                } else {
                    await MainActor.run {
                        self.profileLoadingIndicator.stopAnimating()
                        self.imageProfile.image = nil
                    }
                }

            } catch {
                await MainActor.run {
                    self.profileLoadingIndicator.stopAnimating()
                    self.labelName.text = L10n.tr("error_loading")
                    self.labelGmail.text = L10n.tr("error_loading")
                    self.labelPoints.text = L10n.tr("error_loading")
                }
                print("Error loading profile:", error)
            }
        }
    }

    private func loadImage(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let img = UIImage(data: data)
            
            await MainActor.run {
                self.profileLoadingIndicator.stopAnimating()
                self.imageProfile.image = img
            }
        } catch {
            await MainActor.run {
                self.profileLoadingIndicator.stopAnimating()
                self.imageProfile.image = nil
            }
            print("Error loading avatar:", error)
        }
    }

    private func logout() {
        let alert = UIAlertController(
            title: L10n.tr("log_out"),
            message: L10n.tr("confirm_log_out"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: L10n.tr("cancel"), style: .cancel))

        alert.addAction(UIAlertAction(title: L10n.tr("log_out"), style: .destructive) { [weak self] _ in
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
                            title: L10n.tr("error"),
                            message: L10n.tr( "could_not_log_out_try_again"),
                            preferredStyle: .alert
                        )
                        err.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default))
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
