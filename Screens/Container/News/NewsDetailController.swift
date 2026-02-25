//
//  NewsDetailController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 25/2/26.
//

import UIKit
import SDWebImage

class NewsDetailController: UIViewController {
    
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var labelTitleNav: UILabel!
    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var labelTextShort: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var viewImage: UIView!
    @IBOutlet weak var labelDescription: UILabel!
    
    var news: NewsModel?
    
    private var isImageZoomed = false
    private var overlayView: UIView?
    private var zoomImageView: UIImageView?
    private var originalImageFrameInWindow: CGRect = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.backgroundColor = Colors.greenField.withAlphaComponent(0.1)
        labelTitleNav.config(text: "Detalle de la Publicación", style: StylesLabel.titleNav)

        labelName.config(text: "", style: StylesLabel.title2Name)
        labelTime.config(text: "", style: StylesLabel.subtitleGray2)
        labelTextShort.config(text: "", style: StylesLabel.title2)
        imageView.layer.cornerRadius = 7
        labelDescription.config(text: "", style: StylesLabel.subtitleBlack)

        
        configureUI()
        setupImageTap()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageProfile.layer.cornerRadius = imageProfile.frame.width / 2
    }

    private func configureUI() {
        guard let news else { return }
            
        labelName.text = news.authorName
        labelTextShort.text = news.shortText
        labelDescription.text = news.description
        labelTime.text = formattedDate(news.createdAt)

        // Imagen perfil
        if let avatar = news.authorAvatarUrl, let url = URL(string: avatar) {
            imageProfile.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "person.circle"),
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            )
        } else {
            imageProfile.image = UIImage(systemName: "person.circle")
        }

        // Imagen noticia (si no hay, escondes el bloque)
        if let img = news.imageUrl, let url = URL(string: img) {
            viewImage.isHidden = false
            imageView.sd_setImage(
                with: url,
                placeholderImage: UIImage(systemName: "photo"),
                options: [.continueInBackground, .retryFailed, .scaleDownLargeImages]
            )
        } else {
            viewImage.isHidden = true
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        
        let now = Date()
        let seconds = now.timeIntervalSince(date)

        if seconds < 0 { return "ahora" }
        
        let oneWeek: TimeInterval = 7 * 24 * 60 * 60
        if seconds >= oneWeek {
            let df = DateFormatter()
            df.locale = Locale(identifier: "es_ES")
            df.timeZone = .current
            df.dateFormat = "dd/MM/yyyy"
            return df.string(from: date)
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "es_ES")
            formatter.unitsStyle = .short
            return formatter.localizedString(for: date, relativeTo: now)
        }
    }
    
    @IBAction func backClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    
    // Hacer ZOOM a la imagen
    private func setupImageTap() {
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        imageView.addGestureRecognizer(tap)
    }

    @objc private func imageTapped() {
        guard news?.imageUrl != nil else { return }         // si no hay imagen, nada
        guard let window = view.window else { return }      // por si aún no está en window

        if isImageZoomed {
            shrinkImage(window: window)
        } else {
            expandImage(window: window)
        }
    }

    private func expandImage(window: UIWindow) {
        // Frame original de imageView en coordenadas de la ventana
        originalImageFrameInWindow = imageView.convert(imageView.bounds, to: window)

        // Overlay (fondo oscuro)
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        overlay.alpha = 1
        window.addSubview(overlay)
        overlayView = overlay

        // Imagen clon para animar (así no rompes constraints del XIB)
        let zoomIV = UIImageView(frame: originalImageFrameInWindow)
        zoomIV.image = imageView.image
        zoomIV.contentMode = .scaleAspectFit
        zoomIV.clipsToBounds = true
        zoomIV.layer.cornerRadius = 12
        window.addSubview(zoomIV)
        zoomImageView = zoomIV

        // Tap también en overlay para cerrar
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        overlay.addGestureRecognizer(tap)

        // Calcula tamaño “grande”
        let targetWidth = window.bounds.width * 0.92
        let targetHeight = window.bounds.height * 0.60
        let targetFrame = CGRect(
            x: (window.bounds.width - targetWidth) / 2,
            y: (window.bounds.height - targetHeight) / 2,
            width: targetWidth,
            height: targetHeight
        )

        // Animación
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
            zoomIV.frame = targetFrame
            zoomIV.layer.cornerRadius = 14
        }

        isImageZoomed = true
    }

    private func shrinkImage(window: UIWindow) {
        guard let overlay = overlayView, let zoomIV = zoomImageView else { return }

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            zoomIV.frame = self.originalImageFrameInWindow
            zoomIV.layer.cornerRadius = 12
        } completion: { _ in
            zoomIV.removeFromSuperview()
            overlay.removeFromSuperview()
            self.zoomImageView = nil
            self.overlayView = nil
            self.isImageZoomed = false
        }
    }
}
