//
//  FMDelegateCtrl.swift
//  faeBeta
//
//  Created by Yue on 11/16/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation

extension FaeMapViewController: MainScreenSearchDelegate, PinDetailDelegate, PinMenuDelegate, LeftSlidingMenuDelegate {
    
    // MainScreenSearchDelegate
    func animateToCameraFromMainScreenSearch(_ coordinate: CLLocationCoordinate2D) {
        let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 17)
        self.faeMapView.animate(to: camera)
        let currentZoomLevel = faeMapView.camera.zoom
        let powFactor: Double = Double(21 - currentZoomLevel)
        let coorDistance: Double = 0.0004*pow(2.0, powFactor)*111
        self.updateTimerForLoadRegionPin(radius: Int(coorDistance*1500))
        self.updateTimerForSelfLoc(radius: Int(coorDistance*1500))
        filterCircleAnimation()
        appBackFromBackground()
    }
    
    // PinDetailDelegate
    func dismissMarkerShadow(_ dismiss: Bool) {
        print("back from comment pin detail")
        let currentZoomLevel = faeMapView.camera.zoom
        let powFactor: Double = Double(21 - currentZoomLevel)
        let coorDistance: Double = 0.0004*pow(2.0, powFactor)*111
        self.updateTimerForSelfLoc(radius: Int(coorDistance*1500))
        self.renewSelfLocation()
        if !dismiss {
            self.markerBackFromPinDetail.map = nil
        }
        else {
            
        }
        animateMapFilterArrow()
        filterCircleAnimation()
        appBackFromBackground()
    }
    // PinDetailDelegate
    func animateToCamera(_ coordinate: CLLocationCoordinate2D, pinID: String) {
        let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 17)
        self.faeMapView.camera = camera
    }
    // PinDetailDelegate
    func changeIconImage(marker: GMSMarker, type: String, status: String) {
        var pinData = marker.userData as! [String: AnyObject]
        pinData["status"] = status as AnyObject?
        marker.icon = pinIconSelector(type: type, status: status)
    }

    // PinMenuDelegate
    func sendPinGeoInfo(pinID: String, type: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 17)
        faeMapView.camera = camera
        animatePinWhenItIsCreated(pinID: pinID, type: type)
        let currentZoomLevel = faeMapView.camera.zoom
        let powFactor: Double = Double(21 - currentZoomLevel)
        let coorDistance: Double = 0.0004*pow(2.0, powFactor)*111
        self.updateTimerForSelfLoc(radius: Int(coorDistance*1500))
        self.renewSelfLocation()
        animateMapFilterArrow()
        filterCircleAnimation()
        appBackFromBackground()
    }
    // PinMenuDelegate
    func whenDismissPinMenu() {
        let currentZoomLevel = faeMapView.camera.zoom
        let powFactor: Double = Double(21 - currentZoomLevel)
        let coorDistance: Double = 0.0004*pow(2.0, powFactor)*111
        self.updateTimerForSelfLoc(radius: Int(coorDistance*1500))
        self.renewSelfLocation()
        animateMapFilterArrow()
        filterCircleAnimation()
        appBackFromBackground()
    }
    
    // LeftSlidingMenuDelegate
    func userInvisible(isOn: Bool) {
        if !isOn {
            self.faeMapView.isMyLocationEnabled = false
            self.renewSelfLocation()
            if userStatus != 5  {
                loadPositionAnimateImage()
                getSelfAccountInfo()
            }
            return
        }
        if userStatus == 5 {
            self.invisibleMode()
            self.faeMapView.isMyLocationEnabled = true
            if self.myPositionOutsideMarker_1 != nil {
                self.myPositionOutsideMarker_1.isHidden = true
            }
            if self.myPositionOutsideMarker_2 != nil {
                self.myPositionOutsideMarker_2.isHidden = true
            }
            if self.myPositionOutsideMarker_3 != nil {
                self.myPositionOutsideMarker_3.isHidden = true
            }
            if self.myPositionIcon != nil {
                self.myPositionIcon.isHidden = true
            }
        }
    }
    // LeftSlidingMenuDelegate
    func jumpToMoodAvatar() {
        let moodAvatarVC = MoodAvatarViewController()
        self.present(moodAvatarVC, animated: true, completion: nil)
    }
    // LeftSlidingMenuDelegate
    func logOutInLeftMenu() {
        self.jumpToWelcomeView(animated: true)
    }
    // LeftSlidingMenuDelegate
    func jumpToFaeUserMainPage() {
        self.jumpToMyFaeMainPage()
    }
    
}
