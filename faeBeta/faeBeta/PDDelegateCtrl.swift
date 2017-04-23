//
//  PDHandleDelegateFuncs.swift
//  faeBeta
//
//  Created by Yue on 12/2/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON

extension PinDetailViewController: OpenedPinListViewControllerDelegate, PinCommentsCellDelegate, EditPinViewControllerDelegate, SendStickerDelegate, PinFeelingCellDelegate {
    
    // PinFeelingCellDelegate
    func postFeelingFromFeelingCell(_ feeling: Int) {
        let tmpBtn = UIButton()
        tmpBtn.tag = feeling
        self.postFeeling(tmpBtn)
    }
    // PinFeelingCellDelegate
    func deleteFeelingFromFeelingCell() {
        deleteFeeling()
    }
    
    // SendStickerDelegate
    func sendStickerWithImageName(_ name : String) {
        print("[sendStickerWithImageName] name: \(name)")
        let stickerMessage = "<faeSticker>\(name)</faeSticker>"
        sendMessage(stickerMessage)
        buttonSend.isEnabled = false
        buttonSend.setImage(UIImage(named: "cannotSendMessage"), for: UIControlState())
        UIView.animate(withDuration: 0.3) {
            self.tableCommentsForPin.frame.size.height = screenHeight - 155
            self.draggingButtonSubview.frame.origin.y = screenHeight - 90
        }
        
    }
    func appendEmojiWithImageName(_ name: String) {
        self.textViewInput.insertText("[\(name)]")
        let strLength: Int = self.textViewInput.text.characters.count
        self.textViewInput.scrollRangeToVisible(NSMakeRange(strLength-1, 0))
    }
    func deleteEmoji() {
        self.textViewInput.text = self.textViewInput.text.stringByDeletingLastEmoji()
        self.textViewDidChange(textViewInput)
    }
    
    func reloadPinContent(_ coordinate: CLLocationCoordinate2D, zoom: Float) {
        if self.pinIDPinDetailView != "-999" {
            getSeveralInfo()
        }
        PinDetailViewController.selectedMarkerPosition = coordinate
        zoomLevel = zoom
        self.delegate?.reloadMapPins(PinDetailViewController.selectedMarkerPosition, zoom: zoom, pinID: self.pinIDPinDetailView, marker: PinDetailViewController.pinMarker)
    }
    
    // OpenedPinListViewControllerDelegate
    func animateToCameraFromOpenedPinListView(_ coordinate: CLLocationCoordinate2D, index: Int) {
        buttonPrevPin.isHidden = false
        btnNextPin.isHidden = false
        pinIcon.isHidden = false
        grayBackButton.isHidden = false
        
        self.backJustOnce = true
        self.uiviewPlaceDetail.frame.origin.y = 0
        self.subviewNavigation.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 65)
        self.tableCommentsForPin.center.y += screenHeight
        self.draggingButtonSubview.center.y += screenHeight
        
        PinDetailViewController.selectedMarkerPosition = coordinate
        PinDetailViewController.placeType = OpenedPlaces.openedPlaces[index].category
        PinDetailViewController.strPlaceTitle = OpenedPlaces.openedPlaces[index].title
        PinDetailViewController.strPlaceStreet = OpenedPlaces.openedPlaces[index].street
        PinDetailViewController.strPlaceCity = OpenedPlaces.openedPlaces[index].city
        PinDetailViewController.strPlaceImageURL = OpenedPlaces.openedPlaces[index].imageURL
        initPlaceBasicInfo()
        manageYelpData()
        
        self.delegate?.animateToCamera(coordinate, pinID: "ddd")
        UIApplication.shared.statusBarStyle = .lightContent
    }
    func directlyReturnToMap() {
        actionBackToMap(UIButton())
    }
    
    // OpenedPinListViewControllerDelegate
    func backFromOpenedPinList(pinType: String, pinID: String) {
        backJustOnce = true
        subviewNavigation.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 65)
    }
    
    func directReplyFromPinCell(_ username: String, index: IndexPath) {
        self.replyToUser = "<a>@\(username)</a> "
        self.lblTxtPlaceholder.text = "@\(username):"
        textViewInput.becomeFirstResponder()
        directReplyFromUser = true
        boolKeyboardShowed = true
        tableCommentsForPin.scrollToRow(at: index, at: .bottom, animated: true)
    }
    
    func showActionSheetFromPinCell(_ username: String, userid: Int, index: IndexPath) {
        textViewInput.resignFirstResponder()
        if !boolKeyboardShowed && !boolStickerShowed {
            showActionSheet(name: username, userid: userid, index: index)
        }
        boolKeyboardShowed = false
    }
    
    func showActionSheet(name: String, userid: Int, index: IndexPath) {
        self.replyToUser = "<a>@\(name)</a> "
        let menu = UIAlertController(title: nil, message: "Action", preferredStyle: .actionSheet)
        menu.view.tintColor = UIColor.faeAppRedColor()
        let writeReply = UIAlertAction(title: "Write a Reply", style: .default) { (alert: UIAlertAction) in
            self.lblTxtPlaceholder.text = "@\(name)"
            self.textViewInput.becomeFirstResponder()
            self.directReplyFromUser = true
            self.boolKeyboardShowed = true
            self.tableCommentsForPin.scrollToRow(at: index, at: .bottom, animated: true)
        }
        let report = UIAlertAction(title: "Report", style: .default) { (alert: UIAlertAction) in
            self.actionReportThisPin()
        }
        let delete = UIAlertAction(title: "Delete", style: .default) { (alert: UIAlertAction) in
            let deletePinComment = FaePinAction()
            let pinCommentID = self.pinComments[index.row].commentId
            deletePinComment.uncommentThisPin(pinCommentID: "\(pinCommentID)", completion: { (status, message) in
                if status / 100 == 2 {
                    print("[Delete Pin Comment] Success")
                }
            })
            self.pinComments.remove(at: index.row)
            self.tableCommentsForPin.reloadData()
            
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction) in
            self.replyToUser = ""
            self.lblTxtPlaceholder.text = "Write a Comment..."
        }
        menu.addAction(writeReply)
        if let currentUserID = user_id as? Int {
            if currentUserID == userid {
                menu.addAction(delete)
            } else {
                menu.addAction(report)
            }
        } else {
            menu.addAction(report)
        }
        menu.addAction(cancel)
        self.present(menu, animated: true, completion: nil)
    }
}

