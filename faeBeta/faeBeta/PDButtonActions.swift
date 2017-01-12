//
//  MPDButtonActions.swift
//  faeBeta
//
//  Created by Yue on 12/2/16.
//  Copyright © 2016 fae. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import SwiftyJSON

extension PinDetailViewController {
    
    // Pan gesture for dragging pin detail dragging button
    func panActionPinDetailDrag(_ pan: UIPanGestureRecognizer) {
        var resumeTime:Double = 0.583
        if pan.state == .began {
            if uiviewPinDetail.frame.size.height == 255 {
                pinSizeFrom = 255
                pinSizeTo = screenHeight - 65
            }
            else {
                pinSizeFrom = screenHeight - 65
                pinSizeTo = 255
            }
        } else if pan.state == .ended || pan.state == .failed || pan.state == .cancelled {
            let location = pan.location(in: view)
            let velocity = pan.velocity(in: view)
            resumeTime = abs(Double(CGFloat(screenHeight - 256) / velocity.y))
            print("DEBUG: Velocity TESTing")
            print("Velocity in CGPoint.y")
            print(velocity.y)
            print("Resume Time")
            print(resumeTime)
            if resumeTime >= 0.583 {
                resumeTime = 0.583
            }
            if abs(location.y - pinSizeFrom) >= 80 {
                UIView.animate(withDuration: resumeTime, animations: {
                    self.draggingButtonSubview.frame.origin.y = self.pinSizeTo - 28
                    self.uiviewPinDetail.frame.size.height = self.pinSizeTo
                })
            }
            else {
                UIView.animate(withDuration: resumeTime, animations: {
                    self.draggingButtonSubview.frame.origin.y = self.pinSizeFrom - 28
                    self.uiviewPinDetail.frame.size.height = self.pinSizeFrom
                })
            }
            if uiviewPinDetail.frame.size.height == 255 {
                textviewPinDetail.isScrollEnabled = true
                buttonPinDetailDragToLargeSize.tag = 0
            }
            if uiviewPinDetail.frame.size.height == screenHeight - 65 {
                textviewPinDetail.isScrollEnabled = false
                buttonPinDetailDragToLargeSize.tag = 1
                let newHeight = CGFloat(140 * self.dictCommentsOnPinDetail.count)
                self.tableCommentsForPin.frame.size.height = newHeight
            }
            
        } else {
            let location = pan.location(in: view)
            if location.y >= 306 {
                self.draggingButtonSubview.center.y = location.y - 65
                self.uiviewPinDetail.frame.size.height = location.y + 14 - 65
            }
        }
    }
    
    // Back to pin list window when in detail window
    func actionGoToList(_ sender: UIButton!) {
        endEdit()
        if backJustOnce == true {
            backJustOnce = false
            let openedPinListVC = OpenedPinListViewController()
            openedPinListVC.delegate = self
            openedPinListVC.modalPresentationStyle = .overCurrentContext
            self.present(openedPinListVC, animated: false, completion: {
                self.subviewNavigation.center.y -= self.subviewNavigation.frame.size.height
                self.tableCommentsForPin.center.y -= screenHeight
                self.draggingButtonSubview.center.y -= screenHeight
            })
        }
    }
    
    func actionBackToMap(_ sender: UIButton) {
        endEdit()
        if inputToolbar != nil {
            self.inputToolbar.isHidden = true
            self.subviewInputToolBar.isHidden = true
        }
        controlBoard.removeFromSuperview()
        self.delegate?.dismissMarkerShadow(true)
        UIView.animate(withDuration: 0.583, animations: ({
            self.subviewNavigation.center.y -= screenHeight
            self.tableCommentsForPin.center.y -= screenHeight
            self.subviewTable.center.y -= screenHeight
            self.draggingButtonSubview.center.y -= screenHeight
            self.grayBackButton.alpha = 0
            self.pinIcon.alpha = 0
            self.buttonPrevPin.alpha = 0
            self.buttonNextPin.alpha = 0
        }), completion: { (done: Bool) in
            if done {
                self.dismiss(animated: false, completion: nil)
            }
        })
    }
    
    // When clicking reply button in pin detail window
    func actionReplyToThisPin(_ sender: UIButton) {
        if sender.tag == 1 {
            endEdit()
            sender.tag = 0
            tableCommentsForPin.isScrollEnabled = false
            mediaMode = .small
            zoomMedia(.small)
            buttonPinDetailDragToLargeSize.tag = 0
            if inputToolbar != nil {
                self.inputToolbar.isHidden = true
                self.subviewInputToolBar.isHidden = true
            }
            tableCommentsForPin.isScrollEnabled = false
            UIView.animate(withDuration: 0.583, animations: ({
                self.buttonBackToPinLists.alpha = 1.0
                self.buttonPinBackToMap.alpha = 0.0
                self.draggingButtonSubview.frame.origin.y = 292
                self.tableCommentsForPin.scrollToTop()
                self.tableCommentsForPin.frame.size.height = 227
                self.uiviewPinDetail.frame.size.height = 281
                self.textviewPinDetail.frame.size.height = 0
                self.uiviewPinDetailMainButtons.frame.origin.y = 190
                self.uiviewPinDetailGrayBlock.frame.origin.y = 227
                self.uiviewPinDetailThreeButtons.frame.origin.y = 239
                self.scrollViewMedia.frame.origin.y = 80
            }), completion: { (done: Bool) in
                if done {
                    self.textviewPinDetail.isHidden = true
                }
            })
            return
        }
        sender.tag = 1
        if buttonPinDetailDragToLargeSize.tag == 1 {
            if inputToolbar != nil {
                self.inputToolbar.isHidden = false
                self.subviewInputToolBar.isHidden = false
            }
            self.tableCommentsForPin.frame.size.height = screenHeight - 65 - 90
            self.draggingButtonSubview.frame.origin.y = screenHeight - 28
            return
        }
        if inputToolbar != nil {
            self.inputToolbar.isHidden = false
            self.subviewInputToolBar.isHidden = false
        }
        let textViewHeight: CGFloat = textviewPinDetail.contentSize.height
        tableCommentsForPin.isScrollEnabled = true
        mediaMode = .large
        zoomMedia(.large)
        textviewPinDetail.frame.size.height = 0
        textviewPinDetail.isHidden = false
        UIView.animate(withDuration: 0.583, animations: ({
            self.buttonBackToPinLists.alpha = 0.0
            self.buttonPinBackToMap.alpha = 1.0
            self.draggingButtonSubview.frame.origin.y = screenHeight - 90
            self.tableCommentsForPin.frame.size.height = screenHeight - 65 - 90
            self.uiviewPinDetail.frame.size.height += 65
            self.textviewPinDetail.frame.size.height += 65
            self.uiviewPinDetailThreeButtons.center.y += 65
            self.uiviewPinDetailGrayBlock.center.y += 65
            self.uiviewPinDetailMainButtons.center.y += 65
            if self.textviewPinDetail.text != "" {
                self.uiviewPinDetail.frame.size.height += textViewHeight
                self.textviewPinDetail.frame.size.height += textViewHeight
                self.uiviewPinDetailThreeButtons.center.y += textViewHeight
                self.uiviewPinDetailGrayBlock.center.y += textViewHeight
                self.uiviewPinDetailMainButtons.center.y += textViewHeight
                self.scrollViewMedia.frame.origin.y += textViewHeight
            }
        }), completion: { (done: Bool) in
            if done {
                self.tableCommentsForPin.reloadData()
            }
        })
    }
    
    // When clicking dragging button in pin detail window
    func actionDraggingThisPin(_ sender: UIButton) {
        if sender.tag == 1 {
            sender.tag = 0
            buttonPinAddComment.tag = 0
            tableCommentsForPin.isScrollEnabled = false
            mediaMode = .small
            zoomMedia(.small)
            UIView.animate(withDuration: 0.583, animations: ({
                self.buttonBackToPinLists.alpha = 1.0
                self.buttonPinBackToMap.alpha = 0.0
                self.draggingButtonSubview.frame.origin.y = 292
                self.tableCommentsForPin.scrollToTop()
                self.tableCommentsForPin.frame.size.height = 227
                self.uiviewPinDetail.frame.size.height = 281
                self.textviewPinDetail.frame.size.height = 0
                self.uiviewPinDetailMainButtons.frame.origin.y = 190
                self.uiviewPinDetailGrayBlock.frame.origin.y = 227
                self.uiviewPinDetailThreeButtons.frame.origin.y = 239
                self.scrollViewMedia.frame.origin.y = 80
            }), completion: { (done: Bool) in
                if done {
                    
                }
            })
            return
        }
        sender.tag = 1
        let textViewHeight: CGFloat = textviewPinDetail.contentSize.height
        tableCommentsForPin.isScrollEnabled = true
        mediaMode = .large
        zoomMedia(.large)
        textviewPinDetail.frame.size.height = 0
        textviewPinDetail.isHidden = false
        UIView.animate(withDuration: 0.583, animations: ({
            self.buttonBackToPinLists.alpha = 0.0
            self.buttonPinBackToMap.alpha = 1.0
            self.draggingButtonSubview.frame.origin.y = screenHeight - 28
            self.tableCommentsForPin.frame.size.height = screenHeight - 93
            self.uiviewPinDetail.frame.size.height += 65
            self.textviewPinDetail.frame.size.height += 65
            self.uiviewPinDetailThreeButtons.center.y += 65
            self.uiviewPinDetailGrayBlock.center.y += 65
            self.uiviewPinDetailMainButtons.center.y += 65
            if self.textviewPinDetail.text != "" {
                self.uiviewPinDetail.frame.size.height += textViewHeight
                self.textviewPinDetail.frame.size.height += textViewHeight
                self.uiviewPinDetailThreeButtons.center.y += textViewHeight
                self.uiviewPinDetailGrayBlock.center.y += textViewHeight
                self.uiviewPinDetailMainButtons.center.y += textViewHeight
                self.scrollViewMedia.frame.origin.y += textViewHeight
            }
        }), completion: { (done: Bool) in
            if done {
                self.tableCommentsForPin.reloadData()
            }
        })
    }
    
    func actionShowActionSheet(_ username: String) {
        let menu = UIAlertController(title: nil, message: "Action", preferredStyle: .actionSheet)
        menu.view.tintColor = UIColor.faeAppRedColor()
        let writeReply = UIAlertAction(title: "Write a Reply", style: .default) { (alert: UIAlertAction) in
            self.loadInputToolBar()
            self.inputToolbar.isHidden = false
            self.inputToolbar.contentView.textView.text = "@\(username) "
            self.inputToolbar.contentView.textView.becomeFirstResponder()
            self.lableTextViewPlaceholder.isHidden = true
        }
        let report = UIAlertAction(title: "Report", style: .default) { (alert: UIAlertAction) in
            self.actionReportThisPin(self.buttonReportOnPinDetail)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction) in
            
        }
        menu.addAction(writeReply)
        menu.addAction(report)
        menu.addAction(cancel)
        self.present(menu, animated: true, completion: nil)
    }
    
    func tapOutsideToDismissKeyboard(_ sender: UITapGestureRecognizer) {
        endEdit()
    }
}