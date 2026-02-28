//
//  ContactShelterController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/2/26.
//

import UIKit
import Functions

class ContactShelterController: UIViewController {
    
    @IBOutlet weak var labelTitleNav: UILabel!
    
    @IBOutlet weak var viewInfoShelter: UIView!
    @IBOutlet weak var imageShelter: CircleImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelGmail: UILabel!
    
    @IBOutlet weak var labelReason: UILabel!
    @IBOutlet weak var fieldReason: LabelField!
    
    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var fieldMessage: TextAreaField!
    
    @IBOutlet weak var buttonSend: UIButton!
    
    var shelter: ShelterContactInfo?

    private let profileService = ProfileService()

    private var userName: String = "Usuario"
    private var userEmail: String = ""
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        labelTitleNav.config(text: "Contactar", style: StylesLabel.titleNav)
        
        viewInfoShelter.applyCardStyle()
        labelName.config(text: "", style: StylesLabel.titleHi)
        labelGmail.config(text: "", style: StylesLabel.subtitleGray2)
        
        labelReason.config(text: "Motivo", style: StylesLabel.title2)
        fieldReason.config(image: UIImage(named: ""), placeholder: "Escribe el motivo")
        
        labelMessage.config(text: "Mensaje", style: StylesLabel.title2)
        fieldMessage.config(placeholder: "Escribe tu mensaje...")
        
        buttonSend.config(text: "Enviar", style: StylesButton.primary)

        
        configureShelterUI()
        loadMyProfile()
        hideKeyboardWhenTappedAround()
    }
    
    private func configureShelterUI() {
        guard let shelter else { return }

        labelName.text = shelter.name
        labelGmail.text = shelter.email

        if let urlString = shelter.photoURL, let url = URL(string: urlString) {
            imageShelter.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "house.fill"),
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            )
        } else {
            imageShelter.image = UIImage(systemName: "house.fill")
        }
    }

    private func loadMyProfile() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let email = session.user.email ?? ""
                self.userEmail = email

                // Si quieres name real desde profiles:
                if let dto = try await profileService.fetchMyProfile(email: email) {
                    let fullName = dto.name ?? "Usuario"
                        self.userName = fullName
                } else {
                    self.userName = email.components(separatedBy: "@").first ?? "Usuario"
                }

            } catch {
                print("❌ loadMyProfile error:", error)
                self.userName = "Usuario"
            }
        }
    }
    

    @IBAction func sendClicked(_ sender: Any) {
        guard let shelter else { return }

        let reason = fieldReason.getText().trimmingCharacters(in: .whitespacesAndNewlines)
        let message = fieldMessage.getText().trimmingCharacters(in: .whitespacesAndNewlines)

        let subject = "WalkPaws - \(reason)"
        let body =
    """
    Nuevo mensaje para el refugio: \(shelter.name)

    Usuario: \(userName)
    Email: \(userEmail)

    Motivo:
    \(reason)

    Mensaje:
    \(message)
    """

        openSupportEmail(to: shelter.email, subject: subject, body: body)
    }

    private func sendContactEmailNoToken(
        shelterEmail: String,
        shelterName: String,
        userName: String,
        userEmail: String,
        reason: String,
        message: String,
        completion: @escaping (Bool) -> Void
    ) {
        let url = URL(string: "https://nbcxqbooivodgzjtmqgf.supabase.co/functions/v1/send_contact_email")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // SOLO apikey (publishable)
        let apikey = "sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A"
        request.setValue(apikey, forHTTPHeaderField: "apikey")

        let body: [String: Any] = [
            "toEmail": shelterEmail,
            "toName": shelterName,
            "userName": userName,
            "userEmail": userEmail,
            "reason": reason,
            "message": message
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ sendContactEmailNoToken error:", error)
                completion(false)
                return
            }

            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🌐 status:", status)

            if status != 200 {
                if let data {
                    print("❌ body:", String(data: data, encoding: .utf8) ?? "nil")
                }
                completion(false)
                return
            }

            completion(true)
        }.resume()
    }
    
    private func openEmailComposer(to: String, subject: String, body: String) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // 1) Intentar abrir Gmail
        if let gmailURL = URL(string: "googlegmail://co?to=\(to)&subject=\(encodedSubject)&body=\(encodedBody)"),
           UIApplication.shared.canOpenURL(gmailURL) {
            UIApplication.shared.open(gmailURL)
            return
        }

        // 2) Si no hay Gmail, abrir Apple Mail
        if let mailURL = URL(string: "mailto:\(to)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(mailURL)
        }
    }
    
    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}
