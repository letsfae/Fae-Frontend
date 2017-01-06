//
//  CommentPinDetailLoadItems.swift
//  faeBeta
//
//  Created by Yue on 10/18/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import SwiftyJSON

extension CommentPinDetailViewController {
    // Load comment pin detail window
    func loadCommentPinDetailWindow() {
        
        loadNavigationBar()
        
        subviewTable = UIView(frame: CGRect(x: 0, y: 65, width: screenWidth, height: 255))
        subviewTable.backgroundColor = UIColor.white
        subviewTable.center.y -= screenHeight
        self.view.addSubview(subviewTable)
        subviewTable.layer.zPosition = 1
        subviewTable.layer.shadowColor = UIColor(red: 107/255, green: 105/255, blue: 105/255, alpha: 1.0).cgColor
        subviewTable.layer.shadowOffset = CGSize(width: 0.0, height: 10.0)
        subviewTable.layer.shadowOpacity = 0.3
        subviewTable.layer.shadowRadius = 10.0
        
        // Table comments for comment
        tableCommentsForComment = UITableView(frame: CGRect(x: 0, y: 65, width: screenWidth, height: 255))
        tableCommentsForComment.delegate = self
        tableCommentsForComment.dataSource = self
        tableCommentsForComment.allowsSelection = false
        tableCommentsForComment.delaysContentTouches = true
        tableCommentsForComment.register(PinCommentsCell.self, forCellReuseIdentifier: "commentPinCommentsCell")
        tableCommentsForComment.isScrollEnabled = false
        tableCommentsForComment.tableFooterView = UIView.init(frame: CGRect.zero)
        tableCommentsForComment.layer.zPosition = 109
        tableCommentsForComment.showsVerticalScrollIndicator = false

        self.view.addSubview(tableCommentsForComment)
        tableCommentsForComment.center.y -= screenHeight
        
        // Dragging button
        draggingButtonSubview = UIView(frame: CGRect(x: 0, y: 292, width: screenWidth, height: 27))
        draggingButtonSubview.backgroundColor = UIColor.white
        self.view.addSubview(draggingButtonSubview)
        draggingButtonSubview.layer.zPosition = 109
        draggingButtonSubview.center.y -= screenHeight
        
        uiviewCommentPinUnderLine02 = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 1))
        uiviewCommentPinUnderLine02.backgroundColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1.0)
        self.draggingButtonSubview.addSubview(uiviewCommentPinUnderLine02)
        
        buttonCommentPinDetailDragToLargeSize = UIButton(frame: CGRect(x: 0, y: 1, width: screenWidth, height: 27))
        buttonCommentPinDetailDragToLargeSize.backgroundColor = UIColor.white
        buttonCommentPinDetailDragToLargeSize.setImage(#imageLiteral(resourceName: "pinDetailDraggingButton"), for: UIControlState())
        buttonCommentPinDetailDragToLargeSize.addTarget(self, action: #selector(self.actionDraggingThisComment(_:)), for: .touchUpInside)
        self.draggingButtonSubview.addSubview(buttonCommentPinDetailDragToLargeSize)
        buttonCommentPinDetailDragToLargeSize.center.x = screenWidth/2
        //        buttonCommentPinDetailDragToLargeSize.layer.zPosition = 109
        buttonCommentPinDetailDragToLargeSize.tag = 0
        //        let draggingGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panActionCommentPinDetailDrag(_:)))
        //        buttonCommentPinDetailDragToLargeSize.addGestureRecognizer(draggingGesture)
        loadTableHeader()
        tableCommentsForComment.tableHeaderView = uiviewCommentPinDetail
        loadAnotherToolbar()
        loadPinCtrlButton()
    }
    
    private func loadTableHeader() {
        // Header
        uiviewCommentPinDetail = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 281))
        uiviewCommentPinDetail.backgroundColor = UIColor.white
        let tapToDismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(self.tapOutsideToDismissKeyboard(_:)))
        uiviewCommentPinDetail.addGestureRecognizer(tapToDismissKeyboard)
        uiviewCommentPinDetail.clipsToBounds = true
        
        // ----
        // Textview width based on different resolutions
        var textViewWidth: CGFloat = 0
        if screenWidth == 414 { // 5.5
            textViewWidth = 360
        }
        else if screenWidth == 320 { // 4.0
            textViewWidth = 266
        }
        else if screenWidth == 375 { // 4.7
            textViewWidth = 321
        }
        
        // Textview of comment pin detail
        textviewCommentPinDetail = UITextView(frame: CGRect(x: 27, y: 75, width: textViewWidth, height: 100))
        textviewCommentPinDetail.text = ""
        textviewCommentPinDetail.font = UIFont(name: "AvenirNext-Regular", size: 18)
        textviewCommentPinDetail.textColor = UIColor(red: 89/255, green: 89/255, blue: 89/255, alpha: 1.0)
        textviewCommentPinDetail.isUserInteractionEnabled = true
        textviewCommentPinDetail.isEditable = false
        textviewCommentPinDetail.textContainerInset = UIEdgeInsets.zero
        textviewCommentPinDetail.indicatorStyle = UIScrollViewIndicatorStyle.white
        uiviewCommentPinDetail.addSubview(textviewCommentPinDetail)
        
        // ----
        // Main buttons' container of comment pin detail
        uiviewCommentPinDetailMainButtons = UIView(frame: CGRect(x: 0, y: 190, width: screenWidth, height: 22))
        uiviewCommentPinDetail.addSubview(uiviewCommentPinDetailMainButtons)
        
        // Comment Pin Like
        buttonCommentPinLike = UIButton()
        buttonCommentPinLike.setImage(#imageLiteral(resourceName: "pinDetailLikeHeartHollow"), for: UIControlState())
        buttonCommentPinLike.addTarget(self, action: #selector(self.actionLikeThisComment(_:)), for: [.touchUpInside, .touchUpOutside])
        buttonCommentPinLike.addTarget(self, action: #selector(self.actionHoldingLikeButton(_:)), for: .touchDown)
        uiviewCommentPinDetailMainButtons.addSubview(buttonCommentPinLike)
        uiviewCommentPinDetailMainButtons.addConstraintsWithFormat("H:[v0(56)]-90-|", options: [], views: buttonCommentPinLike)
        uiviewCommentPinDetailMainButtons.addConstraintsWithFormat("V:[v0(22)]-0-|", options: [], views: buttonCommentPinLike)
        buttonCommentPinLike.tag = 0
        buttonCommentPinLike.layer.zPosition = 109
        
        // Add Comment
        buttonCommentPinAddComment = UIButton()
        buttonCommentPinAddComment.setImage(#imageLiteral(resourceName: "pinDetailShowCommentsHollow"), for: UIControlState())
        buttonCommentPinAddComment.addTarget(self, action: #selector(self.actionReplyToThisComment(_:)), for: .touchUpInside)
        buttonCommentPinAddComment.tag = 0
        uiviewCommentPinDetailMainButtons.addSubview(buttonCommentPinAddComment)
        uiviewCommentPinDetailMainButtons.addConstraintsWithFormat("H:[v0(56)]-0-|", options: [], views: buttonCommentPinAddComment)
        uiviewCommentPinDetailMainButtons.addConstraintsWithFormat("V:[v0(22)]-0-|", options: [], views: buttonCommentPinAddComment)
        
        // Label of Like Count
        labelCommentPinLikeCount = UILabel()
        labelCommentPinLikeCount.text = ""
        labelCommentPinLikeCount.font = UIFont(name: "PingFang SC-Semibold", size: 15)
        labelCommentPinLikeCount.textColor = UIColor(red: 107/255, green: 105/255, blue: 105/255, alpha: 1.0)
        labelCommentPinLikeCount.textAlignment = .right
        uiviewCommentPinDetailMainButtons.addSubview(labelCommentPinLikeCount)
        uiviewCommentPinDetailMainButtons.addConstraintsWithFormat("H:[v0(41)]-141-|", options: [], views: labelCommentPinLikeCount)
        uiviewCommentPinDetailMainButtons.addConstraintsWithFormat("V:[v0(22)]-0-|", options: [], views: labelCommentPinLikeCount)
        
        // Label of Comments of Coment Pin Count
        labelCommentPinCommentsCount = UILabel()
        labelCommentPinCommentsCount.text = ""
        labelCommentPinCommentsCount.font = UIFont(name: "PingFang SC-Semibold", size: 15)
        labelCommentPinCommentsCount.textColor = UIColor(red: 107/255, green: 105/255, blue: 105/255, alpha: 1.0)
        labelCommentPinCommentsCount.textAlignment = .right
        uiviewCommentPinDetailMainButtons.addSubview(labelCommentPinCommentsCount)
        uiviewCommentPinDetailMainButtons.addConstraintsWithFormat("H:[v0(41)]-49-|", options: [], views: labelCommentPinCommentsCount)
        uiviewCommentPinDetailMainButtons.addConstraintsWithFormat("V:[v0(22)]-0-|", options: [], views: labelCommentPinCommentsCount)
        
        
        // ----
        // Gray Block
        uiviewCommentPinDetailGrayBlock = UIView(frame: CGRect(x: 0, y: 227, width: screenWidth, height: 12))
        uiviewCommentPinDetailGrayBlock.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1.0)
        uiviewCommentPinDetail.addSubview(uiviewCommentPinDetailGrayBlock)
        
        
        // ----
        // View to hold three buttons
        uiviewPinDetailThreeButtons = UIView(frame: CGRect(x: 0, y: 239, width: screenWidth, height: 42))
        uiviewCommentPinDetail.addSubview(uiviewPinDetailThreeButtons)
        
        // Three buttons bottom gray line
        uiviewGrayBaseLine = UIView()
        uiviewGrayBaseLine.layer.borderWidth = 1.0
        uiviewGrayBaseLine.layer.borderColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1.0).cgColor
        uiviewPinDetailThreeButtons.addSubview(uiviewGrayBaseLine)
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("H:|-0-[v0(\(screenWidth))]", options: [], views: uiviewGrayBaseLine)
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("V:[v0(1)]-0-|", options: [], views: uiviewGrayBaseLine)
        
        let widthOfThreeButtons = screenWidth / 3
        
        // Three buttons bottom sliding red line
        uiviewRedSlidingLine = UIView(frame: CGRect(x: 0, y: 40, width: widthOfThreeButtons, height: 2))
        uiviewRedSlidingLine.layer.borderWidth = 1.0
        uiviewRedSlidingLine.layer.borderColor = UIColor(red: 249/255, green: 90/255, blue: 90/255, alpha: 1.0).cgColor
        uiviewPinDetailThreeButtons.addSubview(uiviewRedSlidingLine)
        
        // "Talk Talk" of this uiview
        labelPinDetailViewComments = UILabel()
        labelPinDetailViewComments.text = "Talk Talk"
        labelPinDetailViewComments.textColor = UIColor.faeAppInputTextGrayColor()
        labelPinDetailViewComments.textAlignment = .center
        labelPinDetailViewComments.font = UIFont(name: "AvenirNext-Medium", size: 16)
        uiviewPinDetailThreeButtons.addSubview(labelPinDetailViewComments)
        
        buttonPinDetailViewComments = UIButton()
        buttonPinDetailViewComments.addTarget(self, action: #selector(self.animationRedSlidingLine(_:)), for: .touchUpInside)
        uiviewPinDetailThreeButtons.addSubview(buttonPinDetailViewComments)
        buttonPinDetailViewComments.tag = 1
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: labelPinDetailViewComments)
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: buttonPinDetailViewComments)
        
        
        // "Feelings" of this uiview
        labelPinDetailViewFeelings = UILabel()
        labelPinDetailViewFeelings.text = "Feelings"
        labelPinDetailViewFeelings.textColor = UIColor.faeAppInputTextGrayColor()
        labelPinDetailViewFeelings.textAlignment = .center
        labelPinDetailViewFeelings.font = UIFont(name: "AvenirNext-Medium", size: 16)
        uiviewPinDetailThreeButtons.addSubview(labelPinDetailViewFeelings)
        
        buttonPinDetailViewFeelings = UIButton()
        buttonPinDetailViewFeelings.addTarget(self, action: #selector(self.animationRedSlidingLine(_:)), for: .touchUpInside)
        uiviewPinDetailThreeButtons.addSubview(buttonPinDetailViewFeelings)
        buttonPinDetailViewFeelings.tag = 3
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: labelPinDetailViewFeelings)
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: buttonPinDetailViewFeelings)
        
        
        // "People" of this uiview
        labelPinDetailViewPeople = UILabel()
        labelPinDetailViewPeople.text = "People"
        labelPinDetailViewPeople.textColor = UIColor.faeAppInputTextGrayColor()
        labelPinDetailViewPeople.textAlignment = .center
        labelPinDetailViewPeople.font = UIFont(name: "AvenirNext-Medium", size: 16)
        uiviewPinDetailThreeButtons.addSubview(labelPinDetailViewPeople)
        buttonPinDetailViewPeople = UIButton()
        buttonPinDetailViewPeople.addTarget(self, action: #selector(self.animationRedSlidingLine(_:)), for: .touchUpInside)
        uiviewPinDetailThreeButtons.addSubview(buttonPinDetailViewPeople)
        buttonPinDetailViewPeople.tag = 5
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: labelPinDetailViewPeople)
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: buttonPinDetailViewPeople)
        
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("H:|-0-[v0(\(widthOfThreeButtons))]-0-[v1(\(widthOfThreeButtons))]-0-[v2(\(widthOfThreeButtons))]", options: [], views: labelPinDetailViewComments, labelPinDetailViewFeelings, labelPinDetailViewPeople)
        uiviewPinDetailThreeButtons.addConstraintsWithFormat("H:|-0-[v0(\(widthOfThreeButtons))]-0-[v1(\(widthOfThreeButtons))]-0-[v2(\(widthOfThreeButtons))]", options: [], views: buttonPinDetailViewComments, buttonPinDetailViewFeelings, buttonPinDetailViewPeople)
        
        // Comment Pin User Avatar
        imageCommentPinUserAvatar = UIImageView()
        imageCommentPinUserAvatar.image = UIImage(named: "defaultMen")
        imageCommentPinUserAvatar.layer.cornerRadius = 25
        imageCommentPinUserAvatar.clipsToBounds = true
        imageCommentPinUserAvatar.contentMode = .scaleAspectFill
        uiviewCommentPinDetail.addSubview(imageCommentPinUserAvatar)
        uiviewCommentPinDetail.addConstraintsWithFormat("H:|-15-[v0(50)]", options: [], views: imageCommentPinUserAvatar)
        uiviewCommentPinDetail.addConstraintsWithFormat("V:|-15-[v0(50)]", options: [], views: imageCommentPinUserAvatar)
        
        // Comment Pin Username
        labelCommentPinUserName = UILabel()
        labelCommentPinUserName.text = ""
        labelCommentPinUserName.font = UIFont(name: "AvenirNext-Medium", size: 18)
        labelCommentPinUserName.textColor = UIColor(red: 89/255, green: 89/255, blue: 89/255, alpha: 1.0)
        labelCommentPinTitle.textAlignment = .left
        uiviewCommentPinDetail.addSubview(labelCommentPinUserName)
        uiviewCommentPinDetail.addConstraintsWithFormat("H:|-80-[v0(250)]", options: [], views: labelCommentPinUserName)
        uiviewCommentPinDetail.addConstraintsWithFormat("V:|-19-[v0(25)]", options: [], views: labelCommentPinUserName)
        
        // Timestamp of comment pin detail
        labelCommentPinTimestamp = UILabel()
        labelCommentPinTimestamp.text = ""
        labelCommentPinTimestamp.font = UIFont(name: "AvenirNext-Medium", size: 13)
        labelCommentPinTimestamp.textColor = UIColor(red: 107/255, green: 105/255, blue: 105/255, alpha: 1.0)
        labelCommentPinTimestamp.textAlignment = .left
        uiviewCommentPinDetail.addSubview(labelCommentPinTimestamp)
        uiviewCommentPinDetail.addConstraintsWithFormat("H:|-80-[v0(200)]", options: [], views: labelCommentPinTimestamp)
        uiviewCommentPinDetail.addConstraintsWithFormat("V:|-40-[v0(27)]", options: [], views: labelCommentPinTimestamp)
        
        // image view appears when saved pin button pressed
        imageViewSaved = UIImageView()
        imageViewSaved.image = #imageLiteral(resourceName: "pinSaved")
        view.addSubview(imageViewSaved)
        view.addConstraintsWithFormat("H:[v0(182)]", options: [], views: imageViewSaved)
        view.addConstraintsWithFormat("V:|-107-[v0(58)]", options: [], views: imageViewSaved)
        NSLayoutConstraint(item: imageViewSaved, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
        imageViewSaved.layer.zPosition = 200
        imageViewSaved.alpha = 0.0
    }
    
    private func loadNavigationBar() {
        subviewNavigation = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 65))
        subviewNavigation.backgroundColor = UIColor.white
        self.view.addSubview(subviewNavigation)
        subviewNavigation.layer.zPosition = 101
        subviewNavigation.center.y -= screenHeight
        
        // Line at y = 64
        uiviewCommentPinUnderLine01 = UIView(frame: CGRect(x: 0, y: 64, width: screenWidth, height: 1))
        uiviewCommentPinUnderLine01.layer.borderWidth = screenWidth
        uiviewCommentPinUnderLine01.layer.borderColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1.0).cgColor
        subviewNavigation.addSubview(uiviewCommentPinUnderLine01)
        
        // Back to Map
        buttonCommentPinBackToMap = UIButton()
        buttonCommentPinBackToMap.setImage(#imageLiteral(resourceName: "pinDetailBackToMap"), for: UIControlState())
        buttonCommentPinBackToMap.addTarget(self, action: #selector(self.actionBackToMap(_:)), for: UIControlEvents.touchUpInside)
        subviewNavigation.addSubview(buttonCommentPinBackToMap)
        subviewNavigation.addConstraintsWithFormat("H:|-(-24)-[v0(101)]", options: [], views: buttonCommentPinBackToMap)
        subviewNavigation.addConstraintsWithFormat("V:|-22-[v0(38)]", options: [], views: buttonCommentPinBackToMap)
        buttonCommentPinBackToMap.alpha = 0.0
        
        // Back to Comment Pin List
        buttonBackToCommentPinLists = UIButton()
        buttonBackToCommentPinLists.setImage(#imageLiteral(resourceName: "pinDetailJumpToOpenedPin"), for: UIControlState())
        buttonBackToCommentPinLists.addTarget(self, action: #selector(self.actionGoToList(_:)), for: UIControlEvents.touchUpInside)
        subviewNavigation.addSubview(buttonBackToCommentPinLists)
        subviewNavigation.addConstraintsWithFormat("H:|-(-24)-[v0(101)]", options: [], views: buttonBackToCommentPinLists)
        subviewNavigation.addConstraintsWithFormat("V:|-22-[v0(38)]", options: [], views: buttonBackToCommentPinLists)
        
        // Comment Pin Option
        buttonOptionOfCommentPin = UIButton()
        buttonOptionOfCommentPin.setImage(#imageLiteral(resourceName: "pinDetailMoreOptions"), for: UIControlState())
        buttonOptionOfCommentPin.addTarget(self, action: #selector(self.showCommentPinMoreButtonDetails(_:)), for: UIControlEvents.touchUpInside)
        subviewNavigation.addSubview(buttonOptionOfCommentPin)
        subviewNavigation.addConstraintsWithFormat("H:[v0(101)]-(-22)-|", options: [], views: buttonOptionOfCommentPin)
        subviewNavigation.addConstraintsWithFormat("V:|-23-[v0(37)]", options: [], views: buttonOptionOfCommentPin)
        
        // Label of Title
        labelCommentPinTitle = UILabel()
        labelCommentPinTitle.text = "Comment"
        labelCommentPinTitle.font = UIFont(name: "AvenirNext-Medium", size: 20)
        labelCommentPinTitle.textColor = UIColor(red: 89/255, green: 89/255, blue: 89/255, alpha: 1.0)
        labelCommentPinTitle.textAlignment = .center
        subviewNavigation.addSubview(labelCommentPinTitle)
        subviewNavigation.addConstraintsWithFormat("H:[v0(92)]", options: [], views: labelCommentPinTitle)
        subviewNavigation.addConstraintsWithFormat("V:|-28-[v0(27)]", options: [], views: labelCommentPinTitle)
        NSLayoutConstraint(item: labelCommentPinTitle, attribute: .centerX, relatedBy: .equal, toItem: subviewNavigation, attribute: .centerX, multiplier: 1.0, constant: 0).isActive = true
    }
    
    func loadAnotherToolbar() {
        // Gray Block
        controlBoard = UIView(frame: CGRect(x: 0, y: 64, width: screenWidth, height: 54))
        controlBoard.backgroundColor = UIColor.white
        self.view.addSubview(controlBoard)
        self.controlBoard.isHidden = true
        controlBoard.layer.zPosition = 110
        
        let anotherGrayBlock = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 12))
        anotherGrayBlock.backgroundColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1.0)
        self.controlBoard.addSubview(anotherGrayBlock)
        
        // Three buttons bottom gray line
        let grayBaseLine = UIView()
        grayBaseLine.layer.borderWidth = 1.0
        grayBaseLine.layer.borderColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1.0).cgColor
        self.controlBoard.addSubview(grayBaseLine)
        self.controlBoard.addConstraintsWithFormat("H:|-0-[v0(\(screenWidth))]", options: [], views: grayBaseLine)
        self.controlBoard.addConstraintsWithFormat("V:[v0(1)]-0-|", options: [], views: grayBaseLine)
        
        // View to hold three buttons
        let threeButtonsContainer = UIView(frame: CGRect(x: 0, y: 12, width: screenWidth, height: 42))
        self.controlBoard.addSubview(threeButtonsContainer)
        
        let widthOfThreeButtons = screenWidth / 3
        
        // Three buttons bottom sliding red line
        anotherRedSlidingLine = UIView(frame: CGRect(x: 0, y: 52, width: widthOfThreeButtons, height: 2))
        anotherRedSlidingLine.layer.borderWidth = 1.0
        anotherRedSlidingLine.layer.borderColor = UIColor(red: 249/255, green: 90/255, blue: 90/255, alpha: 1.0).cgColor
        self.controlBoard.addSubview(anotherRedSlidingLine)
        
        // "Talk Talk" of this uiview
        let labelComments = UILabel()
        labelComments.text = "Talk Talk"
        labelComments.textColor = UIColor.faeAppInputTextGrayColor()
        labelComments.textAlignment = .center
        labelComments.font = UIFont(name: "AvenirNext-Medium", size: 16)
        threeButtonsContainer.addSubview(labelComments)
        let comments = UIButton(frame: CGRect(x: 0, y: 0, width: widthOfThreeButtons, height: 42))
        comments.addTarget(self, action: #selector(self.animationRedSlidingLine(_:)), for: .touchUpInside)
        threeButtonsContainer.addSubview(comments)
        comments.tag = 1
        threeButtonsContainer.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: labelComments)
        threeButtonsContainer.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: comments)
        
        // "Feelings" of this uiview
        let labelFeelings = UILabel()
        labelFeelings.text = "Feelings"
        labelFeelings.textColor = UIColor.faeAppInputTextGrayColor()
        labelFeelings.textAlignment = .center
        labelFeelings.font = UIFont(name: "AvenirNext-Medium", size: 16)
        threeButtonsContainer.addSubview(labelFeelings)
        let feelings = UIButton(frame: CGRect(x: 0, y: 0, width: widthOfThreeButtons, height: 42))
        feelings.addTarget(self, action: #selector(self.animationRedSlidingLine(_:)), for: .touchUpInside)
        threeButtonsContainer.addSubview(feelings)
        feelings.tag = 3
        threeButtonsContainer.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: labelFeelings)
        threeButtonsContainer.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: feelings)
        
        // "People" of this uiview
        let labelPeople = UILabel()
        labelPeople.text = "People"
        labelPeople.textColor = UIColor.faeAppInputTextGrayColor()
        labelPeople.textAlignment = .center
        labelPeople.font = UIFont(name: "AvenirNext-Medium", size: 16)
        threeButtonsContainer.addSubview(labelPeople)
        let people = UIButton(frame: CGRect(x: 0, y: 0, width: widthOfThreeButtons, height: 42))
        people.addTarget(self, action: #selector(self.animationRedSlidingLine(_:)), for: .touchUpInside)
        threeButtonsContainer.addSubview(people)
        people.tag = 5
        threeButtonsContainer.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: labelPeople)
        threeButtonsContainer.addConstraintsWithFormat("V:|-0-[v0(42)]", options: [], views: people)
        
        threeButtonsContainer.addConstraintsWithFormat("H:|-0-[v0(\(widthOfThreeButtons))]-0-[v1(\(widthOfThreeButtons))]-0-[v2(\(widthOfThreeButtons))]", options: [], views: labelComments, labelFeelings, labelPeople)
        threeButtonsContainer.addConstraintsWithFormat("H:|-0-[v0(\(widthOfThreeButtons))]-0-[v1(\(widthOfThreeButtons))]-0-[v2(\(widthOfThreeButtons))]", options: [], views: comments, feelings, people)
    }
    
    func loadPinCtrlButton() {
        commentPinIcon = UIImageView(frame: CGRect(x: 185, y: 477, width: 60, height: 80))
        commentPinIcon.image = UIImage(named: "markerCommentPinHeavyShadow")
        commentPinIcon.contentMode = .scaleAspectFit
        commentPinIcon.center.x = screenWidth/2
        commentPinIcon.center.y = 510
        commentPinIcon.layer.zPosition = 50
        commentPinIcon.alpha = 0
        self.view.addSubview(commentPinIcon)
        
        buttonPrevPin = UIButton(frame: CGRect(x: 15, y: 477, width: 52, height: 52))
        buttonPrevPin.setImage(UIImage(named: "prevPin"), for: UIControlState())
        buttonPrevPin.layer.zPosition = 60
        buttonPrevPin.layer.shadowColor = UIColor(red: 107/255, green: 105/255, blue: 105/255, alpha: 1.0).cgColor
        buttonPrevPin.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        buttonPrevPin.layer.shadowOpacity = 0.6
        buttonPrevPin.layer.shadowRadius = 3.0
        buttonPrevPin.alpha = 0
        self.view.addSubview(buttonPrevPin)
        
        buttonNextPin = UIButton(frame: CGRect(x: 399, y: 477, width: 52, height: 52))
        buttonNextPin.setImage(UIImage(named: "nextPin"), for: UIControlState())
        buttonNextPin.layer.zPosition = 60
        buttonNextPin.layer.shadowColor = UIColor(red: 107/255, green: 105/255, blue: 105/255, alpha: 1.0).cgColor
        buttonNextPin.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        buttonNextPin.layer.shadowOpacity = 0.6
        buttonNextPin.layer.shadowRadius = 3.0
        buttonNextPin.alpha = 0
        self.view.addSubview(buttonNextPin)
        self.view.addConstraintsWithFormat("H:[v0(52)]-15-|", options: [], views: buttonNextPin)
        self.view.addConstraintsWithFormat("V:|-477-[v0(52)]", options: [], views: buttonNextPin)
    }
}
