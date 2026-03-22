//
//  WalkingController.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 1/3/26.
//

import UIKit
import MapKit
import CoreLocation

import UIKit
import MapKit
import CoreLocation

final class WalkingController: UIViewController {

    // MARK: - Outlets (XIB / Storyboard)
    @IBOutlet weak var viewContent: UIView!
    @IBOutlet weak var imageDog: UIImageView!

    @IBOutlet weak var labelShelterT: UILabel!
    @IBOutlet weak var labelShelterD: UILabel!
    @IBOutlet weak var labelDogT: UILabel!
    @IBOutlet weak var labelDogD: UILabel!

    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var labelKm: UILabel!

    @IBOutlet weak var viewCenter: CircleImageView!
    @IBOutlet weak var buttonFinished: UIButton!

    @IBOutlet weak var viewBottom: BottomBar!
    @IBOutlet weak var mapView: MKMapView!

    // MARK: - Datos que llegan
    private var startedAt = Date()
    private var endedAt: Date?

    var selectedShelterId: UUID?
    var selectedDogId: UUID?

    var selectedShelterName: String = ""
    var selectedDogName: String = ""

    // MARK: - Location + tracking
    private var shelterLocation: CLLocation?
    private let locationManager = CLLocationManager()
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var lastLocation: CLLocation?
    private var totalDistanceMeters: Double = 0
    private let minDistanceToSaveMeters: Double = 20
    private let maxDistanceToFinishMeters: Double = 1000

    // MARK: - Timer
    private var timer: Timer?
    private var elapsedSeconds: Int = 0
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewContent.applyCardStyle()
        viewContent.alpha = 0.75
        
        labelShelterT.config(text: "\(String(localized: "shelter")): ", style: StylesLabel.titleBlack)

        labelShelterD.config(text: "", style: StylesLabel.subtitleBlack)
        
        labelDogT.config(text: "\(String(localized: "dog")): ", style: StylesLabel.titleBlack)

        labelDogD.config(text: "", style: StylesLabel.subtitleBlack)
        
        labelTime.config(text: "", style: StylesLabel.titleBlack)
        labelKm.config(text: "", style: StylesLabel.titleBlack)
        
        viewCenter.alpha = 0.75
        buttonFinished.config(text: String(localized: "finish_walk"), style: StylesButton.primary)

        startedAt = Date()

        setupUIFromData()
        setupMap()
        setupLocation()
        startTimer()
        hideKeyboardWhenTappedAround()

        Task { [weak self] in
            guard let self else { return }
            await self.loadDogImageIfPossible()
        }
        
        Task { [weak self] in
            guard let self else { return }
            await self.loadShelterLocation()
        }
    }
    
    private func loadShelterLocation() async {
        guard let shelterId = selectedShelterId else { return }

        struct ShelterCoordDTO: Decodable {
            let latitude: Double?
            let longitude: Double?
        }

        do {
            let dto: ShelterCoordDTO = try await SupabaseManager.shared.client
                .from("shelters")
                .select("latitude, longitude")
                .eq("id", value: shelterId.uuidString)
                .single()
                .execute()
                .value

            guard let lat = dto.latitude, let lon = dto.longitude else { return }

            await MainActor.run {
                self.shelterLocation = CLLocation(latitude: lat, longitude: lon)
            }
        } catch {
            print("❌ loadShelterLocation error:", error)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            stopTracking()
        }
    }

    // MARK: - UI (solo asignar textos)
    private func setupUIFromData() {
        labelShelterD.text = selectedShelterName
        labelDogD.text = selectedDogName

        labelTime.text = "00:00"
        labelKm.text = "0.00 km"
    }

    // MARK: - Map
    private func setupMap() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }

    // MARK: - Location
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 5
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // MARK: - Timer
    private func startTimer() {
        timer?.invalidate()
        elapsedSeconds = 0
        updateTimeLabel()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
            self.updateTimeLabel()
        }
    }

    private func updateTimeLabel() {
        let mm = elapsedSeconds / 60
        let ss = elapsedSeconds % 60
        labelTime.text = String(format: "%02d:%02d", mm, ss)
    }

    private func updateKmLabel() {
        let km = totalDistanceMeters / 1000.0
        labelKm.text = String(format: "%.2f km", km)
    }

    private func stopTracking() {
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Supabase save (tu lógica existente)
    private func buildRouteSimplified() -> RouteSimplified? {
        guard routeCoordinates.count >= 2 else { return nil }
        let coords = routeCoordinates.map { [$0.longitude, $0.latitude] }
        return RouteSimplified(coords: coords)
    }

    private func calculatePoints(distanceKm: Double) -> Int {
        max(0, Int(distanceKm * 10.0))
    }

    private func isoString(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func saveWalkToSupabase() async {
        guard let shelterId = selectedShelterId,
              let dogId = selectedDogId else {
            print("❌ Falta shelterId o dogId")
            return
        }

        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let profileId = session.user.id

            let ended = Date()
            self.endedAt = ended

            let distanceKm = totalDistanceMeters / 1000.0
            let points = calculatePoints(distanceKm: distanceKm)

            let walkRow = WalkInsertRow(
                shelter_id: shelterId,
                dog_id: dogId,
                profile_id: profileId,
                status: "finished",
                started_at: isoString(startedAt),
                ended_at: isoString(ended),
                duration_seconds: elapsedSeconds,
                distance_km: distanceKm,
                points_earned: points,
                route_simplified: buildRouteSimplified()
            )

            let created: WalkCreatedDTO = try await SupabaseManager.shared.client
                .from("walks")
                .insert(walkRow)
                .select("id")
                .single()
                .execute()
                .value

            let walkId = created.id

            let pointsRows: [WalkPointInsertRow] = routeCoordinates.enumerated().map { (idx, c) in
                WalkPointInsertRow(
                    walk_id: walkId,
                    seq: idx,
                    lat: c.latitude,
                    lon: c.longitude
                )
            }

            if !pointsRows.isEmpty {
                _ = try await SupabaseManager.shared.client
                    .from("walk_points")
                    .insert(pointsRows)
                    .execute()
            }

            print("✅ Walk guardado:", walkId)

        } catch {
            print("❌ saveWalkToSupabase error:", error)
        }
    }

    // MARK: - Botones (XIB)
    @IBAction func centerClicked(_ sender: Any) {
        guard let coord = mapView.userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coord, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }

    @IBAction func finishedClicked(_ sender: Any) {

        let km = totalDistanceMeters / 1000.0
        let formattedDistance = String(format: "%.2f km", km)

        let maxDistanceToFinishMeters: Double = 1000

        // 1) Si NO llega al mínimo (0.3km = 300m) -> NO se guarda y aquí sí terminas el tracking
        if totalDistanceMeters < minDistanceToSaveMeters {
            stopTracking()

            let alert = UIAlertController(
                title: String(localized: "walk_too_short"),
                message: String(
                    format: String(localized: "walk_not_saved_min_distance"),
                    formattedDistance
                ),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: String(localized: "ok"), style: .default) { [weak self] _ in
                WalkSession.shared.end()
                self?.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
            return
        }

        // 2) Necesitamos coords para validar “cerca del refugio”
        guard let shelterLoc = shelterLocation, let userLoc = lastLocation else {
            let alert = UIAlertController(
                title: String(localized: "could_not_check_location"),
                message: String(localized: "could_not_finish_location_not_verified"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: String(localized: "ok"), style: .default))
            present(alert, animated: true)
            return
        }

        // 3) Si está a más de 1km -> alerta pero NO paras (sigue contando)
        let distanceToShelter = userLoc.distance(from: shelterLoc) // metros
        if distanceToShelter > maxDistanceToFinishMeters {
            let kmAway = distanceToShelter / 1000.0
            let alert = UIAlertController(
                title: String(localized: "still_far_from_shelter"),
                message: String(format: String(localized: "must_be_closer_to_finish_walk"), kmAway),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: String(localized: "ok"), style: .default))
            present(alert, animated: true)

            // ✅ IMPORTANTE: NO stopTracking() aquí
            return
        }

        // 4) Ya cumple -> mostramos resumen (yo NO pararía aquí todavía, lo paro al Guardar)
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        let formattedTime = String(format: "%02d:%02d", minutes, seconds)

        let message = String(
            format: String(localized: "walk_summary_message"),
            selectedShelterName,
            selectedDogName,
            formattedTime,
            formattedDistance,
            routeCoordinates.count
        )

        let alert = UIAlertController(
            title: String(localized: "walk_summary"),
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: "save"), style: .default) { [weak self] _ in
            guard let self else { return }
            self.stopTracking()
            Task {
                await self.saveWalkToSupabase()
                WalkSession.shared.end()
                await MainActor.run {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })

        alert.addAction(UIAlertAction(title: String(localized: "cancel"), style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Polyline
    private func redrawPolyline() {
        mapView.removeOverlays(mapView.overlays)
        guard routeCoordinates.count >= 2 else { return }
        let polyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
        mapView.addOverlay(polyline)
    }

    // MARK: - Imagen del perro
    private func loadDogImageIfPossible() async {
        guard let dogId = selectedDogId else { return }

        do {
            struct DogPhotoDTO: Decodable {
                let photo_url: String?
            }

            let dto: DogPhotoDTO = try await SupabaseManager.shared.client
                .from("dogs")
                .select("photo_url")
                .eq("id", value: dogId.uuidString)
                .single()
                .execute()
                .value

            guard let urlString = dto.photo_url,
                  let url = URL(string: urlString) else {
                print("⚠️ El perro no tiene photo_url")
                return
            }

            let (data, _) = try await URLSession.shared.data(from: url)

            await MainActor.run {
                self.imageDog.image = UIImage(data: data)
            }

        } catch {
            print("❌ loadDogImage error:", error)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension WalkingController: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            print("❌ Sin permisos de localización")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        if location.horizontalAccuracy < 0 { return }
        if location.horizontalAccuracy > 50 { return }

        if let last = lastLocation {
            let delta = location.distance(from: last)
            if delta > 0.5 && delta < 50 {
                totalDistanceMeters += delta
                updateKmLabel()
            }
        }
        lastLocation = location

        routeCoordinates.append(location.coordinate)
        redrawPolyline()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error:", error)
    }
}

// MARK: - MKMapViewDelegate
extension WalkingController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let r = MKPolylineRenderer(polyline: polyline)
            r.strokeColor = .systemRed
            r.lineWidth = 5
            r.lineJoin = .round
            r.lineCap = .round
            return r
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
