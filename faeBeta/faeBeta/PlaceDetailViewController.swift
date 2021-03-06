//
//  PlaceDetailViewController.swift
//  faeBeta
//
//  Created by Faevorite 2 on 2017-08-14.
//  Copyright © 2017 fae. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

enum EnterPlaceLocDetailMode {
    case collection
    case boards
    case map
}

class PlaceDetailViewController: UIViewController, SeeAllPlacesDelegate, AddPinToCollectionDelegate, AfterAddedToListDelegate, SKPhotoBrowserDelegate {
    
    public var place: PlacePin!
    private var uiviewHeader: UIView!
    private var uiview_bottomLine: UIView!
    private var uiviewSubHeader: FixedHeader!
    private var uiviewFixedHeader: FixedHeader!
    
    private var uiviewPlaceImages: PlacePinImagesView!
    
    private var uiviewFooter: UIView!
    private var btnBack: UIButton!
    private var btnSave: UIButton!
    private var imgSaved: UIImageView!
    private var btnRoute: UIButton!
    private var btnShare: UIButton!
    private var tblPlaceDetail: UITableView!
    private let arrTitle = ["Similar Places", "Near this Place"]
    private var arrSimilarPlaces = [PlacePin]()
    private var placeIdSet = Set<Int>()
    private var arrNearbyPlaces = [PlacePin]()
    private let faePinAction = FaePinAction()
    private var boolSaved: Bool = false
    private var uiviewSavedList: AddPinToCollectionView!
    private var uiviewAfterAdded: AfterAddedToListView!
    private var arrListSavedThisPin = [Int]()
    private var boolSavedListLoaded = false
    private var uiviewWhite: UIView!
    private var intHaveHour = 0
    private var intHaveWebPhone = 0
    private var boolHaveWeb = false
    private var intCellCount = 0
    private var intSimilar = 0
    private var intNearby = 0
    private var intSimilarNearbySection = 0
    private var isScrollViewDidScrollEnabled: Bool = true
    private var arrDay_LG = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    private var arrDay = ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"]
    private var dayIdx = 0
    private var boolMapFold: Bool = true
    private var boolHourFold: Bool = true
    private var mapIndexPath = [IndexPath]()
    private var hourIndexPath = [IndexPath]()
    
    private var viewModelSimilar: BoardPlaceCategoryViewModel?
    private var viewModelNearby: BoardPlaceCategoryViewModel?
    
    var boolShared: Bool = false
    public var enterMode: EnterPlaceLocDetailMode!
    var search_request: DataRequest?
    var nearby_request: DataRequest?
    var fetchCount: Int = 0 {
        didSet {
            guard fetchCount == 2 else { return }
            doneFetchPlaces()
        }
    }
    var dataDict = [String: [PlacePin]]()
    
    // Guest Mode
    private var uiviewGuestMode: GuestModeView!
    
    // MARK: - Life Cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        loadFooter()
        loadHeader()
        loadMidTable()
        loadFixedHeader()
        view.bringSubview(toFront: uiviewSavedList)
        view.bringSubview(toFront: uiviewAfterAdded)
        checkSavedStatus() {}
        setCellCount()
        calculateTodayDate()
        NotificationCenter.default.addObserver(self, selector: #selector(showSavedNoti), name: NSNotification.Name(rawValue: "showSavedNoti_placeDetail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideSavedNoti), name: NSNotification.Name(rawValue: "hideSavedNoti_placeDetail"), object: nil)
        
        // Joshua: Add this two lines to enable the edge-gesture on the left side of screen
        //         whole table view and cell will automatically disable this
        let uiviewLeftMargin = LeftMarginToEnableNavGestureView()
        view.addSubview(uiviewLeftMargin)
        
        initPlaceRelatedData()
        
        print("placeId \(place.id), categoryID \(place.category_icon_id)")
        
        updateCategoryDictionary()
    }
    
    private func updateCategoryDictionary() {
        guard !Key.shared.is_guest else {
            return
        }
        Category.shared.updateCategoryDictionary(place: place)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "showSavedNoti_placeDetail"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "hideSavedNoti_placeDetail"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if boolShared {
            //uiviewAfterAdded.lblSaved.text = "You shared a Place."
            uiviewAfterAdded.lblSaved.frame = CGRect(x: 20, y: 19, width: 200, height: 25)
            uiviewAfterAdded.btnUndo.isHidden = true
            uiviewAfterAdded.btnSeeList.isHidden = true
            uiviewAfterAdded.show("You shared a Place.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.uiviewAfterAdded.hide()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                self.uiviewAfterAdded.lblSaved.text = "Collocted to List!"
                self.uiviewAfterAdded.lblSaved.frame = CGRect(x: 20, y: 19, width: 150, height: 25)
                self.uiviewAfterAdded.btnUndo.isHidden = false
                self.uiviewAfterAdded.btnSeeList.isHidden = false
            }
            boolShared = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
        if tblPlaceDetail.contentOffset.y >= topImagesHeight * screenHeightFactor {
            UIApplication.shared.statusBarStyle = .default
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.statusBarStyle = .default
    }
    
    // MARK: -
    
    private func initPlaceRelatedData() {
        uiviewSubHeader.setValue(place: place)
        uiviewFixedHeader.setValue(place: place)
        tblPlaceDetail.reloadData()
        let lat = String(place.coordinate.latitude)
        let long = String(place.coordinate.longitude)
        
        // TODO Vicky - 在similar places加载出来前点击展开cell偶尔会崩溃 => 似乎解决了？
        getRelatedPlaces(lat, long, isSimilar: true) {
            vickyprint("Exist duplicate place: \(self.testDuplicates())")
        }
        getRelatedPlaces(lat, long, isSimilar: false, {
            
        })
    }
    
    private func doneFetchPlaces() {
        var arrSimilar = [PlacePin]()
        var arrNearby = [PlacePin]()
        if let similars = dataDict["similar"] {
            arrSimilar = similars
        }
        if let nearbys = dataDict["nearby"] {
            arrNearby = nearbys
        }
        viewModelSimilar = BoardPlaceCategoryViewModel(title: arrTitle[0], places: arrSimilar)
        viewModelNearby = BoardPlaceCategoryViewModel(title: arrTitle[1], places: arrNearby)
        //                self.tblPlaceDetail.reloadData()
        //                self.tblPlaceDetail.reloadSections(IndexSet(integer: self.intCellCount - 1), with: .none)
        intSimilarNearbySection = (intSimilar == 0 && intNearby == 0 ? 0 : 1)
        tblPlaceDetail.beginUpdates()
        tblPlaceDetail.insertSections(IndexSet(integer: intCellCount), with: .none)
        tblPlaceDetail.endUpdates()
        uiviewPlaceImages.removeFromSuperview()
        uiviewHeader.addSubview(uiviewPlaceImages)
        uiviewPlaceImages.loadPageCtrl()
    }
    
    private func testDuplicates() -> Bool {
        // for duplicates test
        var testset = Set<PlacePin>()
        for similar in self.arrSimilarPlaces {
            if (testset.contains(similar)) {
//                vickyprint(similar.id)
//                vickyprint(arrSimilarPlaces)
                return true
            }
            testset.insert(similar)
        }
        return false
    }
    
    private func setCellCount() {
        guard place != nil else { return }
        intHaveHour = place.hours.count > 0 ? 1 : 0
        intHaveWebPhone = place.url != "" || place.phone != "" ? 1 : 0
        boolHaveWeb = place.url != ""
        intCellCount = intHaveHour + intHaveWebPhone + 1
        
        mapIndexPath.append(IndexPath(row: 1, section: 0))
        if intHaveHour != 0 {
            for idx in 1...8 {
                hourIndexPath.append(IndexPath(row: idx, section: 1))
            }
        }
    }
    
    private func checkSavedStatus(_ completion: @escaping () -> ()) {
        FaeMap.shared.getPin(type: "place", pinId: String(place.id)) { [weak self] (status, message) in
            guard status / 100 == 2 else { return }
            guard message != nil else { return }
            let resultJson = JSON(message!)
            guard let is_saved = resultJson["user_pin_operations"]["is_saved"].string else {
                completion()
                return
            }
            guard is_saved != "false" else {
                completion()
                return
            }
            var ids = [Int]()
            for colIdRaw in is_saved.split(separator: ",") {
                let strColId = String(colIdRaw)
                guard let colId = Int(strColId) else { continue }
                ids.append(colId)
            }
            guard let `self` = self else { return }
            self.arrListSavedThisPin = ids
            self.uiviewSavedList.arrListSavedThisPin = ids
            self.boolSavedListLoaded = true
            if ids.count != 0 {
                self.showSavedNoti()
            }
            completion()
        }
    }
    
    private func getRelatedPlaces(_ lat: String, _ long: String, isSimilar: Bool, _ completion: @escaping () -> Void) {
        if isSimilar {
            arrSimilarPlaces.removeAll()
            placeIdSet.removeAll()
            let searchAgent = FaeSearch()
            searchAgent.whereKey("source", value: "categories")
            searchAgent.whereKey("type", value: "place")
            searchAgent.whereKey("size", value: "20")
            searchAgent.whereKey("radius", value: "20000")
            searchAgent.whereKey("offset", value: "0")
            searchAgent.whereKey("sort", value: [["_score": "desc"], ["geo_location": "asc"]])
            searchAgent.whereKey("location", value: ["latitude": lat,
                                                          "longitude": long])
            if place.class_5 != "" {
                searchAgent.whereKey("content", value: place.class_5)
                searchAgent.searchContent.append(searchAgent.keyValue)
            }
            if place.class_4 != "" {
                searchAgent.whereKey("content", value: place.class_4)
                searchAgent.searchContent.append(searchAgent.keyValue)
            }
            if place.class_3 != "" {
                searchAgent.whereKey("content", value: place.class_3)
                searchAgent.searchContent.append(searchAgent.keyValue)
            }
            if place.class_2 != "" {
                searchAgent.whereKey("content", value: place.class_2)
                searchAgent.searchContent.append(searchAgent.keyValue)
            }
            if place.class_1 != "" {
                searchAgent.whereKey("content", value: place.class_1)
                searchAgent.searchContent.append(searchAgent.keyValue)
            }
            if place.master_class != "" {
                searchAgent.whereKey("content", value: place.master_class)
                searchAgent.whereKey("source", value: "master_class")
                searchAgent.searchContent.append(searchAgent.keyValue)
            }
            
            print(searchAgent.searchContent)
            
            if searchAgent.searchContent.isEmpty {
                self.intSimilar = 0
                completion()
                return
            }
            search_request?.cancel()
            search_request = searchAgent.searchBulk { [weak self] (status, message) in
                guard let `self` = self else { return }
                guard status / 100 == 2 && message != nil else {
                    print("Get Related Places Fail \(status) \(message!)")
                    self.intSimilar = self.arrSimilarPlaces.count > 0 ? 1 : 0
                    self.fetchCount += 1
                    completion()
                    return
                }
                let json = JSON(message!)
                guard let placesJson = json.array else {
                    self.fetchCount += 1
                    completion()
                    return
                }
                for similarPlaces in placesJson {
                    guard let similarJson = similarPlaces.array else {
                        continue
                    }
                    let places = similarJson.map( { PlacePin(json: $0) } )
                    for place in places {
                        if place.id != self.place.id && !self.placeIdSet.contains(place.id) {
                            self.arrSimilarPlaces.append(place)
                            self.placeIdSet.insert(place.id)
                        }
                    }
                }
                self.arrSimilarPlaces = Array(self.arrSimilarPlaces.prefix(20))
                self.dataDict["similar"] = self.arrSimilarPlaces
                self.intSimilar = self.arrSimilarPlaces.count > 0 ? 1 : 0
                self.fetchCount += 1
                completion()
            }
        } else { // Near this Location
            arrNearbyPlaces.removeAll()
            let fetchAgent = FaeMap()
            fetchAgent.whereKey("geo_latitude", value: lat)
            fetchAgent.whereKey("geo_longitude", value: long)
            fetchAgent.whereKey("radius", value: "5000")
            fetchAgent.whereKey("type", value: "place")
            fetchAgent.whereKey("max_count", value: "20")
            nearby_request?.cancel()
            nearby_request = fetchAgent.getMapPins { [weak self] (status: Int, message: Any?) in
                guard let `self` = self else { return }
                guard status / 100 == 2 && message != nil else {
                    //print("Get Related Places Fail \(status) \(message!)")
                    self.intNearby = self.arrNearbyPlaces.count > 0 ? 1 : 0
                    self.fetchCount += 1
                    completion()
                    return
                }
                let json = JSON(message!)
                guard let placeJson = json.array else {
                    self.fetchCount += 1
                    completion()
                    return
                }
                self.arrNearbyPlaces = placeJson.map({ PlacePin(json: $0) })
                self.arrNearbyPlaces = self.arrNearbyPlaces.filter({ $0.id != self.place.id })
                self.dataDict["nearby"] = self.arrNearbyPlaces
                self.intNearby = self.arrNearbyPlaces.count > 0 ? 1 : 0
                self.fetchCount += 1
                completion()
            }
        }
    }
    
    // MARK: - UI Setups
    
    let topImagesHeight: CGFloat = 308
    
    private func loadHeader() {
        let txtHeight = heightForView(text: place.name, font: UIFont(name: "AvenirNext-Medium", size: 20)!, width: screenWidth - 40)
        uiviewHeader = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: (topImagesHeight + 101 - 27 + txtHeight) * screenHeightFactor + device_offset_top))
        uiviewSubHeader = FixedHeader(frame: CGRect(x: 0, y: topImagesHeight * screenHeightFactor + device_offset_top, width: screenWidth, height: (101 - 27 + txtHeight) * screenHeightFactor))
        uiviewSubHeader.lblName.frame.size.height = txtHeight
        let origin_y = uiviewSubHeader.lblCategory.frame.origin.y - 27 + txtHeight
        uiviewSubHeader.lblCategory.frame.origin.y = origin_y
        uiviewHeader.addSubview(uiviewSubHeader)
        uiviewSubHeader.setValue(place: place)
    }
    
    private func loadFixedHeader() {
        let txtHeight = heightForView(text: place.name, font: UIFont(name: "AvenirNext-Medium", size: 20)!, width: screenWidth - 40)
        uiviewFixedHeader = FixedHeader(frame: CGRect(x: 0, y: 22 * screenHeightFactor, width: screenWidth, height: (101-27+txtHeight) * screenHeightFactor))
        if screenHeight == 812 { uiviewFixedHeader.frame.origin.y = 30 }
        uiviewFixedHeader.lblName.frame.size.height = txtHeight
        let origin_y = uiviewFixedHeader.lblCategory.frame.origin.y - 27 + txtHeight
        uiviewFixedHeader.lblCategory.frame.origin.y = origin_y
        view.addSubview(uiviewFixedHeader)
        uiviewFixedHeader.setValue(place: place)
        uiviewFixedHeader.isHidden = true
        uiviewWhite = UIView(frame: CGRect(x: 0, y: 0, w: 414, h: 22))
        if screenHeight == 812 { uiviewWhite.frame.size.height = 30 }
        uiviewWhite.backgroundColor = .white
        view.addSubview(uiviewWhite)
        uiviewWhite.alpha = 0
    }
    
    private func loadMidTable() {
        tblPlaceDetail = UITableView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight - 49 - device_offset_bot), style: .plain)
        view.addSubview(tblPlaceDetail)
        tblPlaceDetail.tableHeaderView = uiviewHeader
        
        tblPlaceDetail.delegate = self
        tblPlaceDetail.dataSource = self
        tblPlaceDetail.register(PlaceDetailCell.self, forCellReuseIdentifier: "map")
        tblPlaceDetail.register(PlaceDetailCell.self, forCellReuseIdentifier: "hour")
        tblPlaceDetail.register(PlaceDetailCell.self, forCellReuseIdentifier: "web")
        tblPlaceDetail.register(PlaceDetailCell.self, forCellReuseIdentifier: "phone")
        tblPlaceDetail.register(BoardPlacesCell.self, forCellReuseIdentifier: "BoardPlacesCell")
        tblPlaceDetail.register(PlaceDetailMapCell.self, forCellReuseIdentifier: "PlaceDetailMapCell")
        tblPlaceDetail.register(PlaceOpeningHourCell.self, forCellReuseIdentifier: "PlaceOpeningHourCell")
        tblPlaceDetail.register(PlaceHoursHintCell.self, forCellReuseIdentifier: "PlaceHoursHintCell")
        tblPlaceDetail.separatorStyle = .none
        tblPlaceDetail.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            tblPlaceDetail.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideAddCollectionView))
        tblPlaceDetail.addGestureRecognizer(tapGesture)
        tapGesture.cancelsTouchesInView = false
        
        uiviewPlaceImages = PlacePinImagesView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: topImagesHeight * screenHeightFactor + device_offset_top))
        tblPlaceDetail.addSubview(uiviewPlaceImages)
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(actionTapImages))
        uiviewPlaceImages.addGestureRecognizer(tapGes)
        tapGes.cancelsTouchesInView = true

        uiviewPlaceImages.arrURLs = place.imageURLs
        uiviewPlaceImages.loadContent()
        uiviewPlaceImages.setup()
        let bottomLine = UIView(frame: CGRect(x: 0, y: topImagesHeight + device_offset_top, w: 414, h: 1))
        bottomLine.backgroundColor = UIColor._241241241()
        uiviewPlaceImages.addSubview(bottomLine)
        uiviewPlaceImages.addConstraintsWithFormat("H:|-0-[v0]-0-|", options: [], views: bottomLine)
        uiviewPlaceImages.addConstraintsWithFormat("V:[v0(1)]-0-|", options: [], views: bottomLine)
    }
    
    private func loadFooter() {
        uiviewFooter = UIView(frame: CGRect(x: 0, y: screenHeight - 49 - device_offset_bot, width: screenWidth, height: 49 + device_offset_bot))
        view.addSubview(uiviewFooter)
        
        let line = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 1))
        line.backgroundColor = UIColor._200199204()
        uiviewFooter.addSubview(line)
        
        btnBack = UIButton(frame: CGRect(x: -10, y: 1, width: 60.5, height: 48))
        btnBack.setImage(#imageLiteral(resourceName: "navigationBack"), for: .normal)
        btnBack.addTarget(self, action: #selector(backToMapBoard(_:)), for: .touchUpInside)
        
        btnSave = UIButton(frame: CGRect(x: screenWidth / 2 - 105, y: 2, width: 47, height: 47))
        btnSave.setImage(#imageLiteral(resourceName: "place_save"), for: .normal)
        btnSave.tag = 0
        btnSave.addTarget(self, action: #selector(saveThisPin), for: .touchUpInside)
        
        btnRoute = UIButton(frame: CGRect(x: (screenWidth - 47) / 2, y: 2, width: 47, height: 47))
        btnRoute.setImage(#imageLiteral(resourceName: "place_route"), for: .normal)
        btnRoute.tag = 1
        btnRoute.addTarget(self, action: #selector(routeToThisPin), for: .touchUpInside)
        
        btnShare = UIButton(frame: CGRect(x: screenWidth / 2 + 58, y: 2, width: 47, height: 47))
        btnShare.setImage(#imageLiteral(resourceName: "place_share"), for: .normal)
        btnShare.tag = 2
        btnShare.addTarget(self, action: #selector(shareThisPin), for: .touchUpInside)
        
        uiviewFooter.addSubview(btnBack)
        uiviewFooter.addSubview(btnSave)
        uiviewFooter.addSubview(btnRoute)
        uiviewFooter.addSubview(btnShare)
        
        imgSaved = UIImageView(frame: CGRect(x: 38, y: 14, width: 0, height: 0))
        btnSave.addSubview(imgSaved)
        imgSaved.image = #imageLiteral(resourceName: "place_saved")
        imgSaved.alpha = 0
        
        loadAddtoCollection()
    }
    
    private func loadAddtoCollection() {
        uiviewSavedList = AddPinToCollectionView()
        uiviewSavedList.delegate = self
        uiviewSavedList.tableMode = .place
        view.addSubview(uiviewSavedList)
        
        uiviewAfterAdded = AfterAddedToListView()
        uiviewAfterAdded.delegate = self
        view.addSubview(uiviewAfterAdded)
        
        uiviewSavedList.uiviewAfterAdded = uiviewAfterAdded
    }
    
    @objc private func showSavedNoti() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.imgSaved.frame = CGRect(x: 29, y: 5, width: 18, height: 18)
            self.imgSaved.alpha = 1
        }, completion: nil)
    }
    
    @objc private func hideSavedNoti() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.imgSaved.frame = CGRect(x: 38, y: 14, width: 0, height: 0)
            self.imgSaved.alpha = 0
        }, completion: nil)
    }

    // MARK: - UIScrollViewDelegate
    
    private var boolAnimateTo_1 = true

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == tblPlaceDetail else { return }
        if uiviewPlaceImages != nil {
            var frame = uiviewPlaceImages.frame
            if tblPlaceDetail.contentOffset.y < 0 {
                frame.origin.y = tblPlaceDetail.contentOffset.y
                uiviewPlaceImages.frame = frame
                let height = topImagesHeight * screenHeightFactor + device_offset_top - tblPlaceDetail.contentOffset.y
                uiviewPlaceImages.frame.size.height = height
                uiviewPlaceImages.contentSize.height = height
                uiviewPlaceImages.viewObjects[uiviewPlaceImages.currentPage].frame.size.height = height
            } else {
                frame.origin.y = 0
                uiviewPlaceImages.frame.origin.y = 0
            }
        }
        var offset_y: CGFloat = 286 * screenHeightFactor
        if screenHeight == 812 { offset_y = 273 }
        if tblPlaceDetail.contentOffset.y >= offset_y {
            uiviewFixedHeader.isHidden = false
            UIApplication.shared.statusBarStyle = .default
            if boolAnimateTo_1 {
                boolAnimateTo_1 = false
                UIView.animate(withDuration: 0.2, animations: {
                    self.uiviewPlaceImages.alpha = 0
                    self.uiviewSubHeader.alpha = 0
                    self.uiviewWhite.alpha = 1
                })
            }
        } else {
            uiviewFixedHeader.isHidden = true
            self.uiviewWhite.alpha = 0
            self.uiviewSubHeader.alpha = 1
            UIApplication.shared.statusBarStyle = .lightContent
            if boolAnimateTo_1 == false {
                boolAnimateTo_1 = true
                UIView.animate(withDuration: 0.2, animations: {
                    self.uiviewPlaceImages.alpha = 1
                })
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        hideAddCollectionView()
    }
    
    // MARK: - Actions
    
    @objc private func backToMapBoard(_ sender: UIButton) {
        let mbIsOn = SideMenuViewController.boolMapBoardIsOn
        if mbIsOn {
            Key.shared.initialCtrler?.goToMapBoard(animated: false)
        }
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func saveThisPin() {
        guard !Key.shared.is_guest else {
            loadGuestMode()
            return
        }
        func showCollections() {
            uiviewSavedList.tableMode = .place
            //uiviewSavedList.loadCollectionData()
            uiviewSavedList.pinToSave = FaePinAnnotation(type: .place, cluster: nil, data: place)
            uiviewSavedList.show()
        }
        if boolSavedListLoaded {
            showCollections()
        } else {
            checkSavedStatus {
                showCollections()
            }
        }
    }
    
    @objc private func routeToThisPin() {
        let vc = RoutingMapController()
        vc.startPointAddr = RouteAddress(name: "Current Location", coordinate: LocManager.shared.curtLoc.coordinate)
        vc.destinationAddr = RouteAddress(name: place.name, coordinate: place.coordinate)
        vc.destPlaceInfo = self.place
        vc.mode = .place
        navigationController?.pushViewController(vc, animated: false)
    }
    
    @objc private func shareThisPin() {
        guard !Key.shared.is_guest else {
            loadGuestMode()
            return
        }
        let vcShareCollection = NewChatShareController(friendListMode: .place)
        vcShareCollection.placeDetail = place
        vcShareCollection.boolFromPlaceDetail = true
        navigationController?.pushViewController(vcShareCollection, animated: true)
    }
    
    private func showAddCollectionView() {
        uiviewSavedList.show()
    }
    
    @objc private func hideAddCollectionView() {
        uiviewSavedList.hide()
    }
    
    @objc private func actionTapImages() {
        guard uiviewPlaceImages.arrSKPhoto.count > 0 else {
            return
        }
        let browser = SKPhotoBrowser(originImage: uiviewPlaceImages.viewObjects[uiviewPlaceImages.currentPage].image ?? UIImage(), photos: uiviewPlaceImages.arrSKPhoto, animatedFromView: uiviewPlaceImages)
        browser.initializePageIndex(uiviewPlaceImages.currentPage)
        browser.delegate = self
        present(browser, animated: true, completion: nil)
    }
    
    // MARK: - SKPhotoBrowserDelegate
    func didScrollToIndex(_ browser: SKPhotoBrowser, index: Int) {
        print("didScrollToIndex")
        uiviewPlaceImages.updateContent(index)
    }
    
    func viewForPhoto(_ browser: SKPhotoBrowser, index: Int) -> UIView? {
        return uiviewPlaceImages
    }
    
    // MARK: - SeeAllPlacesDelegate
    func jumpToAllPlaces(places: BoardPlaceCategoryViewModel) {
        let vc = AllPlacesViewController()
        vc.viewModelPlaces = places
        vc.strTitle = places.title
        AllPlacesMapController.isBackToLastPlaceDetailVCEnabled = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func jumpToPlaceDetail(place: PlacePin) {
        let vcPlaceDetail = PlaceDetailViewController()
        vcPlaceDetail.place = place
        navigationController?.pushViewController(vcPlaceDetail, animated: true)
    }
    
    // MARK: - AddPintoCollectionDelegate
    func createColList() {
        let vc = CreateColListViewController()
        vc.enterMode = .place
        present(vc, animated: true)
    }
    
    // MARK: - AfterAddedToListDelegate
    func seeList() {
        // TODO VICKY
        uiviewAfterAdded.hide()
        let vcList = CollectionsListDetailViewController()
        vcList.enterMode = uiviewSavedList.tableMode
        vcList.colId = uiviewAfterAdded.selectedCollection.collection_id
//        vcList.colInfo = uiviewAfterAdded.selectedCollection
//        vcList.arrColDetails = uiviewAfterAdded.selectedCollection
        navigationController?.pushViewController(vcList, animated: true)
    }
    
    // AfterAddedToListDelegate
    func undoCollect(colId: Int, mode: UndoMode) {
        uiviewAfterAdded.hide()
        uiviewSavedList.show()
        switch mode {
        case .save:
            uiviewSavedList.arrListSavedThisPin.append(colId)
        case .unsave:
            if uiviewSavedList.arrListSavedThisPin.contains(colId) {
                let arrListIds = uiviewSavedList.arrListSavedThisPin
                uiviewSavedList.arrListSavedThisPin = arrListIds.filter { $0 != colId }
            }
        }
        if uiviewSavedList.arrListSavedThisPin.count <= 0 {
            hideSavedNoti()
        } else if uiviewSavedList.arrListSavedThisPin.count == 1 {
            showSavedNoti()
        }
    }
}

// MARK: - FixedHeader

class FixedHeader: UIView {
    
    var lblName: UILabel!
    var lblCategory: UILabel!
    var lblPrice: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupUI() {
        backgroundColor = .white
        
        lblName = UILabel(frame: CGRect(x: 20, y: 21 * screenHeightFactor, width: screenWidth - 40, height: 27))
        lblName.numberOfLines = 0
        lblName.font = UIFont(name: "AvenirNext-Medium", size: 20)
        lblName.textColor = UIColor._898989()
        addSubview(lblName)
        
        lblCategory = UILabel(frame: CGRect(x: 20, y: 53 * screenHeightFactor, width: screenWidth - 90, height: 22))
        lblCategory.font = UIFont(name: "AvenirNext-Medium", size: 16)
        lblCategory.textColor = UIColor._146146146()
        addSubview(lblCategory)
        
        lblPrice = UILabel()
        lblPrice.font = UIFont(name: "AvenirNext-Medium", size: 16)
        lblPrice.textColor = UIColor._107105105()
        lblPrice.textAlignment = .right
        addSubview(lblPrice)
        addConstraintsWithFormat("H:[v0(100)]-15-|", options: [], views: lblPrice)
        addConstraintsWithFormat("V:[v0(22)]-\(14 * screenHeightFactor)-|", options: [], views: lblPrice)
        
        let uiviewLine = UIView(frame: CGRect(x: 0, y: 96, w: 414, h: 5))
        uiviewLine.backgroundColor = UIColor._241241241()
        addSubview(uiviewLine)
        addConstraintsWithFormat("H:|-0-[v0]-0-|", options: [], views: uiviewLine)
        addConstraintsWithFormat("V:[v0(\(5 * screenHeightFactor))]-0-|", options: [], views: uiviewLine)
    }
    
    public func setValue(place: PlacePin) {
        lblName.text = place.name
        lblCategory.text = place.category
        lblPrice.text = place.price
    }
}

extension PlaceDetailViewController: UITableViewDataSource, UITableViewDelegate, PlaceDetailMapCellDelegate {
    
    // MARK: - UITableViewDelegate & Datasource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return intCellCount + intSimilarNearbySection
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        func similarNearbyCount() -> Int {
            let count = intSimilar + intNearby
            if count == 0 {
                return 0
            } else if count == 1 {
                return 1
            } else {
                return 2
            }
        }
        
        if intHaveHour == 0 && intHaveWebPhone == 0 {
            if section == 0 {
                return boolMapFold ? 1 : 2
            } else {
                return similarNearbyCount()
            }
        } else if intHaveHour == 0 && intHaveWebPhone == 1 {
            if section == 0 {
                return boolMapFold ? 1 : 2
            } else if section == 1 {
                if place.phone == "" { return 1 }
                if place.url == "" { return 1 }
                return 2
            } else {
                return similarNearbyCount()
            }
        } else if intHaveHour == 1 && intHaveWebPhone == 0  {
            if section == 0 {
                return boolMapFold ? 1 : 2
            } else if section == 1 {
                return boolHourFold ? 1 : 9
            } else {
                return similarNearbyCount()
            }
        } else {
            if section == 0 {  // map
                return boolMapFold ? 1 : 2
            } else if section == 1 {  // hours
                return boolHourFold ? 1 : 9
            } else if section == 2 {  // web & phone
                if place.phone == "" { return 1 }
                if place.url == "" { return 1 }
                return 2
            } else {
                return similarNearbyCount()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tblPlaceDetail.rowHeight = UITableViewAutomaticDimension
        tblPlaceDetail.estimatedRowHeight = 60
        let section = indexPath.section
        if intHaveHour == 0 && intHaveWebPhone == 0 {
            if section == 0 {
                return tblPlaceDetail.rowHeight
            } else {
                return 222
            }
        } else if intHaveHour == 1 && intHaveWebPhone == 1 {
            if section <= 2 {
                return tblPlaceDetail.rowHeight
            } else {
                return 222
            }
        } else {
            if section <= 1 {
                return tblPlaceDetail.rowHeight
            } else {
                return 222
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        if intHaveHour == 0 && intHaveWebPhone == 0 {
            if section == 0 {
                return indexPath.row == 0 ? getDetailCell(tableView, indexPath, "map") : getMapDetailCell(tableView, indexPath)
            } else {
                return getMBCell(tableView, indexPath)
            }
        } else if intHaveHour == 0 && intHaveWebPhone == 1 {
            if section == 0 {
                return indexPath.row == 0 ? getDetailCell(tableView, indexPath, "map") : getMapDetailCell(tableView, indexPath)
            } else if section == 1 {
                if place.phone == "" && row == 0 {
                    return getDetailCell(tableView, indexPath, "web")
                } else if place.url == "" && row == 0 {
                    return getDetailCell(tableView, indexPath, "phone")
                } else if indexPath.row == 0 {
                    return getDetailCell(tableView, indexPath, "web")
                } else {
                    return getDetailCell(tableView, indexPath, "phone")
                }
            } else {
                return getMBCell(tableView, indexPath)
            }
        } else if intHaveHour == 1 && intHaveWebPhone == 0  {
            if section == 0 {  // map
                return indexPath.row == 0 ? getDetailCell(tableView, indexPath, "map") : getMapDetailCell(tableView, indexPath)
            } else if section == 1 {  // hours
                if indexPath.row == 0 {
                    return getDetailCell(tableView, indexPath, "hour")
                } else if indexPath.row == 8 {
                    return getHoursHintCell(tableView, indexPath)
                } else {
                    return getOpeningHoursCell(tableView, indexPath)
                }
            } else {
                return getMBCell(tableView, indexPath)
            }
        } else {
            if section == 0 {
                return indexPath.row == 0 ? getDetailCell(tableView, indexPath, "map") : getMapDetailCell(tableView, indexPath)
            } else if section == 1 {
                if indexPath.row == 0 {
                    return getDetailCell(tableView, indexPath, "hour")
                } else if indexPath.row == 8 {
                    return getHoursHintCell(tableView, indexPath)
                } else {
                    return getOpeningHoursCell(tableView, indexPath)
                }
            } else if section == 2 {
                if place.phone == "" && row == 0 {
                    return getDetailCell(tableView, indexPath, "web")
                } else if place.url == "" && row == 0 {
                    return getDetailCell(tableView, indexPath, "phone")
                } else if indexPath.row == 0 {
                    return getDetailCell(tableView, indexPath, "web")
                } else {
                    return getDetailCell(tableView, indexPath, "phone")
                }
            } else {
                return getMBCell(tableView, indexPath)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func tapMapOrHour(_ identifier: String) {
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            switch identifier {
            case "map":
                if mapIndexPath.count == 0 {
                    return
                }
                boolMapFold = !boolMapFold
                
                if !boolMapFold {
                    tableView.insertRows(at: mapIndexPath, with: .none)
                } else {
                    tableView.deleteRows(at: mapIndexPath, with: .none)
                }
                tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            case "hour":
                if hourIndexPath.count == 0 {
                    return
                }
                boolHourFold = !boolHourFold
                
                if !boolHourFold {
                    tableView.insertRows(at: hourIndexPath, with: .none)
                } else {
                    tableView.deleteRows(at: hourIndexPath, with: .none)
                }
                tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
            default:
                break
            }
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            
            uiviewPlaceImages.removeFromSuperview()
            uiviewHeader.addSubview(uiviewPlaceImages)
            uiviewPlaceImages.loadPageCtrl()
        }
        
        func tapWebOrPhone() {
            var strURL = ""
            if boolHaveWeb && indexPath.row == 0 {
                strURL = place.url
            } else {
                let phoneNum = place.phone.onlyNumbers()
                strURL = "tel://\(phoneNum)"
            }
            if let url = URL(string: strURL), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        let section = indexPath.section
        if intHaveHour == 0 && intHaveWebPhone == 0 {
            if section == 0 {
                tapMapOrHour("map")
            }
        } else if intHaveHour == 0 && intHaveWebPhone == 1 {
            if section == 0 {
                tapMapOrHour("map")
            } else if section == 1 {
                tapWebOrPhone()
            }
        } else if intHaveHour == 1 && intHaveWebPhone == 0  {
            if section == 0 {
                tapMapOrHour("map")
            } else if section == 1 {
                tapMapOrHour("hour")
            }
        } else {
            if section == 0 {
                tapMapOrHour("map")
            } else if section == 1 {
                tapMapOrHour("hour")
            } else if section == 2 {
                tapWebOrPhone()
            }
        }
    }
    
    func getMBCell(_ tableView: UITableView, _ indexPath: IndexPath) -> BoardPlacesCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BoardPlacesCell", for: indexPath) as! BoardPlacesCell
        cell.delegate = self
        let count = intSimilar + intNearby
        if count == 1 {
            if intSimilar == 1 {
                if let viewModelSimilar = viewModelSimilar {
                    cell.setValueForCell(viewModelPlaces: viewModelSimilar)
                }
            } else {
                if let viewModelNearby = viewModelNearby {
                    cell.setValueForCell(viewModelPlaces: viewModelNearby)
                }
            }
        } else {
            if indexPath.row == 0 {
                if let viewModelSimilar = viewModelSimilar {
                    cell.setValueForCell(viewModelPlaces: viewModelSimilar)
                }
            } else {
                if let viewModelNearby = viewModelNearby {
                    cell.setValueForCell(viewModelPlaces: viewModelNearby)
                }
            }
        }
        return cell
    }
    
    func getDetailCell(_ tableView: UITableView, _ indexPath: IndexPath, _ identifier: String) -> PlaceDetailCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! PlaceDetailCell
        cell.setValueForCell(identifier, place: place)
        
        if identifier == "map" {
            if !boolMapFold {
                cell.foldOrUnfold(0, true, #imageLiteral(resourceName: "arrow_up"), 10)
            } else {
                cell.foldOrUnfold(1, false, #imageLiteral(resourceName: "arrow_down"), 18)
            }
        } else if identifier == "hour" {
            if !boolHourFold {
                cell.foldOrUnfold(0, true, #imageLiteral(resourceName: "arrow_up"), 11)
            } else {
                cell.foldOrUnfold(0, false, #imageLiteral(resourceName: "arrow_down"), 18)
            }
        }
        
        return cell
    }
    
    func getMapDetailCell(_ tableView: UITableView, _ indexPath: IndexPath) -> PlaceDetailMapCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceDetailMapCell", for: indexPath) as! PlaceDetailMapCell
        cell.delegate = self
        cell.setValueForCell(place: place)
        return cell
    }
    
    func getOpeningHoursCell(_ tableView: UITableView, _ indexPath: IndexPath) -> PlaceOpeningHourCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceOpeningHourCell", for: indexPath) as! PlaceOpeningHourCell
        let row = (indexPath.row - 1 + dayIdx) % arrDay.count
        let day = arrDay_LG[row]
        let hour = place.hours[arrDay[row]] ?? ["N/A"]
        cell.setValueForOpeningHourCell(day, hour, bold: indexPath.row == 1)
        return cell
    }

    func getHoursHintCell(_ tableView: UITableView, _ indexPath: IndexPath) -> PlaceHoursHintCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceHoursHintCell", for: indexPath) as! PlaceHoursHintCell
        return cell
    }
    
    func calculateTodayDate() {
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        
        // components.weekday 2 - Mon, 3 - Tue, 4 - Wed, 5 - Thur, 6 - Fri, 7 - Sat, 8 - Sun
        if let weekday = components.weekday {
            dayIdx = weekday
            
            if weekday == 7 {
                dayIdx = 0
            } else if weekday == 8 {
                dayIdx = 1
            }
        }
    }
    
    func jumpToMainMapWithPlace() {
        let vcMap = PlaceViewMapController()
        vcMap.placePin = self.place
        vcMap.mapCenter = .placeCoordinate
        navigationController?.pushViewController(vcMap, animated: false)
    }
}

extension PlaceDetailViewController {
    
    private func loadGuestMode() {
        uiviewGuestMode = GuestModeView()
        view.addSubview(uiviewGuestMode)
        uiviewGuestMode.show()
        uiviewGuestMode.dismissGuestMode = { [weak self] in
            self?.removeGuestMode()
        }
        uiviewGuestMode.guestLogin = { [weak self] in
            Key.shared.navOpenMode = .welcomeFirst
            let viewCtrlers = [WelcomeViewController(), LogInViewController()]
            self?.navigationController?.setViewControllers(viewCtrlers, animated: true)
        }
        uiviewGuestMode.guestRegister = { [weak self] in
            Key.shared.navOpenMode = .welcomeFirst
            let viewCtrlers = [WelcomeViewController(), RegisterNameViewController()]
            self?.navigationController?.setViewControllers(viewCtrlers, animated: true)
        }
    }
    
    private func removeGuestMode() {
        guard uiviewGuestMode != nil else { return }
        uiviewGuestMode.hide {
            self.uiviewGuestMode.removeFromSuperview()
        }
    }
    
}
