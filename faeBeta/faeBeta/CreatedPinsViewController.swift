//
//  CreatedPinsViewController.swift
//  faeBeta
//
//  Created by Shiqi Wei on 4/17/17.
//  Edited by Sophie Wang
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import SwiftyJSON
import UIKit.UIGestureRecognizerSubclass

class CreatedPinsViewController: PinsViewController, UITableViewDataSource, PinDetailCollectionsDelegate {
    
    override func viewDidLoad() {
        strTableTitle = "Created Pins"
        super.viewDidLoad()
    }
    
    override func loadTblPinsData() {
        super.loadTblPinsData()
        tblPinsData.register(CreatedPinsTableViewCell.self, forCellReuseIdentifier: "createdPinCell")
        tblPinsData.delegate = self
        tblPinsData.dataSource = self
        getPinsData()
        lblEmptyTbl.text = "You haven’t created any Pins, come again after you create some pins. :)"
    }
    
    func reloadPinContent(_ coordinate: CLLocationCoordinate2D) {
        getPinsData()
    }
    
    // get the Created Pins
    func getPinsData() {
        let getCreatedPinsData = FaeMap()
        getCreatedPinsData.getCreatedPins() {(status: Int, message: Any?) in
            if status / 100 == 2 {
                print("Successfully get created pins!")
                self.arrMapPin.removeAll()
                let createdPinsJSON = JSON(message!)
                guard let arrCreatedPins = createdPinsJSON.array else {
                    print("[savedPinsJSON] fail to parse saved pin!")
                    return
                }
                self.arrMapPin = arrCreatedPins.map{MapPinCollections(json: $0)}
                self.tblPinsData.isHidden = !(self.arrMapPin.count > 0)
                self.tblPinsData.reloadData()
            }
            else {
                print("Fail to get created pins!")
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return arrMapPin.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
        if !gesturerecognizerTouch.isCellSwiped {
            tableView.deselectRow(at: indexPath, animated: false)
            let vcPinDetail = PinDetailViewController()
            vcPinDetail.modalPresentationStyle = .overCurrentContext
            vcPinDetail.colDelegate = self
            vcPinDetail.enterMode = .collections
            vcPinDetail.strPinId = "\(arrMapPin[indexPath.section].pinId)"
            vcPinDetail.strTextViewText = arrMapPin[indexPath.section].content
            PinDetailViewController.selectedMarkerPosition = arrMapPin[indexPath.section].position
            PinDetailViewController.pinTypeEnum = PinDetailViewController.PinType(rawValue: arrMapPin[indexPath.section].type)!
            PinDetailViewController.pinUserId = arrMapPin[indexPath.section].userId
            self.indexCurrSelectRowAt = indexPath
            
            self.navigationController?.pushViewController(vcPinDetail, animated: true)
        }
         */
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "createdPinCell", for: indexPath) as! CreatedPinsTableViewCell
        cell.delegate = self
        cell.indexForCurrentCell = indexPath.section
        cell.setValueForCell(arrMapPin[indexPath.section])
        cell.setImageConstraint()
        cell.lblChatDesc.sizeToFit()
        return cell
    }
    
    // PinDetailCollectionsDelegate
    func backToCollections(likeCount: String, commentCount: String, pinLikeStatus: Bool, feelingArray: [Int]) {
        
        if likeCount == "" || commentCount == "" || self.indexCurrSelectRowAt == nil {
            return
        }
        
        let cellCurrSelect = tblPinsData.cellForRow(at: self.indexCurrSelectRowAt) as! CreatedPinsTableViewCell
        cellCurrSelect.lblCommentCount.text = commentCount
        cellCurrSelect.lblLikeCount.text = likeCount
        cellCurrSelect.imgLike.image = pinLikeStatus ? #imageLiteral(resourceName: "pinDetailLikeHeartFull") : #imageLiteral(resourceName: "pinDetailLikeHeartHollow")
    
        if Int(likeCount)! >= 15 || Int(commentCount)! >= 10 {
            cellCurrSelect.imgHot.isHidden = false
        } else {
            cellCurrSelect.imgHot.isHidden = true
        }
        arrMapPin[self.indexCurrSelectRowAt.section].likeCount = Int(likeCount)!
        arrMapPin[self.indexCurrSelectRowAt.section].commentCount = Int(commentCount)!
        arrMapPin[self.indexCurrSelectRowAt.section].isLiked = pinLikeStatus
    }
    
    // PinTableViewCellDelegate protocol required function
    override func itemSwiped(indexCell: Int) {
        let path : IndexPath = IndexPath(row: 0, section: indexCell)
        cellCurrSwiped = tblPinsData.cellForRow(at: path) as! CreatedPinsTableViewCell
        tblPinsData.addGestureRecognizer(gesturerecognizerTouch)
        gesturerecognizerTouch.cellInGivenId = cellCurrSwiped
        gesturerecognizerTouch.isCellSwiped = true
    }
    
    override func toDoItemRemoved(indexCell: Int, pinId: Int, pinType: String) {
        let deleteMyPin = FaeMap()
        deleteMyPin.deletePin(type: pinType, pinId: pinId.description) {(status: Int, message: Any?) in
            if status / 100 == 2 {
                print("Successfully delete the pin!")
            }
        }
        self.arrMapPin.remove(at: indexCell)
        let indexSet = NSMutableIndexSet()
        indexSet.add(indexCell)
        self.tblPinsData.performUpdate( {
            self.tblPinsData.deleteSections(indexSet as IndexSet, with: UITableViewRowAnimation.top)
        }, completion: {
            self.tblPinsData.reloadData()
        })
        if self.arrMapPin.count == 0 {
            self.tblPinsData.isHidden = true
        }
    }
    
    override func toDoItemEdit(indexCell: Int, pinId: Int, pinType: String) {
        /*
        if pinId == -999 {
            return
        }
        let vcEditPin = EditPinViewController()
        vcEditPin.delegate = self
        vcEditPin.previousCommentContent = arrMapPin[indexCell].content
        
        if pinType == "comment" {
            vcEditPin.editPinMode = .comment
        } else if pinType == "media" {
            vcEditPin.mediaIdArray = arrMapPin[indexCell].fileIds
            vcEditPin.editPinMode = .media
        }
        vcEditPin.pinID = "\(pinId)"
        vcEditPin.pinType = pinType
        vcEditPin.pinMediaImageArray = cellCurrSwiped.arrImages
        vcEditPin.pinGeoLocation = arrMapPin[indexCell].position
        
        self.present(vcEditPin, animated: true, completion: {
            self.tblPinsData.reloadData()
            })
        */
    }
    
    override func toDoItemShared(indexCell: Int, pinId: Int, pinType: String) {
        
    }
    
    override func toDoItemVisible(indexCell: Int, pinId: Int, pinType: String) {
        
    }
    
    override func toDoItemLocated(indexCell: Int, pinId: Int, pinType: String) {
        
    }
    
}
