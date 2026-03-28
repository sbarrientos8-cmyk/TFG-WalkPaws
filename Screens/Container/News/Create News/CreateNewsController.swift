//
//  CreateNewsController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 26/2/26.
//

import UIKit
import PhotosUI
import Supabase

class CreateNewsController: UIViewController {

    @IBOutlet weak var labelTitleNav: UILabel!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var fieldTitle: LabelField!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var fieldDescription: TextAreaField!
    @IBOutlet weak var labelImage: UILabel!
    @IBOutlet weak var fieldImage: UIView!
    @IBOutlet weak var labelFieldImage: UILabel!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonPost: UIButton!
    
    private let profileService = ProfileService()
    private var selectedImageData: Data? = nil
    private let newsBucket = "news"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        labelTitleNav.config(text: L10n.tr("new_post"), style: StylesLabel.titleNav)
        labelTitle.config(text: L10n.tr("title_label"), style: StylesLabel.titleHi)
        labelDescription.config(text: L10n.tr("description_label"), style: StylesLabel.titleHi)
        labelImage.config(text: L10n.tr("image_label"), style: StylesLabel.titleHi)
        
        fieldTitle.config(image: UIImage(named: ""), placeholder: L10n.tr( "write_title"))
        fieldDescription.config(placeholder: L10n.tr("write_description"))
        labelFieldImage.config(text: L10n.tr("add_image"), style: StylesLabel.subtitleGray)
        
        buttonPost.config(text: L10n.tr("publish"), style: StylesButton.primary)
        
        setupImageTap()
        hideKeyboardWhenTappedAround()
    }
    
    private func uploadNewsImage(data: Data) async throws -> String {
            // nombre único
            let fileName = "\(UUID().uuidString).jpg"
            let path = fileName

            // upload
            _ = try await SupabaseManager.shared.client.storage
                .from(newsBucket)
                .upload(path: path, file: data, options: FileOptions(contentType: "image/jpeg"))

            // URL pública
            let publicURL = try SupabaseManager.shared.client.storage
                .from(newsBucket)
                .getPublicURL(path: path)

            return publicURL.absoluteString
        }
    
    private func setupImageTap() {
        fieldImage.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(addImageTapped))
        fieldImage.addGestureRecognizer(tap)
    }

    private func openPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func addImageTapped() {
        openPhotoPicker()
    }
    
    @IBAction func addImageClicked(_ sender: Any) {
        openPhotoPicker()
    }
    
    @IBAction func postClicked(_ sender: Any) {

        let title = fieldTitle.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        let description = fieldDescription.getText().trimmingCharacters(in: .whitespacesAndNewlines)

        // ✅ Validación
        if title.isEmpty || description.isEmpty {
            showAlert(
                title: L10n.tr("missing_data"),
                message: L10n.tr("title_and_description_required")
            )
            return
        }

        buttonPost.isEnabled = false

        Task { [weak self] in
            guard let self else { return }

            do {
                // 1) Sesión
                let session = try await SupabaseManager.shared.client.auth.session
                let email = session.user.email ?? ""
                if email.isEmpty {
                    await MainActor.run {
                        self.buttonPost.isEnabled = true
                        self.showAlert(
                            title: L10n.tr("error"),
                            message: L10n.tr( "could_not_get_session_log_in_again")
                        )
                    }
                    return
                }

                // 2) Profile
                guard let dto = try await profileService.fetchMyProfile(email: email),
                      let profileId = dto.id else {
                    await MainActor.run {
                        self.buttonPost.isEnabled = true
                        self.showAlert(
                            title: L10n.tr("error"),
                            message: L10n.tr("could_not_get_profile")
                        )
                    }
                    return
                }

                // 3) Imagen (opcional)
                var imageUrl: String? = nil
                if let data = self.selectedImageData {
                    imageUrl = try await self.uploadNewsImage(data: data)
                }

                // 4) Insert
                let row = NewsInsert(
                    title: title,
                    description: description,
                    image_url: imageUrl,
                    author_type: "user",
                    profile_id: profileId,
                    shelter_id: nil
                )

                _ = try await SupabaseManager.shared.client
                    .from("news")
                    .insert(row)
                    .execute()

                // ✅ Éxito -> alerta -> volver a NewsController
                await MainActor.run {
                    self.buttonPost.isEnabled = true

                    self.showAlert(
                        title: L10n.tr("published_success"),
                        message: L10n.tr("post_created_successfully")
                    ) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }

            } catch {
                print("❌ post news error:", error)
                await MainActor.run {
                    self.buttonPost.isEnabled = true
                    self.showAlert(
                        title: L10n.tr("error"),
                        message: L10n.tr("could_not_publish_try_again")
                    )
                }
            }
        }
    }

    // ✅ helper
    private func showAlert(title: String, message: String, onOk: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("ok"), style: .default) { _ in onOk?() })
        present(alert, animated: true)
    }
    
    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension CreateNewsController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let item = results.first?.itemProvider,
              item.canLoadObject(ofClass: UIImage.self) else { return }

        item.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let self, let image = obj as? UIImage else { return }

            let data = image.jpegData(compressionQuality: 0.85)

            DispatchQueue.main.async {
                self.imagePreview.image = image
                self.selectedImageData = data
                self.labelFieldImage.text = L10n.tr("image_selected")
            }
        }
    }
}
