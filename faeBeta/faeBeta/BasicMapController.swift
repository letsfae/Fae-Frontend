//
//  BasicMapController.swift
//  faeBeta
//
//  Created by Yue Shen on 3/5/18.
//  Copyright © 2018 fae. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SwiftyJSON

enum MapCenter {
    case lastLocation, placeCoordinate, currentUser, specificUser
}

class BasicMapController: UIViewController, MKMapViewDelegate, CCHMapClusterControllerDelegate, CCHMapAnimator, CCHMapClusterer {
    
    // MARK: - Variables Declarations
    weak var delegate: SelectLocationDelegate?
    
    // Top Bar
    var uiviewTopBar: UIView!
    var lblTopBarCenter: FaeLabel!
    var lblTopBarSearch: FaeLabel!
    var btnBack: UIButton!
    
    // Screen Buttons
    var faeMapView: FaeMapView!
    var btnLocat: FMLocateSelf!
    var btnZoom: FMZoomButton!
    
    // Place pins data management
    var placeClusterManager: CCHMapClusterController!
    var uiviewPlaceBar = FMPlaceInfoBar()
    
    // Boolean values
    var fullyLoaded = false // if all ui components are fully loaded
    var PIN_INSTANT_SHOWUP = false
    
    var mapCenter: MapCenter = .currentUser
    var placePin: PlacePin?
    var userPin: UserPin?
    
    // Place Pin Control
    var selectedPlaceAnno: PlacePinAnnotationView?
    var selectedPlace: FaePinAnnotation?
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMapView()
        loadButtons()
        fullyLoaded = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - Loading Parts
    
    func loadMapView() {
        faeMapView = FaeMapView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        faeMapView.showsUserLocation = true
        faeMapView.delegate = self
        faeMapView.showsPointsOfInterest = false
        faeMapView.showsCompass = true
        faeMapView.tintColor = UIColor._2499090()
        view.addSubview(faeMapView)
        
        placeClusterManager = CCHMapClusterController(mapView: faeMapView)
        placeClusterManager.delegate = self
        placeClusterManager.cellSize = 100
        placeClusterManager.maxZoomLevelForClustering = 0
        placeClusterManager.clusterer = self
        placeClusterManager.animator = self
        
        switch mapCenter {
        case .currentUser:
            setCamera(center: LocManager.shared.curtLoc.coordinate)
        case .lastLocation:
            if let loc = Key.shared.lastChosenLoc {
                setCamera(center: loc)
            } else {
                setCamera(center: LocManager.shared.curtLoc.coordinate)
            }
        case .placeCoordinate:
            guard let place = placePin else { return }
            setCamera(center: place.coordinate)
            break
        case .specificUser:
            
            break
        }
    }
    
    func setCamera(center: CLLocationCoordinate2D) {
        let camera = faeMapView.camera
        camera.centerCoordinate = center
        let viewDistance: CLLocationDistance = 500
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(camera.centerCoordinate, viewDistance, viewDistance)
        faeMapView.setRegion(coordinateRegion, animated: false)
    }
    
    func loadButtons() {
        btnLocat = FMLocateSelf()
        btnLocat.removeTarget(nil, action: nil, for: .touchUpInside)
        btnLocat.addTarget(self, action: #selector(self.actionSelfPosition(_:)), for: .touchUpInside)
        view.addSubview(btnLocat)
        view.addConstraintsWithFormat("H:[v0(60)]-21-|", options: [], views: btnLocat)
        view.addConstraintsWithFormat("V:[v0(60)]-\(13+device_offset_bot_main)-|", options: [], views: btnLocat)

        btnZoom = FMZoomButton()
        btnZoom.frame.origin.y = screenHeight - 60 - device_offset_bot_main - 13
        btnZoom.mapView = faeMapView
        view.addSubview(btnZoom)
        btnZoom.isHidden = true
        
        faeMapView.compassOffset = 73 + device_offset_bot_main - device_offset_bot_main //134
        faeMapView.layoutSubviews()
    }
    
    func loadTopBar() {
        uiviewTopBar = UIView()
        uiviewTopBar.backgroundColor = .white
        uiviewTopBar.layer.cornerRadius = 2
        view.addSubview(uiviewTopBar)
        view.addConstraintsWithFormat("H:|-7-[v0]-7-|", options: [], views: uiviewTopBar)
        view.addConstraintsWithFormat("V:|-\(23+device_offset_top)-[v0(48)]", options: [], views: uiviewTopBar)
        addShadow(view: uiviewTopBar, opa: 0.5, offset: CGSize.zero, radius: 3)
        
        btnBack = UIButton()
        btnBack.setImage(#imageLiteral(resourceName: "navigationBack"), for: .normal)
        btnBack.addTarget(self, action: #selector(actionBack(_:)), for: .touchUpInside)
        uiviewTopBar.addSubview(btnBack)
        uiviewTopBar.addConstraintsWithFormat("H:|-1-[v0(38.5)]", options: [], views: btnBack)
        uiviewTopBar.addConstraintsWithFormat("V:|-0-[v0]-0-|", options: [], views: btnBack)
    }
    
    func loadPlaceInfoBar() {
        view.addSubview(uiviewPlaceBar)
    }
    
    // MARK: - MKMapDelegate
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view is PlacePinAnnotationView {
            tapPlacePin(didSelect: view)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            let identifier = "self_selected_mode"
            var anView: SelfAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? SelfAnnotationView {
                dequeuedView.annotation = annotation
                anView = dequeuedView
            } else {
                anView = SelfAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            return anView
        } else if annotation is CCHMapClusterAnnotation {
            guard let clusterAnn = annotation as? CCHMapClusterAnnotation else { return nil }
            guard var firstAnn = clusterAnn.annotations.first as? FaePinAnnotation else { return nil }
            if firstAnn.type == .place {
                if let sPlace = selectedPlace {
                    if faeBeta.coordinateEqual(clusterAnn.coordinate, sPlace.coordinate) {
                        firstAnn = sPlace
                    }
                }
                clusterAnn.representative = firstAnn
                return viewForPlace(annotation: annotation, first: firstAnn)
            } else if firstAnn.type == .location {
                return viewForLocation(annotation: annotation, first: firstAnn)
            }
        } else if annotation is AddressAnnotation {
            guard let addressAnno = annotation as? AddressAnnotation else { return nil }
            let identifier = addressAnno.isStartPoint ? "start_point" : "destination"
            var anView: AddressAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? AddressAnnotationView {
                dequeuedView.annotation = annotation
                anView = dequeuedView
            } else {
                anView = AddressAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            anView.assignImage(addressAnno.isStartPoint ? #imageLiteral(resourceName: "icon_startpoint") : #imageLiteral(resourceName: "icon_destination"))
            return anView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        Key.shared.lastChosenLoc = mapView.centerCoordinate
        if uiviewPlaceBar.tag > 0 {
            uiviewPlaceBar.annotations = visiblePins(mapView: faeMapView, type: .place)
        }
        
    }
    
    // MARK: - CCHMapClusterDelegate
    
    func mapClusterController(_ mapClusterController: CCHMapClusterController!, didAddAnnotationViews annotationViews: [Any]!) {
        for annotationView in annotationViews {
            if let anView = annotationView as? PlacePinAnnotationView {
                if PIN_INSTANT_SHOWUP { // immediatelly show up
                    anView.imgIcon.frame = CGRect(x: -8, y: -5, width: 56, height: 56)
                    anView.alpha = 1
                } else {
                    anView.alpha = 0
                    anView.imgIcon.frame = CGRect(x: 20, y: 46, width: 0, height: 0)
                    let delay: Double = Double(arc4random_uniform(50)) / 100 // Delay 0-1 seconds, randomly
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.75, delay: delay, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                            anView.imgIcon.frame = CGRect(x: -8, y: -5, width: 56, height: 56)
                            anView.alpha = 1
                        }, completion: nil)
                    }
                }
            } else if let anView = annotationView as? LocPinAnnotationView {
                if PIN_INSTANT_SHOWUP {
                    anView.alpha = 1
                } else {
                    anView.alpha = 0
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.2, animations: {
                            anView.alpha = 1
                        })
                    }
                }
            } else if let anView = annotationView as? MKAnnotationView {
                anView.alpha = 0
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.4, animations: {
                        anView.alpha = 1
                    })
                }
            }
        }
    }
    
    func mapClusterController(_ mapClusterController: CCHMapClusterController!, willRemoveAnnotations annotations: [Any]!, withCompletionHandler completionHandler: (() -> Void)!) {
        
        UIView.animate(withDuration: 0.4, animations: {
            for annotation in annotations {
                if let anno = annotation as? MKAnnotation {
                    if let anView = self.faeMapView.view(for: anno) {
                        anView.alpha = 0
                    }
                }
            }
        }) { _ in
            if completionHandler != nil { completionHandler() }
        }
    }
    
    func mapClusterController(_ mapClusterController: CCHMapClusterController!, willReuse mapClusterAnnotation: CCHMapClusterAnnotation!, fullAnnotationSet annotations: Set<AnyHashable>!, findSelectedPin found: Bool) {
        let firstAnn = mapClusterAnnotation.annotations.first as! FaePinAnnotation
        if firstAnn.type == .place {
            if let anView = faeMapView.view(for: mapClusterAnnotation) as? PlacePinAnnotationView {
                var pinFound = false
                if found {
                    for annotation in annotations {
                        guard let pin = annotation as? FaePinAnnotation else { continue }
                        guard let sPlace = selectedPlace else { continue }
                        if faeBeta.coordinateEqual(pin.coordinate, sPlace.coordinate) {
                            pinFound = true
                            let icon = UIImage(named: "place_map_\(pin.category_icon_id)s") ?? #imageLiteral(resourceName: "place_map_48s")
                            anView.assignImage(icon)
                        }
                    }
                    if !pinFound {
                        let firstAnn = mapClusterAnnotation.annotations.first as! FaePinAnnotation
                        anView.assignImage(firstAnn.icon)
                    }
                } else {
                    let firstAnn = mapClusterAnnotation.annotations.first as! FaePinAnnotation
                    anView.assignImage(firstAnn.icon)
                }
                anView.superview?.bringSubview(toFront: anView)
            }
        } else if firstAnn.type == .location {
            if let anView = faeMapView.view(for: mapClusterAnnotation) as? LocPinAnnotationView {
                anView.assignImage(firstAnn.icon)
            }
        }
    }
    
    func mapClusterController(_ mapClusterController: CCHMapClusterController!, coordinateForAnnotations annotations: Set<AnyHashable>!, in mapRect: MKMapRect) -> IsSelectedCoordinate {
        guard let firstAnn = annotations.first as? FaePinAnnotation else {
            return IsSelectedCoordinate(isSelected: false, coordinate: CLLocationCoordinate2DMake(0, 0))
        }
        return IsSelectedCoordinate(isSelected: false, coordinate: firstAnn.coordinate)
    }
    
    // MARK: - Place & Location Managements
    
    func viewForPlace(annotation: MKAnnotation, first: FaePinAnnotation) -> MKAnnotationView {
        let identifier = "place"
        var anView: PlacePinAnnotationView
        if let dequeuedView = faeMapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? PlacePinAnnotationView {
            dequeuedView.annotation = annotation
            anView = dequeuedView
        } else {
            anView = PlacePinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        anView.iconIndex = first.category_icon_id
        anView.assignImage(first.icon)
        if first.isSelected {
            let icon = UIImage(named: "place_map_\(anView.iconIndex)s") ?? #imageLiteral(resourceName: "place_map_48s")
            anView.assignImage(icon)
            anView.optionsReady = true
            anView.optionsOpened = false
            selectedPlaceAnno = anView
            anView.superview?.bringSubview(toFront: anView)
            anView.zPos = 199
        }
        return anView
    }
    
    func tapPlacePin(didSelect view: MKAnnotationView) {
        guard let cluster = view.annotation as? CCHMapClusterAnnotation else { return }
        guard var firstAnn = cluster.representative as? FaePinAnnotation else { return }
        guard let anView = view as? PlacePinAnnotationView else { return }
        if let sPlace = selectedPlace {
            if faeBeta.coordinateEqual(cluster.coordinate, sPlace.coordinate) {
                firstAnn = sPlace
            }
        }
        let idx = firstAnn.category_icon_id
        firstAnn.icon = UIImage(named: "place_map_\(idx)s") ?? #imageLiteral(resourceName: "place_map_48")
        anView.assignImage(firstAnn.icon)
        selectedPlace = firstAnn
        selectedPlaceAnno = anView
        selectedPlaceAnno?.superview?.bringSubview(toFront: selectedPlaceAnno!)
        selectedPlaceAnno?.zPos = 199
        guard firstAnn.type == .place else { return }
        uiviewPlaceBar.show()
        uiviewPlaceBar.resetSubviews()
        uiviewPlaceBar.tag = 1
        mapView(faeMapView, regionDidChangeAnimated: false)
        uiviewPlaceBar.loadingData(current: cluster)
    }
    
    // MARK: - Location Pin Managements
    
    func viewForLocation(annotation: MKAnnotation, first: FaePinAnnotation) -> MKAnnotationView {
        let identifier = "location"
        var anView: LocPinAnnotationView
        if let dequeuedView = faeMapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? LocPinAnnotationView {
            dequeuedView.annotation = annotation
            anView = dequeuedView
        } else {
            anView = LocPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        anView.assignImage(first.icon)
        anView.imgIcon.frame = CGRect(x: 0, y: 0, width: 56, height: 56)
        anView.alpha = 1
        anView.optionsReady = true
        return anView
    }
    
    // MARK: - Actions in Controller
    
    @objc func actionBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: false)
    }
    
    @objc func actionSelfPosition(_ sender: UIButton!) {
        let camera = faeMapView.camera
        camera.centerCoordinate = LocManager.shared.curtLoc.coordinate
        faeMapView.setCamera(camera, animated: false)
    }
    
    // MARK: - Auxiliary Map Functions
    
    func removePlacePins(pins: [FaePinAnnotation], _ completion: (() -> ())? = nil) {
        //let placesNeedToRemove = faePlacePins.filter({ $0 != selectedPlace })
        placeClusterManager.removeAnnotations(pins) {
            completion?()
        }
    }
    
    // MARK: - 辅助函数
}
