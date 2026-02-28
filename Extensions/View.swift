//
//  View.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 14/2/26.
//

import UIKit

extension UIView {

    func applyCardStyle(
        cornerRadius: CGFloat = 12,
        shadowOpacity: Float = 0.1,
        shadowOffset: CGSize = CGSize(width: 0, height: 6),
        shadowRadius: CGFloat = 12
    ) {
        layer.cornerRadius = cornerRadius

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius
        layer.masksToBounds = false
    }

    func updateShadowPath(cornerRadius: CGFloat) {
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: cornerRadius
        ).cgPath
    }
    
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController { return vc }
            responder = r.next
        }
        return nil
    }
}

extension UIViewController {

    func openSupportEmail(to: String, subject: String, body: String) {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // 1) Intentar Gmail
        if let gmailURL = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)"),
           UIApplication.shared.canOpenURL(gmailURL) {
            UIApplication.shared.open(gmailURL, options: [:], completionHandler: nil)
            return
        }

        // 2) Intentar Mail (mailto)
        if let mailURL = URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)"),
           UIApplication.shared.canOpenURL(mailURL) {
            UIApplication.shared.open(mailURL, options: [:], completionHandler: nil)
            return
        }

        // 3) Fallback (no hay apps de correo)
        let alert = UIAlertController(
            title: "No se puede abrir el correo",
            message: "No tienes una app de correo configurada (Gmail/Mail). Instala Gmail o configura Mail en el dispositivo.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

open class CircleImageView: UIImageView {

    public override func layoutSubviews() {
        super.layoutSubviews()

        clipsToBounds = true
        contentMode = .scaleAspectFill

        let side = min(bounds.width, bounds.height)
        layer.cornerRadius = side / 2
    }
}
