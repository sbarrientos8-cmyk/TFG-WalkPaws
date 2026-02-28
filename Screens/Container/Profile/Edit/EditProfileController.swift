//
//  EditProfileController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 26/2/26.
//

import UIKit
import Supabase
import PhotosUI

final class EditProfileController: UIViewController {
    
    @IBOutlet weak var imageProfile: CircleImageView!
    @IBOutlet weak var buttonSetImage: UIButton!

    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var fieldName: LabelField!

    @IBOutlet weak var labelGmail: UILabel!
    @IBOutlet weak var fieldGmail: LabelField!

    @IBOutlet weak var labelPassword: UILabel!
    @IBOutlet weak var labelChangePassword: UILabel!
    @IBOutlet weak var fieldPassword: LabelField!

    @IBOutlet weak var buttonEdit: UIButton!

    private var currentProfile: ProfileDTO?
    private var selectedAvatarData: Data? = nil
    private let avatarBucket = "users"

    override func viewDidLoad() {
        super.viewDidLoad()
        loadProfile()
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
                    avatarUrl = try await uploadAvatar(data: data, userId: userId)
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

                print("✅ Perfil actualizado")
                self.loadProfile()

            } catch {
                print("❌ editProfileClicked error:", error)
            }
        }
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
