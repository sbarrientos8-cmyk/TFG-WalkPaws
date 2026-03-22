//
//  EditProfileController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 26/2/26.
//

import UIKit
import Supabase
import PhotosUI
import SDWebImage

final class EditProfileController: UIViewController {
    
    @IBOutlet weak var labelTitleNav: UILabel!
    @IBOutlet weak var imageProfile: CircleImageView!
    @IBOutlet weak var buttonSetImage: UIButton!

    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var fieldName: LabelField!

    @IBOutlet weak var labelGmail: UILabel!
    @IBOutlet weak var fieldGmail: LabelField!

    @IBOutlet weak var labelPassword: UILabel!
    @IBOutlet weak var fieldPassword: LabelField!

    @IBOutlet weak var buttonEdit: UIButton!

    private var currentProfile: ProfileDTO?
    private var selectedAvatarData: Data? = nil
    private let avatarBucket = "users"
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelTitleNav.config(text: String(localized: "edit_image"), style: StylesLabel.titleNav)
        
        buttonSetImage.config(text: String(localized: "change_image"), style: StylesButton.secondaryGreen)

        labelName.config(text: String(localized: "name_label"), style: StylesLabel.subtitle)
        fieldName.config(image: UIImage(named: ""), placeholder: String(localized: "new_name"))
        
        labelGmail.config(text: String(localized: "email_label"), style: StylesLabel.subtitle)
        fieldGmail.config(image: UIImage(named: ""), placeholder: String(localized: "new_email"))
        
        labelPassword.config(text: String(localized: "password_label"), style: StylesLabel.subtitle)
        fieldPassword.config(image: UIImage(named: ""), placeholder: String(localized: "new_password"))
        
        buttonEdit.config(text: String(localized: "save_changes"), style: StylesButton.primary)
        
        loadProfile()
        hideKeyboardWhenTappedAround()
    }

    // MARK: - Load
    
    private func uploadAvatar(data: Data, userId: UUID) async throws -> String {
        let fileName = "\(userId.uuidString).jpg"
        let path = fileName

        // Subir
        _ = try await SupabaseManager.shared.client.storage
            .from(avatarBucket)
            .upload(
                path: path,
                file: data,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        // URL pública
        let publicURL = try SupabaseManager.shared.client.storage
            .from(avatarBucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

    private func loadProfile() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let user = session.user

                // Email desde Auth
                let authEmail = user.email ?? ""

                // Perfil desde tabla profiles
                // (si tu ProfileService filtra por email, ok)
                let dto = try await ProfileService().fetchMyProfile(email: authEmail)
                self.currentProfile = dto

                await MainActor.run {
                    self.fieldName.setText(dto?.name ?? "")
                    self.fieldGmail.setText(authEmail) // siempre desde auth
                    self.fieldPassword.setText("")      // nunca mostramos la real

                    if let urlStr = dto?.avatar_url, let url = URL(string: urlStr) {
                        self.imageProfile.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.circle"))
                    } else {
                        self.imageProfile.image = UIImage(systemName: "person.circle")
                    }
                }

            } catch {
                print("❌ loadProfile error:", error)
            }
        }
    }

    // MARK: - Image (opcional)

    @IBAction func selectImageClicked(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Save

    @IBAction func editProfileClicked(_ sender: Any) {

        let newName = fieldName.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        let newEmail = fieldGmail.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        let newPassword = fieldPassword.getText().trimmingCharacters(in: .whitespacesAndNewlines)

        buttonEdit.isEnabled = false

        Task { [weak self] in
            guard let self else { return }
            defer {
                Task { @MainActor in self.buttonEdit.isEnabled = true }
            }

            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id // UUID

                // 1) Cambiar contraseña (Auth) si escribió algo
                if !newPassword.isEmpty {
                    try await SupabaseManager.shared.client.auth.update(
                      user: UserAttributes(password: newPassword)
                    )
                }

                // 2) Cambiar email (Auth) si cambió
                //    OJO: según configuración de tu proyecto, puede requerir confirmación por email
                let currentAuthEmail = session.user.email ?? ""
                if !newEmail.isEmpty, newEmail != currentAuthEmail {
                    try await SupabaseManager.shared.client.auth.update(
                      user: UserAttributes(email: newEmail)
                    )
                }

                // 3) (Opcional) Subir avatar a storage y obtener url
                //    Si no quieres ahora, deja avatarUrl = currentProfile?.avatar_url
                var avatarUrl: String? = currentProfile?.avatar_url

                if let data = selectedAvatarData {
                    let uploaded = try await uploadAvatar(data: data, userId: userId)

                    // cache-buster para que SDWebImage no use la misma cache
                    avatarUrl = uploaded + "?v=\(Int(Date().timeIntervalSince1970))"
                }

                // Si más adelante quieres subirlo:
                // if let data = selectedAvatarData { avatarUrl = try await uploadAvatar(data: data, userId: userId) }

                // 4) Actualizar tabla profiles (name/email/avatar_url)
                //    Sync email (aunque Auth use confirmación, aquí lo dejamos igual a lo que escribió)
                let updateRow = ProfileUpdate(
                    name: newName.isEmpty ? nil : newName,
                    email: newEmail.isEmpty ? nil : newEmail,
                    avatar_url: avatarUrl
                )

                try await SupabaseManager.shared.client
                    .from("profiles")
                    .update(updateRow)
                    .eq("id", value: userId.uuidString)
                    .execute()

                await MainActor.run {
                    if let avatarUrl, let url = URL(string: avatarUrl) {
                        SDImageCache.shared.removeImage(forKey: url.absoluteString, cacheType: .all)
                        self.imageProfile.sd_setImage(
                            with: url,
                            placeholderImage: UIImage(systemName: "person.circle"),
                            options: [.refreshCached]
                        )
                    }

                    self.showAlert(
                        title: String(localized: "saved"),
                        message: String(localized: "changes_saved_successfully")
                    ) {
                        // opcional: volver atrás al perfil
                        let vc = ProfileUserController(nibName: "ProfileUserController", bundle: nil)
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }

                print("✅ Perfil actualizado")
                self.loadProfile()

            } catch {
                print("❌ editProfileClicked error:", error)
            }
        }
    }
    
    @IBAction func backClicked(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
    
    private func showAlert(title: String, message: String, onOk: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String(localized: "ok"), style: .default) { _ in onOk?() })
        present(alert, animated: true)
    }
}

extension EditProfileController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

        // 1️⃣ Cerrar picker
        picker.dismiss(animated: true)

        // 2️⃣ Verificar que hay imagen
        guard let item = results.first?.itemProvider,
              item.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        // 3️⃣ Cargar imagen
        item.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self,
                  let image = object as? UIImage else { return }

            // 4️⃣ Convertir a Data
            let data = image.jpegData(compressionQuality: 0.85)

            DispatchQueue.main.async {
                // 5️⃣ Mostrar preview
                self.imageProfile.image = image
                self.selectedAvatarData = data
            }
        }
    }
}
