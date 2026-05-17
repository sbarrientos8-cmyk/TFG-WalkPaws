//
//  MyWalkCell.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 1/3/26.
//

import UIKit
import MapKit
import CoreLocation

final class MyWalkCell: UITableViewCell {

    @IBOutlet weak var viewBackground: UIView!

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var imageDog: CircleImageView!
    @IBOutlet weak var labelShelter: UILabel!
    @IBOutlet weak var labelDog: UILabel!
    @IBOutlet weak var labelPlace: UILabel!

    @IBOutlet weak var viewTime: UIView!
    @IBOutlet weak var labelTime: UILabel!

    @IBOutlet weak var viewKm: UIView!
    @IBOutlet weak var labelKm: UILabel!

    @IBOutlet weak var viewPoints: UIView!
    @IBOutlet weak var labelPoints: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        viewBackground.applyCardStyle()
        
        labelShelter.config(text: "", style: StylesLabel.title1Name)
        labelDog.config(text: "", style: StylesLabel.title1Name)
        labelPlace.config(text: "", style: StylesLabel.subtitleGray2)
        
        viewTime.applyCardStyle(cornerRadius: 15)
        viewTime.backgroundColor = Colors.brownLight
        labelTime.config(text: "", style: StylesLabel.description)
        
        viewKm.applyCardStyle(cornerRadius: 15)
        viewKm.backgroundColor = Colors.greenLight2
        labelKm.config(text: "", style: StylesLabel.description)
        
        viewPoints.applyCardStyle(cornerRadius: 15)
        viewPoints.backgroundColor = Colors.yellow
        labelPoints.config(text: "", style: StylesLabel.description)
        
        mapView.isUserInteractionEnabled = false
        mapView.delegate = self
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
    }

    func config(walk: WalkRowDTO, shelterName: String,dogName: String,city: String?,country: String?,dogPhotoURL: String?) {
        // Textos
        labelShelter.text = shelterName
        labelDog.text = dogName

        let place = [city, country].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                                   .filter { !$0.isEmpty }
                                   .joined(separator: ", ")
        labelPlace.text = place.isEmpty ? "—" : place

        // Tiempo
        let secs = walk.duration_seconds ?? 0
        let mm = secs / 60
        let ss = secs % 60
        labelTime.text = String(format: "%02d:%02d", mm, ss)

        // Km
        labelKm.text = String(format: "%.2f km", walk.distance_km)

        // Puntos
        labelPoints.text = "\(walk.points_earned) \(L10n.tr("points"))"

        // Imagen perro
        if let dogPhotoURL, let url = URL(string: dogPhotoURL) {
            loadImage(url: url)
        }

        // Mapa + ruta
        drawRoute(walk: walk)
    }

    private func drawRoute(walk: WalkRowDTO) {
        mapView.removeOverlays(mapView.overlays)

        guard let coords = walk.route_simplified?.coords, coords.count >= 2 else {
            // fallback (p.ej. Madrid)
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
                span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            )
            mapView.setRegion(region, animated: false)
            return
        }

        // coords: [[lon, lat]]
        let polyCoords: [CLLocationCoordinate2D] = coords.compactMap { pair in
            guard pair.count == 2 else { return nil }
            return CLLocationCoordinate2D(latitude: pair[1], longitude: pair[0])
        }

        guard polyCoords.count >= 2 else { return }

        let polyline = MKPolyline(coordinates: polyCoords, count: polyCoords.count)
        mapView.addOverlay(polyline)

        mapView.setVisibleMapRect(
            polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24),
            animated: false
        )
    }

    private func loadImage(url: URL) {
        // Simple (sin caché). Si quieres, lo mejor es meter caché.
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let img = UIImage(data: data)
                await MainActor.run {
                    self.imageDog.image = img
                }
            } catch {
                // si falla, no hacemos nada
            }
        }
    }
}

// MARK: - MKMapViewDelegate
extension MyWalkCell: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let poly = overlay as? MKPolyline {
            let r = MKPolylineRenderer(polyline: poly)
            r.strokeColor = .systemRed
            r.lineWidth = 4
            r.lineJoin = .round
            r.lineCap = .round
            return r
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
