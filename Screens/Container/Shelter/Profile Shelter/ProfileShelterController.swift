//
//  ProfileShelterController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 13/2/26.
//

import UIKit
import MapKit

class ProfileShelterController: UIViewController
{
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var imageProfile: UIImageView!
    @IBOutlet weak var viewProfile: UIView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var labelUbication: UILabel!
    
    @IBOutlet weak var buttonSeeMap: UIButton!
    @IBOutlet weak var buttonSeeDogs: UIButton!
    @IBOutlet weak var buttonContact: UIButton!
    
    @IBOutlet weak var viewMap: MKMapView!
    @IBOutlet weak var viewMapShadow: UIView!
    
    @IBOutlet weak var labelCoordinates: UILabel!
    @IBOutlet weak var labelDirection: UILabel!
    @IBOutlet weak var labelPhone: UILabel!
    @IBOutlet weak var labelEmail: UILabel!
    
    var shelter: ShelterModel?
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        // Añadir sombras
        viewProfile.updateShadowPath(cornerRadius: 10)
        viewMapShadow.updateShadowPath(cornerRadius: 10)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        labelTitle.config(text: "Refugio", style: StylesLabel.titleNav)
        
        viewProfile.applyCardStyle(cornerRadius: 10, shadowOpacity: 0.12, shadowOffset: CGSize(width: 0, height: 8), shadowRadius: 16)
        imageProfile.layer.cornerRadius = 10
        imageProfile.clipsToBounds = true
        
        imageProfile.contentMode = .scaleAspectFill
        labelName.config(text: "", style: StylesLabel.title)
        labelDescription.config(text: "", style: StylesLabel.subtitle)
        labelUbication.config(text: "", style: StylesLabel.subtitleGray)
        
        buttonSeeMap.configWithIcon(text: "Ver mapa", image: UIImage(named: "ubication"), style: StylesButton.secondaryGreen, withShadow: true)
        buttonSeeDogs.configWithIcon(text: "Ver perros", image: UIImage(named: "footprint"), style: StylesButton.secondaryWhite, withShadow: true)
        buttonContact.configWithIcon(text: "Contactar", image: UIImage(named: "contact"), style: StylesButton.secondaryWhite, withShadow: true)
        
        viewMapShadow.applyCardStyle(cornerRadius: 10, shadowOpacity: 0.12, shadowOffset: CGSize(width: 0, height: 8), shadowRadius: 16)
        viewMap.layer.cornerRadius = 10
        viewMap.clipsToBounds = true

        
        labelCoordinates.config(text: "", style: StylesLabel.subtitleGray)
        labelDirection.config(text: "", style: StylesLabel.subtitleGray)
        labelPhone.config(text: "", style: StylesLabel.subtitleGreen)
        labelEmail.config(text: "", style: StylesLabel.subtitleGreen)

        fillUI()
        setupMap()
        
        hideKeyboardWhenTappedAround()
    }
    
    private func loadImage(from url: URL)
    {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self else { return }
            guard let data, let image = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                self.imageProfile.image = image
            }
        }.resume()
    }

    private func fillUI()
    {
        guard let shelter else { return }

        labelName.text = shelter.name
        labelDescription.text = shelter.description
        labelUbication.text = shelter.locationText
        
        if let coordinate = shelter.coordinate {
            labelCoordinates.text = "Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)"
        } else {
            labelCoordinates.text = "Sin ubicación"
        }
        labelDirection.text = shelter.formattedAddress
        labelPhone.text = shelter.phone
        labelEmail.text = shelter.email

        if let urlString = shelter.photoURL, let url = URL(string: urlString) {
            loadImage(from: url)
        } else {
            imageProfile.image = UIImage(systemName: "house.fill")
        }
    }
    
    private func setupMap() {
        guard let shelter, let coordinate = shelter.coordinate else {
            viewMap.isHidden = true
            return
        }

        viewMap.isHidden = false

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        viewMap.setRegion(region, animated: false)

        viewMap.removeAnnotations(viewMap.annotations)

        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        pin.title = shelter.name
        pin.subtitle = shelter.formattedAddress ?? shelter.locationText
        viewMap.addAnnotation(pin)
    }
    
    @IBAction func backClicked(_ sender: Any)
    {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func listDogsClicked(_ sender: Any) {
        guard let shelterId = shelter?.id else { return }

        let vc = DogController(nibName: "DogController", bundle: nil)
        vc.shelterId = shelterId
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func contactClicked(_ sender: Any)
    {
        let vc = ContactShelterController(nibName: "ContactShelterController", bundle: nil)
        vc.shelter = ShelterContactInfo(
            name: shelter?.name ?? "",
            email: shelter?.email ?? "",
            photoURL: shelter?.photoURL
        )
        navigationController?.pushViewController(vc, animated: true)
    }
    
}
