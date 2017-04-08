//
//  ChatSendLocation.swift
//  faeBeta
//
//  Created by Yue on 7/25/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation

protocol LocationSendDelegate: class {
    func sendPickedLocation(_ lat : CLLocationDegrees, lon : CLLocationDegrees, screenShot : UIImage)
}

class ChatSendLocationController: UIViewController, GMSMapViewDelegate, FaeSearchControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    var widthFactor : CGFloat = 375 / 414
    var heightFactor : CGFloat = 667 / 736
    
    weak var locationDelegate : LocationSendDelegate!
    
    // MARK: -- Location
    var currentLatitude: CLLocationDegrees = 34.0205378
    var currentLongitude: CLLocationDegrees = -118.2854081
    var currentLocation: CLLocation!
    let locManager = CLLocationManager()
    var willAppearFirstLoad = false
    
    // MARK: -- Map main screen Objects
    var faeMapView: GMSMapView!
    var buttonSelfPosition: UIButton!
    var buttonCancelSelectLocation: UIButton!
    var buttonSetLocationOnMap: UIButton!
    
    // MARK: -- Search Bar
    var uiviewTableSubview: UIView!
    var tblSearchResults: UITableView!
    var dataArray = [String]()
    var filteredArray = [String]()
    var shouldShowSearchResults = false
    var searchController: UISearchController!
    var faeSearchController: FaeSearchController!
    var searchBarSubview: UIView!
    var placeholder = [GMSAutocompletePrediction]()
    var searchBarSubviewButton: UIButton!
    
    //MARK: -- Coordinates to send
    var latitudeForPin: CLLocationDegrees = 0.0
    var longitudeForPin: CLLocationDegrees = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        widthFactor = screenWidth / 414
        heightFactor = screenHeight / 736
        loadMapView()
        loadTableView()
        configureFaeSearchController()
        loadButton()
        loadPin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        locManager.requestAlwaysAuthorization()
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined){
            print("Not Authorised")
            self.locManager.requestAlwaysAuthorization()
        }
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied){
            jumpToLocationEnable()
        }
        willAppearFirstLoad = true
        self.actionSelfPosition(self.buttonSelfPosition)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func jumpToLocationEnable(){
//        let vc:UIViewController = UIStoryboard(name: "Main", bundle: nil) .instantiateViewControllerWithIdentifier("LocationEnableViewController")as! LocationEnableViewController
//        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func loadMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: currentLatitude, longitude: currentLongitude, zoom: 17)
        faeMapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        faeMapView.isMyLocationEnabled = true
        faeMapView.delegate = self
        self.view = faeMapView
    }
    
    func loadPin() {
        let pinImage = UIImageView(frame: CGRect(x: 186 * widthFactor, y: 326 * heightFactor, width: 45 * widthFactor, height: 47 * heightFactor))
        pinImage.image = UIImage(named: "chat_map_currentLoc")
        self.view.addSubview(pinImage)
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        faeSearchController.faeSearchBar.endEditing(true)
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        
        let mapCenter = CGPoint(x: screenWidth/2, y: screenHeight/2)
        let mapCenterCoordinate = mapView.projection.coordinate(for: mapCenter)
        GMSGeocoder().reverseGeocodeCoordinate(mapCenterCoordinate, completionHandler: {
            (response, error) -> Void in
            if let fullAddress = response?.firstResult()?.lines {
                var addressToSearchBar = ""
                for line in fullAddress {
                    if fullAddress.index(of: line) == fullAddress.count-1 {
                        addressToSearchBar += line + ""
                    }
                    else {
                        addressToSearchBar += line + ", "
                    }
                }
                self.faeSearchController.faeSearchBar.text = addressToSearchBar
            }
            self.latitudeForPin = mapCenterCoordinate.latitude
            self.longitudeForPin = mapCenterCoordinate.longitude
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if willAppearFirstLoad {
            currentLocation = locManager.location
            currentLatitude = currentLocation.coordinate.latitude
            currentLongitude = currentLocation.coordinate.longitude
            let camera = GMSCameraPosition.camera(withLatitude: currentLatitude, longitude: currentLongitude, zoom: 17)
            faeMapView.camera = camera
            willAppearFirstLoad = false
        }
    }
    
    func configureFaeSearchController() {
        searchBarSubview = UIView(frame: CGRect(x: 8 * widthFactor, y: 23 * heightFactor, width: (screenWidth - 8 * 2 * widthFactor), height: 48 * heightFactor))
        
        faeSearchController = FaeSearchController(searchResultsController: self, searchBarFrame: CGRect(x: 0, y: 5 * heightFactor, width: 398 * widthFactor, height: 38.0 * heightFactor), searchBarFont: UIFont(name: "AvenirNext-Medium", size: 18.0)!, searchBarTextColor: UIColor.faeAppRedColor(), searchBarTintColor: UIColor.white)
        // quick fix for unwant shadow in search bar
        
        if(UIScreen.main.bounds.height == 736) {
            faeSearchController = FaeSearchController(searchResultsController: self, searchBarFrame: CGRect(x: 0, y: 5 * heightFactor, width: 398 * widthFactor, height: 38.0 * heightFactor), searchBarFont: UIFont(name: "AvenirNext-Medium", size: 18.0)!, searchBarTextColor: UIColor.faeAppRedColor(), searchBarTintColor: UIColor.white)
        } else {
            faeSearchController = FaeSearchController(searchResultsController: self, searchBarFrame: CGRect(x: 0, y: 4.5, width: 360 * 1, height: 34), searchBarFont: UIFont(name: "AvenirNext-Medium", size: 18.0)!, searchBarTextColor: UIColor.faeAppRedColor(), searchBarTintColor: UIColor.white)
        }

        faeSearchController.faeSearchBar.placeholder = "Search Address or Place                                  "
        faeSearchController.faeDelegate = self
        faeSearchController.faeSearchBar.layer.borderWidth = 2.0
        faeSearchController.faeSearchBar.layer.borderColor = UIColor.white.cgColor
        
        searchBarSubview.addSubview(faeSearchController.faeSearchBar)
        searchBarSubview.backgroundColor = UIColor.white
        self.view.addSubview(searchBarSubview)
        
        searchBarSubview.layer.borderColor = UIColor.white.cgColor
        searchBarSubview.layer.borderWidth = 1.0
        searchBarSubview.layer.cornerRadius = 2.0
        searchBarSubview.layer.shadowOpacity = 0.5
        searchBarSubview.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        searchBarSubview.layer.shadowRadius = 5.0
        searchBarSubview.layer.shadowColor = UIColor.black.cgColor
        
        searchBarSubviewButton = UIButton(frame: CGRect(x: 8 * widthFactor, y: 23 * heightFactor, width: 398 * widthFactor, height: 48 * heightFactor))
        searchBarSubview.addSubview(searchBarSubviewButton)
        searchBarSubviewButton.addTarget(self, action: #selector(ChatSendLocationController.actionActiveSearchBar(_:)), for: UIControlEvents.touchUpInside)
        
    }
    
    func loadButton() {
        buttonSelfPosition = UIButton(frame: CGRect(x: screenWidth - (16+59) *  widthFactor, y: screenHeight - 59 * widthFactor - 75 * heightFactor, width: 59 * widthFactor, height: 59 * widthFactor))
        buttonSelfPosition.setImage(UIImage(named: "mainScreenSelfPosition"), for: UIControlState())
        self.view.addSubview(buttonSelfPosition)
        buttonSelfPosition.addTarget(self, action: #selector(ChatSendLocationController.actionSelfPosition(_:)), for: UIControlEvents.touchUpInside)
        
        buttonCancelSelectLocation = UIButton(frame: CGRect(x: 16 * widthFactor, y: screenHeight - 59 * widthFactor - 75 * heightFactor, width: 59 * widthFactor, height: 59 * widthFactor))
        buttonCancelSelectLocation.setImage(UIImage(named: "cancelSelectLocation"), for: UIControlState())
        self.view.addSubview(buttonCancelSelectLocation)
        buttonCancelSelectLocation.addTarget(self, action: #selector(ChatSendLocationController.actionCancelSelectLocation(_:)), for: UIControlEvents.touchUpInside)
        
        buttonSetLocationOnMap = UIButton(frame: CGRect(x: 0, y: screenHeight - 65 * heightFactor, width: screenWidth, height: 65 * heightFactor))
        buttonSetLocationOnMap.setTitle("Send Location", for: UIControlState())
        buttonSetLocationOnMap.setTitle("Send Location", for: .highlighted)
        buttonSetLocationOnMap.setTitleColor(UIColor.faeAppRedColor(), for: UIControlState())
        buttonSetLocationOnMap.setTitleColor(UIColor.lightGray, for: .highlighted)
        buttonSetLocationOnMap.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 22)
        buttonSetLocationOnMap.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.9)
        self.view.addSubview(buttonSetLocationOnMap)
        buttonSetLocationOnMap.addTarget(self, action: #selector(ChatSendLocationController.actionSetLocationForComment(_:)), for: UIControlEvents.touchUpInside)
    }
    
    func actionSelfPosition(_ sender: UIButton!) {
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            currentLocation = locManager.location
        }
        if currentLocation != nil {
            currentLatitude = currentLocation.coordinate.latitude
            currentLongitude = currentLocation.coordinate.longitude
            let camera = GMSCameraPosition.camera(withLatitude: currentLatitude, longitude: currentLongitude, zoom: 17)
            faeMapView.animate(to: camera)
        }
    }
    
    func actionCancelSelectLocation(_ sender: UIButton!) {
        _ = self.navigationController?.popViewController(animated: true)
//        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func actionSetLocationForComment(_ sender: UIButton!) {
        UIGraphicsBeginImageContext(self.faeMapView.frame.size)
        self.faeMapView.layer.render(in: UIGraphicsGetCurrentContext()!)
        if let screenShotImage = UIGraphicsGetImageFromCurrentImageContext(){
            _ = self.navigationController?.popViewController(animated: true)
            locationDelegate.sendPickedLocation(self.latitudeForPin, lon: self.longitudeForPin, screenShot: screenShotImage)
        }
    }
    
    func actionActiveSearchBar(_ sender: UIButton!) {
        self.faeSearchController.faeSearchBar.becomeFirstResponder()
    }
    
    func loadTableView() {
        uiviewTableSubview = UIView(frame: CGRect(x: 0, y: 0, width: 398 * widthFactor, height: 0))
        tblSearchResults = UITableView(frame: self.uiviewTableSubview.bounds)
        tblSearchResults.delegate = self
        tblSearchResults.dataSource = self
        tblSearchResults.register(FaeCellForAddressSearch.self, forCellReuseIdentifier: "faeCellForAddressSearch")
        tblSearchResults.isScrollEnabled = false
        tblSearchResults.layer.masksToBounds = true
        tblSearchResults.separatorInset = UIEdgeInsets.zero
        tblSearchResults.layoutMargins = UIEdgeInsets.zero
        uiviewTableSubview.layer.borderColor = UIColor.white.cgColor
        uiviewTableSubview.layer.borderWidth = 1.0
        uiviewTableSubview.layer.cornerRadius = 2.0
        uiviewTableSubview.layer.shadowOpacity = 0.5
        uiviewTableSubview.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        uiviewTableSubview.layer.shadowRadius = 5.0
        uiviewTableSubview.layer.shadowColor = UIColor.black.cgColor
        uiviewTableSubview.addSubview(tblSearchResults)
        self.view.addSubview(uiviewTableSubview)
    }
    
    // MARK: UITableView Delegate and Datasource functions
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return placeholder.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "faeCellForAddressSearch", for: indexPath) as! FaeCellForMainScreenSearch
        cell.labelTitle.text = placeholder[indexPath.row].attributedPrimaryText.string
        if let secondaryText = placeholder[indexPath.row].attributedSecondaryText {
            cell.labelSubTitle.text = secondaryText.string
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let placesClient = GMSPlacesClient()
        placesClient.lookUpPlaceID(placeholder[indexPath.row].placeID!, callback: {
            (place, error) -> Void in
            // Get place.coordinate
            GMSGeocoder().reverseGeocodeCoordinate(place!.coordinate, completionHandler: {
                (response, error) -> Void in
                if let selectedAddress = place?.coordinate {
                    let camera = GMSCameraPosition.camera(withTarget: selectedAddress, zoom: self.faeMapView.camera.zoom)
                    self.faeMapView.animate(to: camera)
                }
            })
        })
        self.faeSearchController.faeSearchBar.text = self.placeholder[indexPath.row].attributedFullText.string
        self.faeSearchController.faeSearchBar.resignFirstResponder()
        self.searchBarTableHideAnimation()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 61 * screenWidthFactor
    }
    
    func searchBarTableHideAnimation() {
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.transitionFlipFromBottom, animations: ({
            self.tblSearchResults.frame = CGRect(x: 0, y: 0, width: 398 * self.widthFactor, height: 0)
            self.uiviewTableSubview.frame = CGRect(x: 8 * self.widthFactor, y: (23+53) * self.heightFactor, width: 398 * self.widthFactor, height: 0)
        }), completion: nil)
    }
    
    func searchBarTableShowAnimation() {
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions.transitionFlipFromBottom, animations: ({
            self.tblSearchResults.frame = CGRect(x: 0, y: 0, width: 398 * self.widthFactor, height: 240 * self.heightFactor)
            self.uiviewTableSubview.frame = CGRect(x: 8 * self.widthFactor, y: (23+53) * self.heightFactor, width: 398 * self.widthFactor, height: 240 * self.heightFactor)
        }), completion: nil)
    }
    
    // MARK: UISearchResultsUpdating delegate function
    func updateSearchResultsForSearchController(_ searchController: UISearchController) {
        tblSearchResults.reloadData()
    }
    
    // MARK: FaeSearchControllerDelegate functions
    func didStartSearching() {
        shouldShowSearchResults = true
        tblSearchResults.reloadData()
        faeSearchController.faeSearchBar.becomeFirstResponder()
    }
    
    func didTapOnSearchButton() {
        if !shouldShowSearchResults {
            shouldShowSearchResults = true
            tblSearchResults.reloadData()
        }
        
        if placeholder.count > 0 {
            let placesClient = GMSPlacesClient()
            placesClient.lookUpPlaceID(placeholder[0].placeID!, callback: {
                (place, error) -> Void in
                GMSGeocoder().reverseGeocodeCoordinate(place!.coordinate, completionHandler: {
                    (response, error) -> Void in
                    if let selectedAddress = place?.coordinate {
                        let camera = GMSCameraPosition.camera(withTarget: selectedAddress, zoom: self.faeMapView.camera.zoom)
                        self.faeMapView.animate(to: camera)
                    }
                })
            })
            self.faeSearchController.faeSearchBar.text = self.placeholder[0].attributedFullText.string
            self.faeSearchController.faeSearchBar.resignFirstResponder()
            self.searchBarTableHideAnimation()
        }
        
    }
    
    func didTapOnCancelButton() {
        shouldShowSearchResults = false
        tblSearchResults.reloadData()
    }
    
    func didChangeSearchText(_ searchText: String) {
        if(searchText != "") {
            let placeClient = GMSPlacesClient()
            placeClient.autocompleteQuery(searchText, bounds: nil, filter: nil) {
                (results, error : Error?) -> Void in
                if let error = error {
                    print(error)
                }
                self.placeholder.removeAll()
                if results == nil {
                    return
                } else {
                    for result in results! {
                        self.placeholder.append(result)
                    }
                    self.tblSearchResults.reloadData()
                }
            }
            if placeholder.count > 0 {
                searchBarTableShowAnimation()
            }
        }
        else {
            self.placeholder.removeAll()
            searchBarTableHideAnimation()
            self.tblSearchResults.reloadData()
        }
    }
}
