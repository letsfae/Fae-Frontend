//
//  FMMapNameCard.swift
//  faeBeta
//
//  Created by Yue on 12/15/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftyJSON
import GoogleMaps

extension FaeMapViewController {
    
    func getSelfNameCard(_ sender: UIButton) {
        btnOptions.tag = Int(user_id)
        btnShowSelfOnMap.isHidden = false
        btnFavorite.isHidden = true
        if user_id != nil {
            let stringHeaderURL = "\(baseURL)/files/users/\(user_id.stringValue)/avatar"
            imageAvatarNameCard.sd_setImage(with: URL(string: stringHeaderURL), placeholderImage: Key.sharedInstance.imageDefaultMale, options: .refreshCached)
            btnChat.tag = Int(user_id)
        }
        else {
            return
        }
        let zoomLv = faeMapView.camera.zoom
        let offset: Double = 0.0012 * pow(2, Double(17 - zoomLv))
        let camera = GMSCameraPosition.camera(withLatitude: currentLatitude+offset,
                                              longitude: currentLongitude, zoom: zoomLv)
        faeMapView.animate (to: camera)
        animateNameCard()
        let userNameCard = FaeUser()
        userNameCard.getSelfNamecard(){(status:Int, message: Any?) in
            if status / 100 == 2 {
                print("[updateNameCard] \(message!)")
                let profileInfo = JSON(message!)
                let canShowGender = profileInfo["show_gender"].boolValue
                let gender = profileInfo["gender"].stringValue
                let canShowAge = profileInfo["show_age"].boolValue
                let age = profileInfo["age"].stringValue
                self.showGenderAge(showGender: canShowGender, gender: gender, showAge: canShowAge, age: age)
                self.labelDisplayName.text = profileInfo["nick_name"].stringValue
                self.labelShortIntro.text = profileInfo["short_intro"].stringValue
            }
        }
    }
    
    func animateNameCard() {
        let targetFrame = CGRect(x: 73, y: 158, width: 268, height: 293)
        UIView.animate(withDuration: 0.8, delay: 0.3, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .curveLinear, animations: {
            self.btnTransparentClose.alpha = 1
            self.imageBackground.frame = targetFrame
            self.imageCover.frame = CGRect(x: 73, y: 158, width: 268, height: 125)
            self.avatarBaseView.frame = CGRect(x: 170, y: 240, width: 74, height: 74)
            self.imageAvatarNameCard.frame = CGRect(x: 170, y: 240, width: 74, height: 74)
            self.btnChat.frame = CGRect(x: 193.5, y: 393, width: 27, height: 27)
            self.labelDisplayName.frame = CGRect(x: 114, y: 323, width: 186, height: 25)
            self.labelDisplayName.alpha = 1
            self.labelShortIntro.frame = CGRect(x: 122, y: 349, width: 171, height: 18)
            self.imageOneLine.frame = CGRect(x: 73, y: 380.5, width: 268, height: 1)
            self.btnFavorite.frame = CGRect(x: 116, y: 393, width: 27, height: 27)
            self.btnShowSelfOnMap.frame = CGRect(x: 116, y: 393, width: 27, height: 27)
            self.btnOptions.frame = CGRect(x: 294, y: 292, width: 32, height: 18)
            self.btnEmoji.frame = CGRect(x: 271, y: 393, width: 27, height: 27)
            self.uiViewNameCard.frame = CGRect(x: 73, y: 158, width: 268, height: 275)
            self.uiviewUserGender.frame = CGRect(x: 88, y: 292, width: 46, height: 18)
            self.imageUserGender.frame = CGRect(x: 97, y: 295, width: 10, height: 12)
            self.lblUserAge.frame = CGRect(x: 113, y: 293, width: 16, height: 14)
            self.lblUserAge.alpha = 1
        }, completion: nil)
    }
    
    func hideNameCard(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, animations: ({
            if sender == self.btnTransparentClose {
                self.btnTransparentClose.alpha = 0
                self.imageBackground.frame = CGRect(x: screenWidth/2, y: 451, width: 0, height: 0)
                self.imageCover.frame = self.startFrame
                self.avatarBaseView.frame = self.startFrame
                self.imageAvatarNameCard.frame = self.startFrame
                self.btnChat.frame = self.startFrame
                self.labelDisplayName.frame = CGRect(x: 114, y: 451, width: 0, height: 0)
                self.labelShortIntro.frame = self.startFrame
                self.imageOneLine.frame = self.startFrame
                self.btnFavorite.frame = self.startFrame
                self.btnShowSelfOnMap.frame = self.startFrame
                self.btnOptions.frame = self.startFrame
                self.btnEmoji.frame = self.startFrame
                self.uiviewUserGender.frame = self.startFrame
                self.uiViewNameCard.frame = self.startFrame
                self.imageUserGender.frame = self.startFrame
                self.lblUserAge.frame = self.startFrame
            }
            if sender.tag == 1 || sender == self.btnCloseNameCardOptions {
                self.btnOptions.setImage(#imageLiteral(resourceName: "moreOptionMapNameCardFade"), for: .normal)
                sender.tag = 0
                let subviewXBefore: CGFloat = 243 * screenWidthFactor
                let subviewYBefore: CGFloat = 151 * screenWidthFactor
                let buttonY: CGFloat = 191 * screenWidthFactor
                self.nameCardMoreOptions.frame = CGRect(x: subviewXBefore, y: subviewYBefore, width: 0, height: 0)
                self.shareNameCard.frame = CGRect(x: subviewXBefore, y: buttonY, width: 0, height: 0)
                self.editNameCard.frame = CGRect(x: subviewXBefore, y: buttonY, width: 0, height: 0)
                self.reportNameCard.frame = CGRect(x: subviewXBefore, y: buttonY, width: 0, height: 0)
                self.shareNameCard.alpha = 0
                self.editNameCard.alpha = 0
                self.reportNameCard.alpha = 0
                self.btnCloseNameCardOptions.alpha = 0
            }
        }), completion: {(done: Bool) in
            if sender == self.btnTransparentClose {
                self.canDoNextUserUpdate = true
                self.uiviewUserGender.isHidden = true
                self.imageUserGender.image = nil
                self.lblUserAge.text = nil
                self.lblUserAge.alpha = 0
                self.labelDisplayName.alpha = 0
                
                guard let userData = self.selectedUserMarker.userData as? [Int: AnyObject] else {
                    return
                }
                guard let userPin = userData.values.first as? FaeUserPin else {
                    return
                }
                userPin.pause = false
            }
        })
    }
    
    func loadNameCard() {
        btnTransparentClose = UIButton(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        self.view.addSubview(btnTransparentClose)
        btnTransparentClose.layer.zPosition = 900
        btnTransparentClose.alpha = 0
        btnTransparentClose.addTarget(self, action: #selector(self.hideNameCard(_:)), for: .touchUpInside)
        
        uiViewNameCard = UIView(frame: startFrame)
        uiViewNameCard.backgroundColor = UIColor.white
        uiViewNameCard.layer.anchorPoint = nameCardAnchor
        uiViewNameCard.layer.shadowColor = UIColor.gray.cgColor
        uiViewNameCard.layer.shadowOffset = CGSize.zero
        uiViewNameCard.layer.shadowOpacity = 1
        uiViewNameCard.layer.shadowRadius = 25
        uiViewNameCard.layer.zPosition = 901
        uiViewNameCard.layer.cornerRadius = 18.9
        self.view.addSubview(uiViewNameCard)
        
        imageBackground = UIImageView(frame: startFrame)
        imageBackground.layer.anchorPoint = nameCardAnchor
        imageBackground.image = UIImage(named: "NameCard")
        imageBackground.contentMode = .scaleAspectFit
        imageBackground.clipsToBounds = true
        imageBackground.layer.zPosition = 902
        self.view.addSubview(imageBackground)
        
        imageCover = UIImageView(frame: startFrame)
        imageCover.image = UIImage(named: "Cover")
        imageCover.layer.anchorPoint = nameCardAnchor
        imageCover.layer.zPosition = 903
        self.view.addSubview(imageCover)
        
        avatarBaseView = UIView(frame: startFrame)
        avatarBaseView.layer.anchorPoint = nameCardAnchor
        avatarBaseView.backgroundColor = UIColor.white
        avatarBaseView.layer.cornerRadius = 37
        avatarBaseView.layer.borderColor = UIColor.white.cgColor
        avatarBaseView.layer.borderWidth = 6
        avatarBaseView.layer.shadowColor = UIColor.gray.cgColor
        avatarBaseView.layer.shadowOffset = CGSize.zero
        avatarBaseView.layer.shadowOpacity = 0.5
        avatarBaseView.layer.shadowRadius = 6
        avatarBaseView.layer.zPosition = 904
        
        self.view.addSubview(avatarBaseView)
        
        imageAvatarNameCard = UIImageView(frame: startFrame)
        imageAvatarNameCard.layer.anchorPoint = nameCardAnchor
        imageAvatarNameCard.layer.cornerRadius = 37
        imageAvatarNameCard.layer.borderColor = UIColor.white.cgColor
        imageAvatarNameCard.layer.borderWidth = 6
        imageAvatarNameCard.image = #imageLiteral(resourceName: "defaultMen")
        imageAvatarNameCard.contentMode = .scaleAspectFill
        imageAvatarNameCard.layer.masksToBounds = true
        imageAvatarNameCard.layer.zPosition = 905
        self.view.addSubview(imageAvatarNameCard)
        
        btnChat = UIButton(frame: startFrame)
        btnChat.layer.anchorPoint = nameCardAnchor
        btnChat.setImage(#imageLiteral(resourceName: "chatFromMap"), for: .normal)
        btnChat.layer.zPosition = 906
        self.view.addSubview(btnChat)
        btnChat.addTarget(self, action: #selector(self.btnChatAction(_:)), for: .touchUpInside)
        
        labelDisplayName = UILabel(frame: CGRect(x: 114, y: 451, width: 0, height: 0))
        labelDisplayName.layer.anchorPoint = nameCardAnchor
        labelDisplayName.text = nil
        labelDisplayName.textAlignment = .center
        labelDisplayName.font = UIFont(name: "AvenirNext-DemiBold", size: 18)
        labelDisplayName.textColor = UIColor(red: 107/255, green: 105/255, blue: 105/255, alpha: 1.0)
        labelDisplayName.layer.zPosition = 907
        labelDisplayName.alpha = 0
        self.view.addSubview(labelDisplayName)
        
        labelShortIntro = UILabel(frame: startFrame)
        labelShortIntro.layer.anchorPoint = nameCardAnchor
        labelShortIntro.text = ""
        labelShortIntro.textAlignment = .center
        labelShortIntro.font = UIFont(name: "AvenirNext-Medium", size: 13)
        labelShortIntro.textColor = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1.0)
        labelShortIntro.layer.zPosition = 908
        self.view.addSubview(labelShortIntro)
        
        imageOneLine = UIImageView(frame: startFrame)
        imageOneLine.layer.anchorPoint = nameCardAnchor
        imageOneLine.backgroundColor = UIColor(red: 206/255, green: 203/255, blue: 203/255, alpha: 1.0)
        imageOneLine.layer.zPosition = 909
        self.view.addSubview(imageOneLine)
        
        btnFavorite = UIButton(frame: startFrame)
        btnFavorite.layer.anchorPoint = nameCardAnchor
        btnFavorite.setImage(UIImage(named: "Favorite"), for: .normal)
        btnFavorite.layer.zPosition = 910
        self.view.addSubview(btnFavorite)
        
        btnShowSelfOnMap = UIButton(frame: startFrame)
        btnShowSelfOnMap.layer.anchorPoint = nameCardAnchor
        btnShowSelfOnMap.layer.zPosition = 910
        btnShowSelfOnMap.setImage(#imageLiteral(resourceName: "showSelfWaveToOthers"), for: .normal)
        self.view.addSubview(btnShowSelfOnMap)
        btnShowSelfOnMap.isHidden = true
        
        btnOptions = UIButton(frame: startFrame)
        btnOptions.layer.anchorPoint = nameCardAnchor
        btnOptions.setImage(#imageLiteral(resourceName: "moreOptionMapNameCardFade"), for: .normal)
        btnOptions.layer.zPosition = 910
        self.view.addSubview(btnOptions)
        btnOptions.addTarget(self, action: #selector(self.showNameCardOptions(_:)), for: .touchUpInside)
        
        btnEmoji = UIButton(frame: startFrame)
        btnEmoji.layer.anchorPoint = nameCardAnchor
        btnEmoji.setImage(UIImage(named: "Emoji"), for: .normal)
        btnEmoji.layer.zPosition = 910
        self.view.addSubview(btnEmoji)
        
        loadGenderAge()
        
        btnCloseNameCardOptions = UIButton(frame: CGRect(x: 73, y: 158, width: 268, height: 293))
        btnCloseNameCardOptions.layer.zPosition = 920
        self.view.addSubview(btnCloseNameCardOptions)
        btnCloseNameCardOptions.alpha = 0
        btnCloseNameCardOptions.addTarget(self, action: #selector(self.hideNameCard(_:)), for: .touchUpInside)
    }
    
    func loadGenderAge() {
        uiviewUserGender = UIView(frame: startFrame)
        uiviewUserGender.layer.anchorPoint = nameCardAnchor
        uiviewUserGender.backgroundColor = UIColor(red: 149/255, green: 207/255, blue: 246/255, alpha: 1)
        uiviewUserGender.layer.cornerRadius = 9*screenHeightFactor
        uiviewUserGender.layer.zPosition = 912
        self.view.addSubview(uiviewUserGender)
        imageUserGender = UIImageView(frame: startFrame)
        imageUserGender.contentMode = .scaleAspectFit
        imageUserGender.layer.anchorPoint = nameCardAnchor
        self.view.addSubview(imageUserGender)
        imageUserGender.layer.zPosition = 913
        lblUserAge = UILabel(frame: startFrame)
        lblUserAge.layer.anchorPoint = nameCardAnchor
        lblUserAge.textColor = UIColor.white
        lblUserAge.font = UIFont(name: "AvenirNext-Demibold", size: 13)
        lblUserAge.layer.zPosition = 913
        lblUserAge.alpha = 0
        self.view.addSubview(lblUserAge)
//        lblUserAge.text = "21"
    }
    
    func updateNameCard(withUserId: Int) {
        btnChat.tag = withUserId
        btnOptions.tag = withUserId
        btnShowSelfOnMap.isHidden = true
        btnFavorite.isHidden = false
        let stringHeaderURL = "\(baseURL)/files/users/\(withUserId)/avatar"
        imageAvatarNameCard.sd_setImage(with: URL(string: stringHeaderURL), placeholderImage: Key.sharedInstance.imageDefaultMale, options: .refreshCached)
        let userNameCard = FaeUser()
        userNameCard.getNamecardOfSpecificUser("\(withUserId)"){(status:Int, message: Any?) in
            if status / 100 == 2 {
                print("[updateNameCard] \(message!)")
                let profileInfo = JSON(message!)
                let canShowGender = profileInfo["show_gender"].boolValue
                let gender = profileInfo["gender"].stringValue
                let canShowAge = profileInfo["show_age"].boolValue
                let age = profileInfo["age"].stringValue
                self.showGenderAge(showGender: canShowGender, gender: gender, showAge: canShowAge, age: age)
                self.labelDisplayName.text = profileInfo["nick_name"].stringValue
                self.labelShortIntro.text = profileInfo["short_intro"].stringValue
            }
        }
    }
    
    fileprivate func showGenderAge(showGender: Bool, gender: String, showAge: Bool, age: String) {
        if !showGender && !showAge {
            uiviewUserGender.isHidden = true
            imageUserGender.image = nil
        } else if showGender && showAge {
            uiviewUserGender.isHidden = false
            if gender == "male" {
                imageUserGender.image = #imageLiteral(resourceName: "userGenderMale")
                uiviewUserGender.backgroundColor = UIColor.maleBackgroundColor()
            } else if gender == "female" {
                imageUserGender.image = #imageLiteral(resourceName: "userGenderFemale")
                uiviewUserGender.backgroundColor = UIColor.femaleBackgroundColor()
            } else {
                imageUserGender.image = nil
            }
            lblUserAge.text = age
            lblUserAge.frame.size = lblUserAge.intrinsicContentSize
            uiviewUserGender.frame.size.width = 32 + lblUserAge.intrinsicContentSize.width
        } else if showAge && !showGender {
            uiviewUserGender.isHidden = false
            lblUserAge.text = age
            lblUserAge.frame.size = lblUserAge.intrinsicContentSize
            uiviewUserGender.frame.size.width = 17 + lblUserAge.intrinsicContentSize.width
            lblUserAge.frame.origin.x = 97
            imageUserGender.image = nil
            uiviewUserGender.backgroundColor = UIColor.faeAppShadowGrayColor()
        } else if showGender && !showAge {
            uiviewUserGender.isHidden = false
            if gender == "male" {
                imageUserGender.image = #imageLiteral(resourceName: "userGenderMale")
                uiviewUserGender.backgroundColor = UIColor.maleBackgroundColor()
            } else if gender == "female" {
                imageUserGender.image = #imageLiteral(resourceName: "userGenderFemale")
                uiviewUserGender.backgroundColor = UIColor.femaleBackgroundColor()
            } else {
                imageUserGender.image = nil
            }
            uiviewUserGender.frame.size.width = 28
            lblUserAge.text = nil
        }
    }
    
    func btnChatAction(_ sender: UIButton) {
        hideNameCard(btnTransparentClose)
        let withUserId: NSNumber = NSNumber(value: sender.tag)
        //First get chatroom id
        getFromURL("chats/users/\(user_id.stringValue)/\(withUserId.stringValue)", parameter: nil, authentication: headerAuthentication()) { (status, result) in
            var resultJson1 = JSON([])
            if(status / 100 == 2){
                resultJson1 = JSON(result!)
            }
            // then get with user name
            getFromURL("users/\(withUserId.stringValue)/name_card", parameter: nil, authentication: headerAuthentication()) { (status, result) in
                if status / 100 == 2 {
                    let resultJson2 = JSON(result!)
                    var chat_id: String?
                    if let id = resultJson1["chat_id"].number {
                        chat_id = id.stringValue
                    }
                    if let withNickName = resultJson2["nick_name"].string {
                        self.startChat(chat_id ,withUserId: withUserId, withNickName: withNickName)
                    } else {
                        self.startChat(chat_id, withUserId: withUserId, withNickName: nil)
                    }
                }
            }
        }
    }
    
    func startChat(_ chat_id: String? ,withUserId: NSNumber, withNickName: String?){
        let chatVC = UIStoryboard(name: "Chat", bundle: nil) .instantiateViewController(withIdentifier: "ChatViewController")as! ChatViewController
        chatVC.chatRoomId = user_id.compare(withUserId).rawValue < 0 ? "\(user_id.stringValue)-\(withUserId.stringValue)" : "\(withUserId.stringValue)-\(user_id.stringValue)"
        chatVC.chat_id = chat_id
        let nickName = withNickName ?? "Chat"
        chatVC.withUser = FaeWithUser(userName: nickName, userId: withUserId.stringValue, userAvatar: nil)
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func showNameCardOptions(_ sender: UIButton) {
        btnCloseNameCardOptions.alpha = 1
        btnTransparentClose.tag = 1
        var thisIsMe = false
        if sender.tag == Int(user_id) {
            print("[showNameCardOptions] this is me")
            thisIsMe = true
        }
        let subviewXBefore: CGFloat = 243 / 414 * screenWidth
        let subviewYBefore: CGFloat = 151 / 414 * screenWidth
        let subviewXAfter: CGFloat = 79 / 414 * screenWidth
        let subviewYAfter: CGFloat = subviewYBefore
        let subviewWidthAfter: CGFloat = 164 / 414 * screenWidth
        let subviewHeightAfter: CGFloat = 110 / 414 * screenWidth
        let firstButtonX: CGFloat = 103 / 414 * screenWidth
        let secondButtonX: CGFloat = 172 / 414 * screenWidth
        let buttonY: CGFloat = 191 / 414 * screenWidth
        let buttonWidth: CGFloat = 50 / 414 * screenWidth
        let buttonHeight: CGFloat = 51 / 414 * screenWidth
        
        btnOptions.setImage(#imageLiteral(resourceName: "moreOptionMapNameCardReal"), for: .normal)
        
        nameCardMoreOptions = UIImageView(frame: CGRect(x: subviewXBefore, y: subviewYBefore, width: 0, height: 0))
        nameCardMoreOptions.image = #imageLiteral(resourceName: "nameCardOptions")
        self.btnCloseNameCardOptions.addSubview(nameCardMoreOptions)
        
        shareNameCard = UIButton(frame: CGRect(x: subviewXBefore, y: subviewYBefore, width: 0, height: 0))
        shareNameCard.setImage(#imageLiteral(resourceName: "pinDetailShare"), for: .normal)
        self.btnCloseNameCardOptions.addSubview(shareNameCard)
        shareNameCard.clipsToBounds = true
        shareNameCard.alpha = 0.0
//        shareNameCard.addTarget(self, action: #selector(CommentPinDetailViewController.actionShareComment(_:)), for: .TouchUpInside)
        
        editNameCard = UIButton(frame: CGRect(x: subviewXBefore, y: subviewYBefore, width: 0, height: 0))
        editNameCard.setImage(#imageLiteral(resourceName: "pinDetailEdit"), for: .normal)
        self.btnCloseNameCardOptions.addSubview(editNameCard)
        editNameCard.clipsToBounds = true
        editNameCard.alpha = 0.0
//        editNameCard.addTarget(self, action: #selector(CommentPinDetailViewController.actionEditComment(_:)), for: .touchUpInside)
        
        reportNameCard = UIButton(frame: CGRect(x: subviewXBefore, y: subviewYBefore, width: 0, height: 0))
        reportNameCard.setImage(#imageLiteral(resourceName: "pinDetailReport"), for: .normal)
        self.btnCloseNameCardOptions.addSubview(reportNameCard)
        reportNameCard.clipsToBounds = true
        reportNameCard.alpha = 0.0
        reportNameCard.addTarget(self, action: #selector(self.actionReportThisPin(_:)), for: .touchUpInside)
        
        UIView.animate(withDuration: 0.3, animations: ({
            self.nameCardMoreOptions.frame = CGRect(x: subviewXAfter, y: subviewYAfter, width: subviewWidthAfter, height: subviewHeightAfter)
            self.shareNameCard.frame = CGRect(x: firstButtonX, y: buttonY, width: buttonWidth, height: buttonHeight)
            self.shareNameCard.alpha = 1.0
            if thisIsMe {
                self.editNameCard.alpha = 1.0
                self.editNameCard.frame = CGRect(x: secondButtonX, y: buttonY, width: buttonWidth, height: buttonHeight)
            }
            else {
                self.reportNameCard.alpha = 1.0
                self.reportNameCard.frame = CGRect(x: secondButtonX, y: buttonY, width: buttonWidth, height: buttonHeight)
            }
        }))
    }
}
