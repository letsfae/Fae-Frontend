//
//  FMUpdatePlacePins.swift
//  faeBeta
//
//  Created by Yue on 3/9/17.
//  Copyright © 2017 fae. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftyJSON
import RealmSwift

extension FaeMapViewController {
    
    func updateTimerForLoadRegionPlacePin() {
        self.loadCurrentRegionPlacePins()
        if timerLoadRegionPlacePins != nil {
            timerLoadRegionPlacePins.invalidate()
        }
        timerLoadRegionPlacePins = Timer.scheduledTimer(timeInterval: 750, target: self, selector: #selector(self.loadCurrentRegionPlacePins), userInfo: nil, repeats: true)
    }
    
    func loadCurrentRegionPlacePins() {
        clearMap(type: "place", animated: true)
        let coorDistance = cameraDiagonalDistance()
        let placeAllType = allTypePlacesPin()
        if self.boolCanUpdatePlacePin {
            self.boolCanUpdatePlacePin = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.refreshPlacePins(radius: coorDistance, all: placeAllType)
                self.boolCanUpdatePlacePin = true
            })
        }
    }
    
    fileprivate func pinPlacesOnMap(results: [PlacePin]) {
        for result in results {
            let categoryList = result.category
            let iconImage = self.placesPinIconImage(categoryList: categoryList)
            let pinMap = FaePinAnnotation(type: "place", json: JSON())
            pinMap.coordinate = result.position
            pinMap.image = iconImage
            self.mapClusterManager.addAnnotations([pinMap], withCompletionHandler: nil)
        }
    }
    
    fileprivate func refreshPlacePins(radius: Int, all: Bool) {
        
        placePins.removeAll()
        placeNames.removeAll()
        
        let mapCenter = CGPoint(x: screenWidth/2, y: screenHeight/2)
        let mapCenterCoordinate = faeMapView.convert(mapCenter, toCoordinateFrom: nil)
        yelpQuery.setLatitude(lat: Double(mapCenterCoordinate.latitude))
        yelpQuery.setLongitude(lon: Double(mapCenterCoordinate.longitude))
        yelpQuery.setRadius(radius: Int(Double(radius)))
        yelpQuery.setSortRule(sort: "best_match")
        
        func checkPlaceExist(_ result: PlacePin) -> Bool {
            let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
            if placeNames.contains(latPlusLon) {
                return true
            }
            return false
        }
        
        if !all {
            yelpQuery.setResultLimit(count: 10)
            self.yelpManager.query(request: self.yelpQuery, completion: { (results) in
                self.placePins = results
                for result in results {
                    if checkPlaceExist(result) {
                        continue
                    }
                    let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
                    self.placeNames.append(latPlusLon)
                }
                self.pinPlacesOnMap(results: self.placePins)
            })
        } else {
            
            let count = 16
            let count_1 = count/2
            
            yelpQuery.setResultLimit(count: count)
            yelpQuery.setCatagoryToRestaurant()
            yelpManager.query(request: yelpQuery, completion: { (results) in
                for result in results {
                    if checkPlaceExist(result) {
                        continue
                    }
                    let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
                    self.placeNames.append(latPlusLon)
                    self.placePins.append(result)
//                    self.pinPlacesOnMap(results: [result])
                }
                
                self.yelpQuery.setResultLimit(count: count_1)
                self.yelpQuery.setCatagoryToDessert()
                self.yelpManager.query(request: self.yelpQuery, completion: { (results) in
                    for result in results {
                        if checkPlaceExist(result) {
                            continue
                        }
                        let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
                        self.placeNames.append(latPlusLon)
                        self.placePins.append(result)
//                        self.pinPlacesOnMap(results: [result])
                    }
                    self.yelpQuery.setCatagoryToCafe()
                    self.yelpManager.query(request: self.yelpQuery, completion: { (results) in
                        for result in results {
                            if checkPlaceExist(result) {
                                continue
                            }
                            let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
                            self.placeNames.append(latPlusLon)
                            self.placePins.append(result)
//                            self.pinPlacesOnMap(results: [result])
                        }
                        self.yelpQuery.setCatagoryToCinema()
                        self.yelpManager.query(request: self.yelpQuery, completion: { (results) in
                            for result in results {
                                if checkPlaceExist(result) {
                                    continue
                                }
                                let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
                                self.placeNames.append(latPlusLon)
                                self.placePins.append(result)
//                                self.pinPlacesOnMap(results: [result])
                            }
                            self.yelpQuery.setCatagoryToSport()
                            self.yelpManager.query(request: self.yelpQuery, completion: { (results) in
                                for result in results {
                                    if checkPlaceExist(result) {
                                        continue
                                    }
                                    let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
                                    self.placeNames.append(latPlusLon)
                                    self.placePins.append(result)
//                                    self.pinPlacesOnMap(results: [result])
                                }
                                self.yelpQuery.setCatagoryToBeauty()
                                self.yelpManager.query(request: self.yelpQuery, completion: { (results) in
                                    for result in results {
                                        if checkPlaceExist(result) {
                                            continue
                                        }
                                        let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
                                        self.placeNames.append(latPlusLon)
                                        self.placePins.append(result)
//                                        self.pinPlacesOnMap(results: [result])
                                    }
                                    self.yelpQuery.setCatagoryToArt()
                                    self.yelpManager.query(request: self.yelpQuery, completion: { (results) in
                                        for result in results {
                                            if checkPlaceExist(result) {
                                                continue
                                            }
                                            let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
                                            self.placeNames.append(latPlusLon)
                                            self.placePins.append(result)
//                                            self.pinPlacesOnMap(results: [result])
                                        }
                                        self.yelpQuery.setCatagoryToJuice()
                                        self.yelpManager.query(request: self.yelpQuery, completion: { (results) in
                                            for result in results {
                                                if checkPlaceExist(result) {
                                                    continue
                                                }
                                                let latPlusLon = Double(result.position.latitude) + Double(result.position.longitude)
                                                self.placeNames.append(latPlusLon)
                                                self.placePins.append(result)
                                                self.pinPlacesOnMap(results: [result])
                                            }
                                            self.pinPlacesOnMap(results: self.placePins)
                                        })
                                    })
                                })
                            })
                        })
                    })
                })
            })
        }
    }
    
    fileprivate func calculateZoomLevel(results: [PlacePin]) {
        var latArr = [Double]()
        var lonArr = [Double]()
        for result in results {
            latArr.append(result.position.latitude)
            lonArr.append(result.position.longitude)
        }
        
        let minLat = latArr.min()!
        let maxLat = latArr.max()!
        let minLon = lonArr.min()!
        let maxLon = lonArr.max()!
        let northWestCor = CLLocationCoordinate2DMake(maxLat, minLon)
        let southEastCor = CLLocationCoordinate2DMake(minLat, maxLon)
        let geoBounds = GMSCoordinateBounds(coordinate: northWestCor, coordinate: southEastCor)
        let cameraUpdate = GMSCameraUpdate.fit(geoBounds, withPadding: 25.0)
//        faeMapView.animate(with: cameraUpdate)
    }
    
    fileprivate func allTypePlacesPin() -> Bool {
        if btnMFilterPlacesAll.tag == 1 || btnMFilterShowAll.tag == 1 {
            return true
        } else {
            return false
        }
    }
    
    func placesPinIconImage(categoryList: [String]) -> UIImage {
        var iconImage = UIImage()
        if categoryList.contains("burgers") {
            iconImage = placeBurger
        }
        else if categoryList.contains("pizza") {
            iconImage = placePizza
        }
        else if categoryList.contains("coffee") {
            iconImage = placeCoffee
        }
        else if categoryList.contains("desserts") {
            iconImage = placeDessert
        }
        else if categoryList.contains("icecream") {
            iconImage = placeDessert
        }
        else if categoryList.contains("movietheaters") {
            iconImage = placeCinema
        }
        else if categoryList.contains("museums") {
            iconImage = placeArt
        }
        else if categoryList.contains("galleries") {
            iconImage = placeArt
        }
        else if categoryList.contains("spas") {
            iconImage = placeBeauty
        }
        else if categoryList.contains("barbers") {
            iconImage = placeBeauty
        }
        else if categoryList.contains("skincare") {
            iconImage = placeBeauty
        }
        else if categoryList.contains("massage") {
            iconImage = placeBeauty
        }
        else if categoryList.contains("playgrounds") {
            iconImage = placeSport
        }
        else if categoryList.contains("countryclubs") {
            iconImage = placeSport
        }
        else if categoryList.contains("sports_clubs") {
            iconImage = placeSport
        }
        else if categoryList.contains("bubbletea") {
            iconImage = placeBoba
        }
        else if categoryList.contains("juicebars") {
            iconImage = placeBoba
        }
        return iconImage
    }
}
