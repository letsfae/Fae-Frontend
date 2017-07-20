//
//  UpdateMapPins.swift
//  faeBeta
//
//  Created by Yue on 8/9/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import SwiftyJSON

extension FaeMapViewController {
    
    func updateTimerForLoadRegionPin() {
        self.loadCurrentRegionPins()
        if timerLoadRegionPins != nil {
            timerLoadRegionPins.invalidate()
        }
        timerLoadRegionPins = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(self.loadCurrentRegionPins), userInfo: nil, repeats: true)
    }
    
    // MARK: -- Load Pins based on the Current Region Camera
    func loadCurrentRegionPins() {
        let coorDistance = getRadius()
        if self.boolCanUpdateSocialPin {
            self.boolCanUpdateSocialPin = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.refreshMapPins(radius: coorDistance, completion: { results in
                    self.pinMapPinsOnMap(results: results)
                    self.boolCanUpdateSocialPin = true
                })
            })
        }
    }
    
    fileprivate func refreshMapPins(radius: Double, completion: @escaping ([MapPin]) -> ()) {
        self.mapPins.removeAll()
        
        // Get screen center's coordinate
        let mapCenter = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
        let mapCenterCoordinate = faeMapView.convert(mapCenter, toCoordinateFrom: nil)
        
        // Get social pins data from Fae Back-End
        let loadPinsByZoomLevel = FaeMap()
        loadPinsByZoomLevel.whereKey("geo_latitude", value: "\(mapCenterCoordinate.latitude)")
        loadPinsByZoomLevel.whereKey("geo_longitude", value: "\(mapCenterCoordinate.longitude)")
        loadPinsByZoomLevel.whereKey("radius", value: "\(radius)")
        loadPinsByZoomLevel.whereKey("type", value: stringFilterValue)
        loadPinsByZoomLevel.whereKey("in_duration", value: "true")
        loadPinsByZoomLevel.getMapInformation { (status: Int, message: Any?) in
            if status / 100 != 2 || message == nil {
                print("[loadCurrentRegionPins] status/100 != 2")
                Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.stopMapFilterSpin), userInfo: nil, repeats: false)
                completion(self.mapPins)
                return
            }
            let mapInfoJSON = JSON(message!)
            guard let mapPinJsonArray = mapInfoJSON.array else {
                Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.stopMapFilterSpin), userInfo: nil, repeats: false)
                print("[loadCurrentRegionPins] fail to parse pin comments")
                completion(self.mapPins)
                return
            }
            if mapPinJsonArray.count <= 0 {
                Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.stopMapFilterSpin), userInfo: nil, repeats: false)
                completion(self.mapPins)
                return
            }
            self.processMapPins(results: mapPinJsonArray)
            Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.stopMapFilterSpin), userInfo: nil, repeats: false)
            completion(self.mapPins)
        }
    }
    
    fileprivate func processMapPins(results: [JSON]) {
        for result in results {
            let mapPin = MapPin(json: result)
            if self.mapPins.contains(mapPin) {
                continue
            } else {
                self.mapPins.append(mapPin)
            }
        }
    }
    
    fileprivate func pinMapPinsOnMap(results: [MapPin]) {
        for result in results {
            DispatchQueue.global(qos: .default).async {
                let pinMap = FaePinAnnotation(type: result.type)
                pinMap.id = result.pinId
                pinMap.coordinate = result.position
                pinMap.icon = self.pinIconSelector(type: result.type, status: result.status)
                pinMap.pinInfo = result as AnyObject
                DispatchQueue.main.async {
                    self.mapClusterManager.addAnnotations([pinMap], withCompletionHandler: nil)
                }
            }
        }
    }
    
    // Animation for pin logo
    func animatePinWhenItIsCreated(pinID: String, type: String) {
        tempMarker = UIImageView(frame: CGRect(x: 0, y: 0, width: 120, height: 128))
        let mapCenter = CGPoint(x: screenWidth / 2, y: screenHeight / 2 - 25.5)
        tempMarker.center = mapCenter
        if type == "comment" {
            tempMarker.image = UIImage(named: "commentMarkerWhenCreated")
        } else if type == "media" {
            tempMarker.image = UIImage(named: "momentMarkerWhenCreated")
        } else if type == "chat_room" {
            tempMarker.image = UIImage(named: "chatMarkerWhenCreated")
        }
        self.view.addSubview(tempMarker)
        markerMask = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        self.view.addSubview(markerMask)
        UIView.animate(withDuration: 0.783, delay: 0.15, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveLinear, animations: {
            self.tempMarker.frame.size.width = 48
            self.tempMarker.frame.size.height = 51
            self.tempMarker.center = mapCenter
        }, completion: { (done: Bool) in
            if done {
                self.markerMask.removeFromSuperview()
                self.loadMarkerWithpinID(pinID: pinID, type: type, tempMaker: self.tempMarker)
            }
        })
    }
    
    fileprivate func loadMarkerWithpinID(pinID: String, type: String, tempMaker: UIImageView) {
        let loadPin = FaeMap()
        loadPin.getPin(type: type, pinId: pinID) { (status: Int, message: Any?) in
            if status / 100 != 2 || message == nil {
                print("[loadMarkerWithpinID] status/100 != 2")
                return
            }
            guard let mapInfo = message else {
                print("[loadMarkerWithpinID] fail to parse pin info")
                return
            }
            let mapPinJson = JSON(mapInfo)
            // Just init an empty MapPin class instance, GET /map isn't used here.
            var mapPin = MapPin(json: mapPinJson)
            // Add the info manually here
            mapPin.pinId = Int(pinID)!
            mapPin.type = type
            mapPin.userId = mapPinJson["user_id"].intValue
            mapPin.status = "normal"
            mapPin.position.latitude = mapPinJson["geolocation"]["latitude"].doubleValue
            mapPin.position.longitude = mapPinJson["geolocation"]["longitude"].doubleValue
            self.mapPins.append(mapPin)
            let pinMap = FaePinAnnotation(type: mapPin.type)
            pinMap.icon = self.pinIconSelector(type: type, status: mapPin.status)
            pinMap.coordinate = mapPin.position
            pinMap.pinInfo = mapPin as AnyObject
            self.mapClusterManager.addAnnotations([pinMap], withCompletionHandler: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                self.tempMarker.removeFromSuperview()
            })
        }
    }
    
    func getRadius() -> Double {
        guard faeMapView != nil else { return 8000 }
        let centerCoor: CLLocationCoordinate2D = getCenterCoordinate()
        let centerLocation = CLLocation(latitude: centerCoor.latitude, longitude: centerCoor.longitude)
        let topCenterCoor: CLLocationCoordinate2D = getTopCenterCoordinate()
        let topCenterLocation = CLLocation(latitude: topCenterCoor.latitude, longitude: topCenterCoor.longitude)
        let radius: CLLocationDistance = centerLocation.distance(from: topCenterLocation) * 4
        joshprint("[getRadius]", radius)
        return 20000
    }
    
    func getCenterCoordinate() -> CLLocationCoordinate2D {
        return faeMapView.centerCoordinate
    }
    
    func getTopCenterCoordinate() -> CLLocationCoordinate2D {
        // to get coordinate from CGPoint of your map
        return faeMapView.convert(CGPoint(x: faeMapView.frame.size.width / 2.0, y: 0), toCoordinateFrom: faeMapView)
    }
    
    func pinIconSelector(type: String, status: String) -> UIImage {
        switch type {
        case "comment":
            if status == "hot" {
                return #imageLiteral(resourceName: "markerCommentHot")
            } else if status == "new" {
                return #imageLiteral(resourceName: "markerCommentNew")
            } else if status == "hotRead" {
                return #imageLiteral(resourceName: "markerCommentHotRead")
            } else if status == "read" {
                return #imageLiteral(resourceName: "markerCommentRead")
            } else {
                return #imageLiteral(resourceName: "commentPinMarker")
            }
        case "chat_room":
            if status == "hot" {
                return #imageLiteral(resourceName: "markerChatHot")
            } else if status == "new" {
                return #imageLiteral(resourceName: "markerChatNew")
            } else if status == "hotRead" {
                return #imageLiteral(resourceName: "markerChatHotRead")
            } else if status == "read" {
                return #imageLiteral(resourceName: "markerChatRead")
            } else {
                return #imageLiteral(resourceName: "chatPinMarker")
            }
        case "media":
            if status == "hot" {
                return #imageLiteral(resourceName: "markerMomentHot")
            } else if status == "new" {
                return #imageLiteral(resourceName: "markerMomentNew")
            } else if status == "hotRead" {
                return #imageLiteral(resourceName: "markerMomentHotRead")
            } else if status == "read" {
                return #imageLiteral(resourceName: "markerMomentRead")
            } else {
                return #imageLiteral(resourceName: "momentPinMarker")
            }
        default:
            return UIImage()
        }
    }
}
