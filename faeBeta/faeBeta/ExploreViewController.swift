//
//  ExploreViewController.swift
//  faeBeta
//
//  Created by Yue Shen on 9/12/17.
//  Modified by Yue Shen on 5/7/18.
//  Copyright © 2017 fae. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreLocation
import Alamofire

protocol ExploreDelegate: class {
    func jumpToExpPlacesCollection(places: [PlacePin], category: String)
}

class ExploreViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AddPinToCollectionDelegate, AfterAddedToListDelegate, SelectLocationDelegate, EXPCellDelegate {
    
    // MARK: - Variables
    
    // MARK: Main Items
    weak var delegate: ExploreDelegate?
    
    private var uiviewNavBar: FaeNavBar!
    private var scrlViewTypes: UIScrollView!
    private var dictTypeBtns = [String: UIButton]()
    private var clctViewPlaceCard: UICollectionView!
    private var lblBottomLocation: UILabel!
    private var btnGoLeft: UIButton!
    private var btnGoRight: UIButton!
    private var btnSave: UIButton!
    private var btnRefresh: UIButton!
    private var btnMap: UIButton!
    private var imgSaved: UIImageView!
    
    private var intCurtPage = 0
    
    private var categories: [String] = ["Random", "Food", "Drinks", "Shopping", "Outdoors", "Recreation"]
    private var categoryState: [String: CategoryState] = ["Random": .initial, "Food": .initial, "Drinks": .initial, "Shopping": .initial, "Outdoors": .initial, "Recreation": .initial]
    
    // MARK: Requests
    private var requests = [String: DataRequest]()
    
    // MARK: Six Types Categories
    private var arrRandom = [PlacePin]()
    private var arrFood = [PlacePin]()
    private var arrDrinks = [PlacePin]()
    private var arrShopping = [PlacePin]()
    private var arrOutdoors = [PlacePin]()
    private var arrRecreation = [PlacePin]()
    
    // MARK: Loading Waves
    private var uiviewAvatarWaveSub: UIView!
    private var imgAvatar: FaeAvatarView!
    private var filterCircle_1: UIImageView!
    private var filterCircle_2: UIImageView!
    private var filterCircle_3: UIImageView!
    private var filterCircle_4: UIImageView!
    
    // MARK: Collecting Pin Control
    private var uiviewSavedList: AddPinToCollectionView!
    private var uiviewAfterAdded: AfterAddedToListView!
    private var arrListSavedThisPin = [Int]()
    
    private var fullyLoaded = false
    private var coordinate: CLLocationCoordinate2D!
    private var strLocation: String = ""
    private var lblNoResults: FaeLabel!
    
    private var USE_TEST_PLACE = false
    
    // Guest Mode
    private var uiviewGuestMode: GuestModeView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        loadNavBar()
        loadAvatar()
        DispatchQueue.main.async {
            self.loadContent()
            self.reloadBottomText("Loading...", "")
            var location: CLLocation!
            if let loc = LocManager.shared.locToSearch_explore {
                location = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            } else {
                location = LocManager.shared.curtLoc
            }
            self.coordinate = location.coordinate
            self.searchAllCategories()
            General.shared.getAddress(location: location, original: false, full: false, detach: true) { [weak self] (status, address) in
                guard let `self` = self else { return }
                guard status != 400 else {
                    self.lblBottomLocation.text = "Querying for location too fast!"
                    self.lblBottomLocation.isHidden = false
                    return
                }
                if let addr = address as? String {
                    let new = addr.split(separator: "@")
                    self.reloadBottomText(String(new[0]), String(new[1]))
                    self.strLocation = "\(String(new[0])), \(String(new[1]))"
                }
            }
            self.fullyLoaded = true
        }
        NotificationCenter.default.addObserver(self, selector: #selector(showSavedNoti), name: NSNotification.Name(rawValue: "showSavedNoti_explore"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideSavedNoti), name: NSNotification.Name(rawValue: "hideSavedNoti_explore"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadWaves()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cancelAllRequests()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "showSavedNoti_explore"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showSavedNoti), name: NSNotification.Name(rawValue: "hideSavedNoti_explore"), object: nil)
    }
    
    // MARK: - Loading Content
    
    private func loadContent() {
        loadSearchTypesCollection()
        loadPlaceCardCollection()
        loadButtons()
        loadBottomLocation()
        loadPlaceListView()
        loadNoResultLabel()
        let edgeView = LeftMarginToEnableNavGestureView()
        view.addSubview(edgeView)
    }
    
    private func loadPlaceListView() {
        uiviewSavedList = AddPinToCollectionView()
        uiviewSavedList.delegate = self
//        uiviewSavedList.loadCollectionData()
        view.addSubview(uiviewSavedList)
        
        uiviewAfterAdded = AfterAddedToListView()
        uiviewAfterAdded.delegate = self
        view.addSubview(uiviewAfterAdded)
        
        uiviewSavedList.uiviewAfterAdded = uiviewAfterAdded
    }
    
    private func loadNoResultLabel() {
        var y_offset: CGFloat = 550
        switch screenHeight {
        case 736, 667:
            y_offset = 515 * screenHeightFactor
        case 568:
            y_offset = 350
        default:
            break
        }
        lblNoResults = FaeLabel(CGRect(x: 0, y: y_offset, width: 270, height: 88) , .center, .medium, 16, UIColor._146146146())
        lblNoResults.center.x = screenWidth / 2
        lblNoResults.numberOfLines = 3
        lblNoResults.text = "Sorry… we can’t suggest any place\ncards currently, please try a different\nlocation or check back later!"
        view.addSubview(lblNoResults)
        lblNoResults.alpha = 0
    }
    
    private func loadAvatar() {
        let xAxis: CGFloat = screenWidth / 2
        var yAxis: CGFloat = 324.5 * screenHeightFactor
        yAxis += screenHeight == 812 ? 80 : 0
        
        uiviewAvatarWaveSub = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenWidth))
        uiviewAvatarWaveSub.center = CGPoint(x: xAxis, y: yAxis)
        view.addSubview(uiviewAvatarWaveSub)
        
        let imgAvatarSub = UIImageView(frame: CGRect(x: 0, y: 0, width: 98, height: 98))
        imgAvatarSub.contentMode = .scaleAspectFill
        imgAvatarSub.image = #imageLiteral(resourceName: "exp_avatar_border")
        imgAvatarSub.center = CGPoint(x: xAxis, y: xAxis)
        uiviewAvatarWaveSub.addSubview(imgAvatarSub)
        
        imgAvatar = FaeAvatarView(frame: CGRect(x: 0, y: 0, width: 86, height: 86))
        imgAvatar.layer.cornerRadius = 43
        imgAvatar.contentMode = .scaleAspectFill
        imgAvatar.center = CGPoint(x: xAxis, y: xAxis)
        imgAvatar.isUserInteractionEnabled = false
        imgAvatar.clipsToBounds = true
        uiviewAvatarWaveSub.addSubview(imgAvatar)
        if Key.shared.is_guest {
            imgAvatar.image = #imageLiteral(resourceName: "default_gray_avatar")
        } else {
            imgAvatar.userID = Key.shared.user_id
            imgAvatar.loadAvatar(id: Key.shared.user_id)
        }
    }
    
    private func loadWaves() {
        func createFilterCircle() -> UIImageView {
            let xAxis: CGFloat = screenWidth / 2
            let imgView = UIImageView(frame: CGRect.zero)
            imgView.frame.size = CGSize(width: 98, height: 98)
            imgView.center = CGPoint(x: xAxis, y: xAxis)
            imgView.image = #imageLiteral(resourceName: "exp_wave")
            imgView.tag = 0
            return imgView
        }
        if filterCircle_1 != nil {
            filterCircle_1.removeFromSuperview()
            filterCircle_2.removeFromSuperview()
            filterCircle_3.removeFromSuperview()
            filterCircle_4.removeFromSuperview()
        }
        filterCircle_1 = createFilterCircle()
        filterCircle_2 = createFilterCircle()
        filterCircle_3 = createFilterCircle()
        filterCircle_4 = createFilterCircle()
        uiviewAvatarWaveSub.addSubview(filterCircle_1)
        uiviewAvatarWaveSub.addSubview(filterCircle_2)
        uiviewAvatarWaveSub.addSubview(filterCircle_3)
        uiviewAvatarWaveSub.addSubview(filterCircle_4)
        uiviewAvatarWaveSub.sendSubview(toBack: filterCircle_1)
        uiviewAvatarWaveSub.sendSubview(toBack: filterCircle_2)
        uiviewAvatarWaveSub.sendSubview(toBack: filterCircle_3)
        uiviewAvatarWaveSub.sendSubview(toBack: filterCircle_4)
        
        waveAnimation(circle: filterCircle_1, delay: 0)
        waveAnimation(circle: filterCircle_2, delay: 0.5)
        waveAnimation(circle: filterCircle_3, delay: 2)
        waveAnimation(circle: filterCircle_4, delay: 2.5)
    }
    
    private func waveAnimation(circle: UIImageView, delay: Double) {
        let animateTime: Double = 3
        let radius: CGFloat = screenWidth
        let newFrame = CGRect(x: 0, y: 0, width: radius, height: radius)
        
        let xAxis: CGFloat = screenWidth / 2
        circle.frame.size = CGSize(width: 98, height: 98)
        circle.center = CGPoint(x: xAxis, y: xAxis)
        circle.alpha = 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIView.animate(withDuration: animateTime, delay: 0, options: [.curveEaseOut], animations: ({
                circle.alpha = 0.0
                circle.frame = newFrame
            }), completion: { _ in
                self.waveAnimation(circle: circle, delay: 0.75)
            })
        }
    }
    
    private func loadSearchTypesCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 20
        layout.estimatedItemSize = CGSize(width: 80, height: 36)
        
        scrlViewTypes = UIScrollView()
        scrlViewTypes.backgroundColor = .clear
        scrlViewTypes.showsHorizontalScrollIndicator = false
        scrlViewTypes.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        view.addSubview(scrlViewTypes)
        view.addConstraintsWithFormat("H:|-0-[v0]-0-|", options: [], views: scrlViewTypes)
        view.addConstraintsWithFormat("V:|-\(73+device_offset_top)-[v0(36)]", options: [], views: scrlViewTypes)
        
        var last_offset: CGFloat = 20
        var tag = 0
        for category in categories {
            let button = UIButton()
            button.setTitle(category, for: .normal)
            button.titleLabel?.font = FaeFont(fontType: .medium, size: 15)
            button.setTitleColor(.lightGray, for: .normal)
            
            let width = category.width(withConstrainedWidth: 36, font: FaeFont(fontType: .medium, size: 15))
            button.frame.origin = CGPoint(x: last_offset, y: 0)
            button.frame.size = CGSize(width: width + 3.0, height: 36)
            last_offset = button.frame.origin.x + width + 23.0
            
            button.tag = tag
            tag += 1
            
            button.addTarget(self, action: #selector(actionTypeButtonTap(_:)), for: .touchUpInside)
            
            dictTypeBtns[category] = button
            scrlViewTypes.addSubview(button)
        }
        scrlViewTypes.contentSize.width = last_offset - 23.0
    }
    
    private func loadPlaceCardCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: screenWidth, height: screenHeight - 116 - 156)
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        clctViewPlaceCard = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        clctViewPlaceCard.register(EXPClctPicCell.self, forCellWithReuseIdentifier: "exp_pics")
        clctViewPlaceCard.delegate = self
        clctViewPlaceCard.dataSource = self
        clctViewPlaceCard.isPagingEnabled = true
        clctViewPlaceCard.backgroundColor = UIColor.clear
        clctViewPlaceCard.showsHorizontalScrollIndicator = false
        clctViewPlaceCard.alpha = 0
        view.addSubview(clctViewPlaceCard)
        view.addConstraintsWithFormat("H:|-0-[v0]-0-|", options: [], views: clctViewPlaceCard)
        view.addConstraintsWithFormat("V:|-\(116+device_offset_top)-[v0]-\(156+device_offset_bot)-|", options: [], views: clctViewPlaceCard)
    }
    
    private func loadButtons() {
        let uiviewBtnSub = UIView(frame: CGRect(x: (screenWidth - 370) / 2, y: screenHeight - 138 - device_offset_bot, width: 370, height: 78))
        view.addSubview(uiviewBtnSub)
        
        btnGoLeft = UIButton()
        btnGoLeft.setImage(#imageLiteral(resourceName: "exp_go_left"), for: .normal)
        btnGoLeft.addTarget(self, action: #selector(actionSwitchPage(_:)), for: .touchUpInside)
        uiviewBtnSub.addSubview(btnGoLeft)
        uiviewBtnSub.addConstraintsWithFormat("H:|-0-[v0(78)]", options: [], views: btnGoLeft)
        uiviewBtnSub.addConstraintsWithFormat("V:|-0-[v0(78)]", options: [], views: btnGoLeft)
        
        btnSave = UIButton()
        btnSave.setImage(#imageLiteral(resourceName: "exp_save"), for: .normal)
        btnSave.addTarget(self, action: #selector(actionSave(_:)), for: .touchUpInside)
        uiviewBtnSub.addSubview(btnSave)
        uiviewBtnSub.addConstraintsWithFormat("H:|-82-[v0(66)]", options: [], views: btnSave)
        uiviewBtnSub.addConstraintsWithFormat("V:|-6-[v0(66)]", options: [], views: btnSave)
        imgSaved = UIImageView(frame: CGRect(x: 50, y: 16, width: 0, height: 0))
        imgSaved.image = #imageLiteral(resourceName: "place_new_collected")
        imgSaved.alpha = 0
        btnSave.addSubview(imgSaved)
        
        btnRefresh = UIButton()
        btnRefresh.setImage(#imageLiteral(resourceName: "exp_refresh"), for: .normal)
        btnRefresh.addTarget(self, action: #selector(actionRefresh), for: .touchUpInside)
        uiviewBtnSub.addSubview(btnRefresh)
        uiviewBtnSub.addConstraintsWithFormat("H:|-152-[v0(66)]", options: [], views: btnRefresh)
        uiviewBtnSub.addConstraintsWithFormat("V:|-6-[v0(66)]", options: [], views: btnRefresh)
        
        btnMap = UIButton()
        btnMap.setImage(#imageLiteral(resourceName: "exp_map"), for: .normal)
        btnMap.addTarget(self, action: #selector(actionExpMap), for: .touchUpInside)
        uiviewBtnSub.addSubview(btnMap)
        uiviewBtnSub.addConstraintsWithFormat("H:[v0(66)]-82-|", options: [], views: btnMap)
        uiviewBtnSub.addConstraintsWithFormat("V:|-6-[v0(66)]", options: [], views: btnMap)
        
        btnGoRight = UIButton()
        btnGoRight.setImage(#imageLiteral(resourceName: "exp_go_right"), for: .normal)
        btnGoRight.addTarget(self, action: #selector(actionSwitchPage(_:)), for: .touchUpInside)
        uiviewBtnSub.addSubview(btnGoRight)
        uiviewBtnSub.addConstraintsWithFormat("H:[v0(78)]-0-|", options: [], views: btnGoRight)
        uiviewBtnSub.addConstraintsWithFormat("V:|-0-[v0(78)]", options: [], views: btnGoRight)
    }
    
    private func loadBottomLocation() {
        lblBottomLocation = UILabel()
        lblBottomLocation.numberOfLines = 1
        lblBottomLocation.textAlignment = .center
        lblBottomLocation.isUserInteractionEnabled = true
        view.addSubview(lblBottomLocation)
        view.addConstraintsWithFormat("H:|-0-[v0]-0-|", options: [], views: lblBottomLocation)
        view.addConstraintsWithFormat("V:[v0(25)]-\(19+device_offset_bot)-|", options: [], views: lblBottomLocation)
        lblBottomLocation.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapToChooseLoc(_:)))
        lblBottomLocation.addGestureRecognizer(tapGesture)
    }
    
    private func loadNavBar() {
        uiviewNavBar = FaeNavBar()
        view.addSubview(uiviewNavBar)
        uiviewNavBar.rightBtn.isHidden = true
        uiviewNavBar.loadBtnConstraints()
        
        let title_0 = "Explore "
        let title_1 = "Around Me"
        let attrs_0 = [NSAttributedStringKey.foregroundColor: UIColor._898989(), NSAttributedStringKey.font: UIFont(name: "AvenirNext-Medium", size: 20)!]
        let attrs_1 = [NSAttributedStringKey.foregroundColor: UIColor._2499090(), NSAttributedStringKey.font: UIFont(name: "AvenirNext-Medium", size: 20)!]
        let title_0_attr = NSMutableAttributedString(string: title_0, attributes: attrs_0)
        let title_1_attr = NSMutableAttributedString(string: title_1, attributes: attrs_1)
        title_0_attr.append(title_1_attr)
        
        uiviewNavBar.lblTitle.attributedText = title_0_attr
        uiviewNavBar.leftBtn.addTarget(self, action: #selector(actionBack(_:)), for: .touchUpInside)
    }
    
    // MARK: - Button Actions
    
    @objc private func actionExpMap() {
        var arrPlaceData = [PlacePin]()
        let lastSelectedRow = Key.shared.selectedTypeIdx_explore.row
        let cat = categories[lastSelectedRow]
        switch cat {
        case "Random":
            arrPlaceData = arrRandom
        case "Food":
            arrPlaceData = arrFood
        case "Drinks":
            arrPlaceData = arrDrinks
        case "Shopping":
            arrPlaceData = arrShopping
        case "Outdoors":
            arrPlaceData = arrOutdoors
        case "Recreation":
            arrPlaceData = arrRecreation
        default:
            break
        }
        let vc = ExploreMapController()
        vc.arrExpPlace = arrPlaceData
        vc.strCategory = cat
        navigationController?.pushViewController(vc, animated: false)
    }
    
    @objc private func actionSave(_ sender: UIButton) {
        guard !Key.shared.is_guest else {
            loadGuestMode()
            return
        }
        uiviewSavedList.show()
    }
    
    @objc private func actionSwitchPage(_ sender: UIButton) {
        var arrCount = 0
        let lastSelectedRow = Key.shared.selectedTypeIdx_explore.row
        let cat = categories[lastSelectedRow]
        switch cat {
        case "Random":
            arrCount = arrRandom.count
        case "Food":
            arrCount = arrFood.count
        case "Drinks":
            arrCount = arrDrinks.count
        case "Shopping":
            arrCount = arrShopping.count
        case "Outdoors":
            arrCount = arrOutdoors.count
        case "Recreation":
            arrCount = arrRecreation.count
        default:
            break
        }
        var numPage = intCurtPage
        if sender == btnGoLeft {
            numPage -= 1
        } else {
            numPage += 1
        }
        if numPage < 0 {
            numPage = arrCount - 1
        } else if numPage >= arrCount {
            numPage = 0
        }
        if (numPage == 0 && intCurtPage != 1) || (numPage == arrCount - 1 && intCurtPage != arrCount - 2) {
            UIView.animate(withDuration: 0.3, animations: {
                self.clctViewPlaceCard.alpha = 0
            }, completion: { _ in
                self.clctViewPlaceCard.setContentOffset(CGPoint(x: screenWidth * CGFloat(numPage), y: 0), animated: false)
                self.intCurtPage = numPage
                self.checkSavedStatus(idx: self.intCurtPage)
                UIView.animate(withDuration: 0.3, animations: {
                    self.clctViewPlaceCard.alpha = 1
                }, completion: { _ in
                    
                })
            })
        } else {
            clctViewPlaceCard.setContentOffset(CGPoint(x: screenWidth * CGFloat(numPage), y: 0), animated: true)
            intCurtPage = numPage
            checkSavedStatus(idx: intCurtPage)
        }
    }
    
    @objc private func actionBack(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func actionRefresh() {
        guard coordinate != nil else { return }
        showWaves()
        buttonEnable(on: false)
        search(category: Key.shared.lastCategory_explore, indexPath: Key.shared.selectedTypeIdx_explore)
        resetVisitedIndex()
    }
    
    private func resetVisitedIndex() {
        intCurtPage = 0
    }
    
    // MARK: - Other Functions
    
    private func buttonEnable(on: Bool) {
        btnGoLeft.isEnabled = on
        btnSave.isEnabled = on
        btnRefresh.isEnabled = on
        btnMap.isEnabled = on
        btnGoRight.isEnabled = on
        scrlViewTypes.isUserInteractionEnabled = on
    }
    
    // MARK: Save Noti
    
    @objc private func showSavedNoti() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.imgSaved.frame = CGRect(x: 41, y: 7, width: 18, height: 18)
            self.imgSaved.alpha = 1
        }, completion: nil)
    }
    
    @objc private func hideSavedNoti() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.imgSaved.frame = CGRect(x: 50, y: 16, width: 0, height: 0)
            self.imgSaved.alpha = 0
        }, completion: nil)
    }
    
    // MARK: Location Text
    private func reloadBottomText(_ city: String, _ state: String) {
        
        strLocation = "\(city), \(state)"
        let fullAttrStr = NSMutableAttributedString()
        let firstImg = #imageLiteral(resourceName: "mapSearchCurrentLocation")
        let first_attch = InlineTextAttachment()
        first_attch.fontDescender = -2
        first_attch.image = UIImage(cgImage: (firstImg.cgImage)!, scale: 3, orientation: .up)
        let firstImg_attach = NSAttributedString(attachment: first_attch)
        
        let secondImg = #imageLiteral(resourceName: "exp_bottom_loc_arrow")
        let second_attch = InlineTextAttachment()
        second_attch.fontDescender = -1
        second_attch.image = UIImage(cgImage: (secondImg.cgImage)!, scale: 3, orientation: .up)
        let secondImg_attach = NSAttributedString(attachment: second_attch)
        let attrs_0 = [NSAttributedStringKey.foregroundColor: UIColor._898989(), NSAttributedStringKey.font: UIFont(name: "AvenirNext-Medium", size: 16)!]
        let title_0_attr = NSMutableAttributedString(string: "  " + city + " ", attributes: attrs_0)
        
        let attrs_1 = [NSAttributedStringKey.foregroundColor: UIColor._138138138(), NSAttributedStringKey.font: UIFont(name: "AvenirNext-Medium", size: 13)!]
        let title_1_attr = NSMutableAttributedString(string: state + "  ", attributes: attrs_1)
        
        fullAttrStr.append(firstImg_attach)
        fullAttrStr.append(title_0_attr)
        fullAttrStr.append(title_1_attr)
        fullAttrStr.append(secondImg_attach)
        DispatchQueue.main.async {
            self.lblBottomLocation.attributedText = fullAttrStr
            self.lblBottomLocation.isHidden = false
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = clctViewPlaceCard.frame.size.width
        intCurtPage = Int(clctViewPlaceCard.contentOffset.x / pageWidth)
        checkSavedStatus(idx: intCurtPage)
    }
    
    // MARK: - Pin Info
    
    private func checkSavedStatus(idx: Int) {
        var arrPlaceData = [PlacePin]()
        let lastSelectedRow = Key.shared.selectedTypeIdx_explore.row
        let cat = categories[lastSelectedRow]
        switch cat {
        case "Random":
            arrPlaceData = arrRandom
        case "Food":
            arrPlaceData = arrFood
        case "Drinks":
            arrPlaceData = arrDrinks
        case "Shopping":
            arrPlaceData = arrShopping
        case "Outdoors":
            arrPlaceData = arrOutdoors
        case "Recreation":
            arrPlaceData = arrRecreation
        default:
            break
        }
        guard idx < arrPlaceData.count else { return }
        uiviewSavedList.pinToSave = FaePinAnnotation(type: .place, cluster: nil, data: arrPlaceData[idx] as AnyObject)
        getPinSavedInfo(id: arrPlaceData[idx].id, type: "place") { [weak self] (ids) in
            guard let `self` = self else { return }
            self.arrListSavedThisPin = ids
            self.uiviewSavedList.arrListSavedThisPin = ids
            if ids.count > 0 {
                self.showSavedNoti()
            } else {
                self.hideSavedNoti()
            }
        }
    }
    
    private func getPinSavedInfo(id: Int, type: String, _ completion: @escaping ([Int]) -> Void) {
        FaeMap.shared.getPin(type: type, pinId: String(id)) { (status, message) in
            guard status / 100 == 2 else { return }
            guard message != nil else { return }
            let resultJson = JSON(message!)
            var ids = [Int]()
            guard let is_saved = resultJson["user_pin_operations"]["is_saved"].string else {
                completion(ids)
                return
            }
            guard is_saved != "false" else { return }
            for colIdRaw in is_saved.split(separator: ",") {
                let strColId = String(colIdRaw)
                guard let colId = Int(strColId) else { continue }
                ids.append(colId)
            }
            completion(ids)
        }
    }
    
    // MARK: - Gesture Recognizers
    
    @objc private func tapToChooseLoc(_ tap: UITapGestureRecognizer) {
        let vc = SelectLocationViewController()
        vc.delegate = self
        vc.mode = .part
        vc.previousVC = .explore
        navigationController?.pushViewController(vc, animated: false)
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: screenWidth, height: screenHeight - 116 - 156 - device_offset_top - device_offset_bot)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == clctViewPlaceCard {
            let selectedIdxRow = Key.shared.selectedTypeIdx_explore.row
            let isInitial = categoryState[categories[selectedIdxRow]] != .initial
            var count = 0
            switch selectedIdxRow {
            case 0:
                count = arrRandom.count
            case 1:
                count = arrFood.count
            case 2:
                count = arrDrinks.count
            case 3:
                count = arrShopping.count
            case 4:
                count = arrOutdoors.count
            case 5:
                count = arrRecreation.count
            default:
                return 0
            }
            lblNoResults.alpha = count == 0 && isInitial ? 1 : 0
            if count == 0 {
                showWaves()
            } else {
                hideWaves()
            }
            return count
        }
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == clctViewPlaceCard {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "exp_pics", for: indexPath) as! EXPClctPicCell
            cell.delegate = self
            var data: PlacePin!
            let lastSelectedRow = Key.shared.selectedTypeIdx_explore.row
            let cat = categories[lastSelectedRow]
            switch cat {
            case "Random":
                data = arrRandom[indexPath.row]
            case "Food":
                data = arrFood[indexPath.row]
            case "Drinks":
                data = arrDrinks[indexPath.row]
            case "Shopping":
                data = arrShopping[indexPath.row]
            case "Outdoors":
                data = arrOutdoors[indexPath.row]
            case "Recreation":
                data = arrRecreation[indexPath.row]
            default:
                break
            }
            cell.updateCell(placeData: data)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "exp_types", for: indexPath) as! EXPClctTypeCell
            
            let cat = categories[indexPath.row]
            cell.updateTitle(type: cat)
            cell.indexPath = indexPath
            
            if let catState = categoryState[cat] {
                cell.state = catState
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == clctViewPlaceCard {
            var placePin: PlacePin!
            let lastSelectedRow = Key.shared.selectedTypeIdx_explore.row
            let cat = categories[lastSelectedRow]
            switch cat {
            case "Random":
                placePin = arrRandom[indexPath.row]
            case "Food":
                placePin = arrFood[indexPath.row]
            case "Drinks":
                placePin = arrDrinks[indexPath.row]
            case "Shopping":
                placePin = arrShopping[indexPath.row]
            case "Outdoors":
                placePin = arrOutdoors[indexPath.row]
            case "Recreation":
                placePin = arrRecreation[indexPath.row]
            default:
                break
            }
            let vcPlaceDetail = PlaceDetailViewController()
            vcPlaceDetail.place = placePin
            navigationController?.pushViewController(vcPlaceDetail, animated: true)
        }
    }
    
    @objc private func actionTypeButtonTap(_ button: UIButton) {
        let indexPath = IndexPath(row: button.tag, section: 0)
        let lastCategory = Key.shared.lastCategory_explore
        if let lastBtn = dictTypeBtns[lastCategory] {
            changeTypeButtonState(lastBtn, .read)
        }
        if let curtBtn = dictTypeBtns[categories[button.tag]] {
            changeTypeButtonState(curtBtn, .selected)
        }
        Key.shared.selectedTypeIdx_explore = indexPath
        Key.shared.lastCategory_explore = categories[button.tag]
        clctViewPlaceCard.setContentOffset(.zero, animated: false)
        clctViewPlaceCard.reloadData()
    }
    
    // MARK: - EXPCellDelegate
    func jumpToPlaceDetail(_ placeInfo: PlacePin) {
        let vcPlaceDetail = PlaceDetailViewController()
        vcPlaceDetail.place = placeInfo
        navigationController?.pushViewController(vcPlaceDetail, animated: true)
    }
    
    // MARK: - Category Search
    
    private func searchAllCategories() {
        buttonEnable(on: false)
        for i in 0..<categories.count {
            search(category: categories[i], indexPath: IndexPath(row: i, section: 0))
        }
    }
    
    private func loadPlaces(center: CLLocationCoordinate2D, indexPath: IndexPath) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.requests["Random"] = General.shared.getPlacePins(coordinate: center, radius: 0, count: 200, completion: { [weak self] (status, placesJSON) in
                guard let `self` = self else { return }
                guard status / 100 == 2 else {
                    if indexPath == Key.shared.selectedTypeIdx_explore {
                        self.buttonEnable(on: true)
                    }
                    return
                }
                guard let mapPlaceJsonArray = placesJSON.array else {
                    //.fail
                    if indexPath == Key.shared.selectedTypeIdx_explore {
                        self.buttonEnable(on: true)
                    }
                    return
                }
                guard mapPlaceJsonArray.count > 0 else {
                    //.fail
                    if indexPath == Key.shared.selectedTypeIdx_explore {
                        self.buttonEnable(on: true)
                    }
                    return
                }
                let arrRaw = mapPlaceJsonArray.map { PlacePin(json: $0) }
                self.arrRandom = self.getRandomIndex(arrRaw)
                if Key.shared.lastCategory_explore == "Random" {
                    if let lastBtn = self.dictTypeBtns["Random"] {
                        self.changeTypeButtonState(lastBtn, .selected)
                    }
                } else {
                    if let lastBtn = self.dictTypeBtns["Random"] {
                        self.changeTypeButtonState(lastBtn, .unread)
                    }
                }
                if indexPath == Key.shared.selectedTypeIdx_explore {
                    self.clctViewPlaceCard.reloadData()
                    self.hideWaves()
                    self.buttonEnable(on: true)
                }
                self.checkSavedStatus(idx: 0)
            })
        }
    }
    
    private func showWaves() {
        UIView.animate(withDuration: 0.3, animations: {
            if self.clctViewPlaceCard != nil {
                self.clctViewPlaceCard.alpha = 0
            }
            self.uiviewAvatarWaveSub.alpha = 1
        })
    }
    
    private func hideWaves() {
        UIView.animate(withDuration: 0.3, animations: {
            self.clctViewPlaceCard.alpha = 1
            self.uiviewAvatarWaveSub.alpha = 0
        })
    }
    
    private func cancelAllRequests() {
        for (_, request) in requests {
            request.cancel()
        }
    }
    
    private func search(category: String, indexPath: IndexPath) {
        
        if category == "Random" {
            loadPlaces(center: coordinate, indexPath: indexPath)
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            
            var locationToSearch = LocManager.shared.curtLoc.coordinate
            if let locToSearch = LocManager.shared.locToSearch_explore {
                locationToSearch = locToSearch
            }
            
            let searchAgent = FaeSearch()
            searchAgent.whereKey("content", value: category)
            searchAgent.whereKey("source", value: "master_class")
            searchAgent.whereKey("type", value: "place")
            searchAgent.whereKey("size", value: "20")
            searchAgent.whereKey("radius", value: "500000")
            searchAgent.whereKey("offset", value: "0")
            searchAgent.whereKey("sort", value: [["_score": "desc"], ["geo_location": "asc"]])
            searchAgent.whereKey("location", value: ["latitude": locationToSearch.latitude,
                                                     "longitude": locationToSearch.longitude])
            self.requests[category] = searchAgent.search { [weak self] (status: Int, message: Any?) in
                guard let `self` = self else { return }
                
                if status / 100 != 2 {
                    if category == Key.shared.lastCategory_explore {
                        self.buttonEnable(on: true)
                    }
                    return
                }
                guard message != nil else {
                    if category == Key.shared.lastCategory_explore {
                        self.buttonEnable(on: true)
                    }
                    return
                }
                let placeInfoJSON = JSON(message!)
                guard let placeInfoJsonArray = placeInfoJSON.array else {
                    if category == Key.shared.lastCategory_explore {
                        self.buttonEnable(on: true)
                    }
                    return
                }
                let arrRaw = placeInfoJsonArray.map { PlacePin(json: $0) }
                switch category {
                case "Random":
                    self.arrRandom = self.getRandomIndex(arrRaw)
                case "Food":
                    self.arrFood = self.getRandomIndex(arrRaw)
                case "Drinks":
                    self.arrDrinks = self.getRandomIndex(arrRaw)
                case "Shopping":
                    self.arrShopping = self.getRandomIndex(arrRaw)
                case "Outdoors":
                    self.arrOutdoors = self.getRandomIndex(arrRaw)
                case "Recreation":
                    self.arrRecreation = self.getRandomIndex(arrRaw)
                default:
                    break
                }
                if Key.shared.lastCategory_explore == category {
                    self.categoryState[category] = .selected
                    if let btn = self.dictTypeBtns[category] {
                        self.changeTypeButtonState(btn, .selected)
                    }
                } else {
                    self.categoryState[category] = .unread
                    if let btn = self.dictTypeBtns[category] {
                        self.changeTypeButtonState(btn, .unread)
                    }
                }
                if indexPath == Key.shared.selectedTypeIdx_explore {
                    self.clctViewPlaceCard.reloadData()
                    self.hideWaves()
                    self.buttonEnable(on: true)
                }
                self.checkSavedStatus(idx: 0)
            }
        }
    }
    
    private func changeTypeButtonState(_ btn: UIButton, _ state: CategoryState) {
        switch state {
        case .initial:
            btn.titleLabel?.font = FaeFont(fontType: .medium, size: 15)
            btn.setTitleColor(.lightGray, for: .normal)
        case .unread:
            btn.titleLabel?.font = FaeFont(fontType: .medium, size: 15)
            btn.setTitleColor(UIColor(r: 102, g: 192, b: 251, alpha: 100), for: .normal)
        case .read:
            btn.titleLabel?.font = FaeFont(fontType: .medium, size: 15)
            btn.setTitleColor(.lightGray, for: .normal)
        case .selected:
            btn.titleLabel?.font = FaeFont(fontType: .demiBold, size: 15)
            btn.setTitleColor(UIColor._2499090(), for: .normal)
        }
    }
    
    private func getRandomIndex(_ arrRaw: [PlacePin]) -> [PlacePin] {
        var tempRaw = arrRaw
        var arrResult = [PlacePin]()
        let count = arrRaw.count < 20 ? arrRaw.count : 20
        for _ in 0..<count {
            let random: Int = Int(arc4random_uniform(UInt32(tempRaw.count)))
            arrResult.append(tempRaw[random])
            tempRaw.remove(at: random)
        }
        return arrResult
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
    
    // MARK: - AddPlacetoCollectionDelegate
    func createColList() {
        let vc = CreateColListViewController()
        vc.enterMode = .place
        present(vc, animated: true)
    }
    
    // MARK: - SelectLocationDelegate
    func sendLocationBack(address: RouteAddress) {
        var arrNames = address.name.split(separator: ",")
        var array = [String]()
        guard arrNames.count >= 1 else { return }
        for i in 0..<arrNames.count {
            let name = String(arrNames[i]).trimmingCharacters(in: CharacterSet.whitespaces)
            array.append(name)
        }
        if array.count >= 3 {
            reloadBottomText(array[0], array[1] + ", " + array[2])
        } else if array.count == 1 {
            reloadBottomText(array[0], "")
        } else if array.count == 2 {
            reloadBottomText(array[0], array[1])
        }
        self.coordinate = address.coordinate
        self.showWaves()
        search(category: Key.shared.lastCategory_explore, indexPath: Key.shared.selectedTypeIdx_explore)
    }
    
}

extension ExploreViewController {
    
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
