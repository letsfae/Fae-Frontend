//
//  ChatViewController.swift
//  quickChat
//
//  Created by User on 6/6/16.
//  Copyright © 2016 User. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import FirebaseDatabase
import Photos
import MobileCoreServices
import CoreMedia
import AVFoundation
import RealmSwift

public let kAVATARSTATE = "avatarState"
public let kFIRSTRUN = "firstRun"
public var headerDeviceToken: Data!

class ChatViewController: JSQMessagesViewControllerCustom, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate, SendMutipleImagesDelegate, LocationSendDelegate, FAEChatToolBarContentViewDelegate, CAAnimationDelegate, BoardsSearchDelegate {
    // MARK: properties
    var uiviewNavBar: FaeNavBar!
    var uiviewLocationExtend = LocationExtendView()
    var toolbarContentView: FAEChatToolBarContentView!
    // custom toolBar the bottom toolbar button
    var btnSet = [UIButton]()
    var btnSend: UIButton!
    var btnKeyBoard: UIButton!
    var btnSticker: UIButton!
    var btnImagePicker: UIButton!
    var btnVoiceRecorder: UIButton!
    var btnLocation: UIButton!
    // heart animation related
    var imgHeart: UIImageView!
    var imgHeartDic: [CAAnimation: UIImageView] = [CAAnimation: UIImageView]()
    // the proxy of the keyboard
    var uiviewKeyboard: UIView!
    
    var ref = Database.database().reference().child(fireBaseRef) // reference to all chat room
    var roomRef: DatabaseReference?
    var _refHandle: DatabaseHandle?
    var dictArrInitMessages: [NSDictionary] = [] // load latest 15 messages before showing chatting
    var arrJSQMessages: [JSQMessage] = [] // data source of collectionView
    var arrStrMessagesKey: [String] = [] // the key of each message to tell whether it is loaded
    var arrDictMessages: [NSDictionary] = [] // same content as JSQMessages, but in dictionary format
    var dictMessageSent: NSDictionary = [:] // the message just sent, used to reload collectionView
    let intNumberOfMessagesOneTime = 15
    var intNumberOfMessagesLoaded = 0
    var intTotalNumberOfMessages: Int {
        get {
            if let lastMessage = arrDictMessages.last {
                return lastMessage["index"] as! Int
            }
            return 0
        }
    }
    
    var realmWithUser: RealmUser? // info of the other user of chatting
    var avatarDictionary: NSMutableDictionary? // avatars of users in this chatting
    var strChatRoomId: String! // chatRoomId in the firebase
    var strChatId: String? // the chat Id returned by our server
    
    // the message bubble of mine
    var outgoingBubble = JSQMessagesBubbleImageFactoryCustom(bubble: UIImage(named: "bubble2"), capInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)).outgoingMessagesBubbleImage(with: UIColor._2499090())
    // the message bubble of the other user
    let incomingBubble = JSQMessagesBubbleImageFactoryCustom(bubble: UIImage(named: "bubble2"), capInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)).incomingMessagesBubbleImage(with: UIColor.white)
    var boolInitialLoadComplete = false // the first time open this chat room
    var boolLoadingPreviousMessages = false // load previous message when scroll to the top
    var dateLastMarker: Date! = Date.distantPast // time of last messages sent
    var boolSentInLast5s = false // avoid mutiple timestamps when sending photos
    private var animatingHeartTimer: Timer! // a timer to show heart animation continously
    var boolJustSentHeart = false // check if user just sent a heart sticker and avoid sending heart continuously
    
    var boolGoToFullContent = false // go to full album, full map, taking photo from chatting
    var boolClosingToolbarContentView = false
    var floatScrollViewOriginOffset: CGFloat = 0.0 // origin offset when starting dragging
    var floatDistanceInputBarToBottom: CGFloat {
        get {
            return self.toolbarBottomLayoutGuide.constant
        }
        set {
            self.toolbarBottomLayoutGuide.constant = newValue
        }
    }
    let floatLocExtendHeight: CGFloat = 76
    let floatInputBarHeight: CGFloat = 90
    let floatToolBarContentHeight: CGFloat = 271
  
    // not used now
    let userDefaults = UserDefaults.standard
    var showAvatar: Bool = true //false not show avatar, true show avatar
    var firstLoad: Bool? // whether it is the first time to load this room.
    
    // MARK: lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBarSet()
        loadInputBarComponent()
        setupToolbarContentView()
        uiviewLocationExtend.isHidden = true
        uiviewLocationExtend.buttonCancel.addTarget(self, action: #selector(closeLocExtendView), for: .touchUpInside)
        view.addSubview(uiviewLocationExtend)
        moveDownInputBar()
        
        collectionView.backgroundColor = UIColor._241241241()
        senderId = "\(Key.shared.user_id)"
        senderDisplayName = realmWithUser!.userNickName
        setAvatar()
        
        for message in dictArrInitMessages {
            _ = insertMessage(message)
            self.intNumberOfMessagesLoaded += 1
        }
        self.finishReceivingMessage(animated: false)
        /* ///////// Felix
         let realm = try! Realm()
         let messagesToLoad = realm.objects(RealmMessage.self).filter("withUserID == %@", withUserId!).sorted(byKeyPath: "date")
         for i in (messagesToLoad.count - 10)..<messagesToLoad.count {
         let message = messagesToLoad[i]
         let item: NSDictionary = ["type": message.type, "senderName": message.senderName, "senderId": message.senderID, "message": message.message, "date": message.date, "latitude": message.latitude.value, "longitude": message.longitude.value, "place": message.place, "snapImage": message.snapImage?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue : 0)), "videoDuration": message.videoDuration.value, "isHeartSticker": message.isHeartSticker, "data": message.data?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue : 0)), "keyValue": message.messageID, "hasTimeStamp": message.hasTimeStamp, "status": message.status]
         //print("_")
         _ = insertMessage(item)
         }
         ///////// */
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
        loadUserDefault()
        loadNewMessage()
        
        if boolGoToFullContent {
            scrollToBottom(false)
            boolGoToFullContent = false
        }
        
        if !boolInitialLoadComplete {
            scrollToBottom(false)
            boolInitialLoadComplete = true
        }
        
        let initializeType = (FAEChatToolBarContentType.sticker.rawValue | FAEChatToolBarContentType.photo.rawValue | FAEChatToolBarContentType.audio.rawValue | FAEChatToolBarContentType.minimap.rawValue)
        toolbarContentView.setup(initializeType)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ref.removeObserver(withHandle: _refHandle!)
        closeLocExtendView()
        moveDownInputBar()
        toolbarContentView.clearToolBarViews()
    }
    
    // MARK: setup    
    private func navigationBarSet() {
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        uiviewNavBar = FaeNavBar(frame: CGRect.zero)
        view.addSubview(uiviewNavBar)
        uiviewNavBar.loadBtnConstraints()
        uiviewNavBar.rightBtn.setImage(nil, for: .normal)
        uiviewNavBar.leftBtn.addTarget(self, action: #selector(navigationLeftItemTapped), for: .touchUpInside)        
        uiviewNavBar.lblTitle.text = realmWithUser!.userNickName
    }
    
    func loadInputBarComponent() {
        //        let camera = Camera(delegate_: self)
        let contentView = inputToolbar.contentView
        contentView?.backgroundColor = UIColor.white
        contentView?.textView.placeHolder = "Type Something..."
        contentView?.textView.contentInset = UIEdgeInsetsMake(3.0, 0.0, 1.0, 0.0)
        contentView?.textView.delegate = self
        
        let contentOffset = (screenWidth - 42 - 29 * 7) / 6 + 29
        btnKeyBoard = UIButton(frame: CGRect(x: 21, y: inputToolbar.frame.height - 36, width: 29, height: 29))
        btnKeyBoard.setImage(UIImage(named: "keyboardEnd"), for: UIControlState())
        btnKeyBoard.setImage(UIImage(named: "keyboardEnd"), for: .highlighted)
        btnKeyBoard.addTarget(self, action: #selector(showKeyboard), for: .touchUpInside)
        contentView?.addSubview(btnKeyBoard)
        
        btnSticker = UIButton(frame: CGRect(x: 21 + contentOffset * 1, y: inputToolbar.frame.height - 36, width: 29, height: 29))
        btnSticker.setImage(UIImage(named: "sticker"), for: UIControlState())
        btnSticker.setImage(UIImage(named: "sticker"), for: .highlighted)
        btnSticker.addTarget(self, action: #selector(showStikcer), for: .touchUpInside)
        contentView?.addSubview(btnSticker)
        
        btnImagePicker = UIButton(frame: CGRect(x: 21 + contentOffset * 2, y: inputToolbar.frame.height - 36, width: 29, height: 29))
        btnImagePicker.setImage(UIImage(named: "imagePicker"), for: UIControlState())
        btnImagePicker.setImage(UIImage(named: "imagePicker"), for: .highlighted)
        contentView?.addSubview(btnImagePicker)
        btnImagePicker.addTarget(self, action: #selector(showLibrary), for: .touchUpInside)
        
        let buttonCamera = UIButton(frame: CGRect(x: 21 + contentOffset * 3, y: inputToolbar.frame.height - 36, width: 29, height: 29))
        buttonCamera.setImage(UIImage(named: "camera"), for: UIControlState())
        buttonCamera.setImage(UIImage(named: "camera"), for: .highlighted)
        contentView?.addSubview(buttonCamera)
        buttonCamera.addTarget(self, action: #selector(showCamera), for: .touchUpInside)
        
        btnVoiceRecorder = UIButton(frame: CGRect(x: 21 + contentOffset * 4, y: inputToolbar.frame.height - 36, width: 29, height: 29))
        btnVoiceRecorder.setImage(UIImage(named: "voiceMessage"), for: UIControlState())
        btnVoiceRecorder.setImage(UIImage(named: "voiceMessage"), for: .highlighted)
        btnVoiceRecorder.addTarget(self, action: #selector(showRecord), for: .touchUpInside)
        contentView?.addSubview(btnVoiceRecorder)
        
        btnLocation = UIButton(frame: CGRect(x: 21 + contentOffset * 5, y: inputToolbar.frame.height - 36, width: 29, height: 29))
        btnLocation.setImage(UIImage(named: "shareLocation"), for: UIControlState())
        btnLocation.showsTouchWhenHighlighted = false
        btnLocation.addTarget(self, action: #selector(showMiniMap), for: .touchUpInside)
        contentView?.addSubview(btnLocation)
        
        btnSend = UIButton(frame: CGRect(x: 21 + contentOffset * 6, y: inputToolbar.frame.height - 36, width: 29, height: 29))
        btnSend.setImage(UIImage(named: "cannotSendMessage"), for: .disabled)
        btnSend.setImage(UIImage(named: "cannotSendMessage"), for: .highlighted)
        btnSend.setImage(UIImage(named: "canSendMessage"), for: .normal)
        
        contentView?.addSubview(btnSend)
        btnSend.isEnabled = false
        btnSend.addTarget(self, action: #selector(ChatViewController.sendMessageButtonTapped), for: .touchUpInside)
        
        btnSet.append(btnKeyBoard)
        btnSet.append(btnSticker)
        btnSet.append(btnImagePicker)
        btnSet.append(buttonCamera)
        btnSet.append(btnLocation)
        btnSet.append(btnVoiceRecorder)
        btnSet.append(btnSend)
        
        for button in btnSet {
            button.autoresizingMask = [.flexibleTopMargin]
        }
        
        contentView?.heartButtonHidden = false
        contentView?.heartButton.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        contentView?.heartButton.addTarget(self, action: #selector(actionHoldingLikeButton(_:)), for: .touchDown)
        contentView?.heartButton.addTarget(self, action: #selector(actionLeaveLikeButton(_:)), for: .touchDragOutside)
        
        automaticallyAdjustsScrollViewInsets = false
    }
    
    func setupToolbarContentView() {
        toolbarContentView = FAEChatToolBarContentView(frame: CGRect(x: 0, y: screenHeight, width: screenWidth, height: floatToolBarContentHeight))
        toolbarContentView.delegate = self
        toolbarContentView.inputToolbar = inputToolbar
        toolbarContentView.cleanUpSelectedPhotos()
        view.addSubview(toolbarContentView)
        toolbarContentView.viewMiniLoc.btnSearch.addTarget(self, action: #selector(showFullLocationView), for: .touchUpInside)
        toolbarContentView.viewMiniLoc.btnSend.addTarget(self, action: #selector(sendLocationMessageFromMini), for: .touchUpInside)
    }
    
    func navigationLeftItemTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func navigationRightItemTapped() {
        // TODO
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: NSNotification.Name(rawValue: "appWillEnterForeground"), object: nil)
        inputToolbar.contentView.textView.addObserver(self, forKeyPath: "text", options: [.new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        let textView = object as! UITextView
        if textView == inputToolbar.contentView.textView && keyPath! == "text" {
            
            let newString = (change![NSKeyValueChangeKey.newKey]! as! String)
            btnSend.isEnabled = newString.characters.count > 0
        }
    }
    
    func removeObservers() {
        inputToolbar.contentView.textView.removeObserver(self, forKeyPath: "text", context: nil)
    }
    
    // MARK: user default function
    func loadUserDefault() {
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if !firstLoad! {
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(showAvatar, forKey: kAVATARSTATE)
            userDefaults.synchronize()
        }
        showAvatar = true
        //        showAvatar = userDefaults.boolForKey(kAVATARSTATE)
    }
    
    // MARK: JSQMessages Delegate (useless, but require implementation)
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
    }
    
    //MARK: input bar tapped events
    func showKeyboard() {
        resetToolbarButtonIcon()
        btnKeyBoard.setImage(UIImage(named: "keyboard"), for: UIControlState())
        toolbarContentView.showKeyboard()
        inputToolbar.contentView.textView.becomeFirstResponder()
        //scrollToBottom(false)
    }
    
    func showCamera() {
        view.endEditing(true)
        uiviewLocationExtend.isHidden = true
        boolGoToFullContent = true
        UIView.animate(withDuration: 0.3, animations: {
            self.closeToolbarContentView()
        }, completion: nil)
        let camera = Camera(delegate_: self)
        camera.presentPhotoCamera(self, canEdit: false)
    }
    
    func showStikcer() {
        view.endEditing(true)
        resetToolbarButtonIcon()
        btnSticker.setImage(UIImage(named: "stickerChosen"), for: UIControlState())
        let animated = !toolbarContentView.mediaContentShow && !toolbarContentView.boolKeyboardShow
        toolbarContentView.showStikcer()
        moveUpInputBarContentView(animated)
        scrollToBottom(false)
    }
    
    func showLibrary() {
        view.endEditing(true)
        let status = PHPhotoLibrary.authorizationStatus()
        if status != .authorized {
            print("not authorized!")
            showAlertView(withWarning: "Cannot use this function without authorization to Photo!")
            return
        }
        resetToolbarButtonIcon()
        btnImagePicker.setImage(UIImage(named: "imagePickerChosen"), for: UIControlState())
        let animated = !toolbarContentView.mediaContentShow && !toolbarContentView.boolKeyboardShow
        toolbarContentView.showLibrary()
        uiviewLocationExtend.isHidden = true
        moveUpInputBarContentView(animated)
        scrollToBottom(false)
    }
    
    func showRecord() {
        view.endEditing(true)
        resetToolbarButtonIcon()
        btnVoiceRecorder.setImage(UIImage(named: "voiceMessage_red"), for: UIControlState())
        let animated = !toolbarContentView.mediaContentShow && !toolbarContentView.boolKeyboardShow
        toolbarContentView.showRecord()
        moveUpInputBarContentView(animated)
        scrollToBottom(false)
    }
    
    func showMiniMap() {
        view.endEditing(true)
        resetToolbarButtonIcon()
        btnLocation.setImage(UIImage(named: "locationChosen"), for: UIControlState())
        let animated = !toolbarContentView.mediaContentShow && !toolbarContentView.boolKeyboardShow
        toolbarContentView.showMiniLocation()
        moveUpInputBarContentView(animated)
        scrollToBottom(false)
    }
    
    func sendMessageButtonTapped() {
        if uiviewLocationExtend.isHidden {
            sendMessage(text: inputToolbar.contentView.textView.text, date: Date())
        } else {
            sendMessage(text: inputToolbar.contentView.textView.text, location: uiviewLocationExtend.location, snapImage: uiviewLocationExtend.getImageDate(), date: Date())
        }
        if uiviewLocationExtend.isHidden == false {
            uiviewLocationExtend.isHidden = true
            closeLocExtendView()
        }
        btnSend.isEnabled = false
    }
    
    //MARK: handle the position of input bar
    func moveUpInputBarContentView(_ animated: Bool) {
        collectionView.isScrollEnabled = false
        if animated {
            toolbarContentView.frame.origin.y = screenHeight
            floatDistanceInputBarToBottom = 0
            UIView.animate(withDuration: 0.3, animations: {
                self.setContraintsWhenInputBarMove(inputBarToBottom: self.floatToolBarContentHeight, keyboard: false)
            }, completion: { (_) -> Void in
                self.collectionView.isScrollEnabled = true
            })
        } else {
            self.setContraintsWhenInputBarMove(inputBarToBottom: self.floatToolBarContentHeight, keyboard: false)
            collectionView.isScrollEnabled = true
        }
    }
    
    func moveDownInputBar() {
        view.endEditing(true)
        setContraintsWhenInputBarMove(inputBarToBottom: 0, keyboard: false)
    }
    
    // MARK: input text field delegate
    override func textViewDidChange(_ textView: UITextView) {
        if textView.text.characters.count == 0 {
            // when text has no char, cannot send message
            btnSend.isEnabled = false
        } else {
            btnSend.isEnabled = true
        }
    }
    
    override func textViewDidEndEditing(_ textView: UITextView) {
    }
    
    override func textViewDidBeginEditing(_ textView: UITextView) {
        btnKeyBoard.setImage(UIImage(named: "keyboard"), for: UIControlState())
        showKeyboard()
        btnSend.isEnabled = inputToolbar.contentView.textView.text.characters.count > 0 || !uiviewLocationExtend.isHidden
    }
    
    // MARK: keyboard delegate
    func keyboardWillShow(_ notification: NSNotification) {
        keyboardFrameChange(notification)
    }
    
    func keyboardDidShow(_ notification: NSNotification) {
        toolbarContentView.boolKeyboardShow = true
        setProxyKeyboardView()
    }

    func keyboardWillHide(_ notification: NSNotification) {
        if toolbarContentView.mediaContentShow { // show toolbar, no keyboard
            uiviewKeyboard.frame.origin.y = screenHeight
            return
        }
        if uiviewKeyboard != nil {
            if uiviewKeyboard.frame.origin.y >= screenHeight { // keyboard is not visiable
                return
            }
        }
        keyboardFrameChange(notification)
    }
    
    func keyboardDidHide(_ notification: NSNotification) {
        toolbarContentView.boolKeyboardShow = false
        uiviewKeyboard = nil
    }
    
    @objc func keyboardFrameChange(_ notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            var distance: CGFloat = 0.0
            if (endFrame?.origin.y)! < screenHeight {
                distance = endFrame?.size.height ?? 0.0
            }
            UIView.animate(withDuration: duration, delay: TimeInterval(0), options: animationCurve, animations: {
                self.setContraintsWhenInputBarMove(inputBarToBottom: distance, keyboard: true)
                if endFrame?.origin.y != screenHeight {
                    self.scrollToBottom(false)
                }
            },
            completion:{ (_) -> Void in
                //TODO debug keyboard
            })
        }
    }
    
    func setContraintsWhenInputBarMove(inputBarToBottom distance: CGFloat, keyboard notToolBar: Bool = true, isScrolling: Bool = false) {
        let extendHeight = uiviewLocationExtend.isHidden ? 0.0 : floatLocExtendHeight
        floatDistanceInputBarToBottom = distance
        uiviewLocationExtend.frame.origin.y = screenHeight - distance - floatInputBarHeight - floatLocExtendHeight
        if !notToolBar {
            toolbarContentView.frame.origin.y = screenHeight - distance
        }
        view.setNeedsUpdateConstraints()
        view.layoutIfNeeded()
        if !isScrolling {
            let insets = UIEdgeInsetsMake(0.0, 0.0, distance + floatInputBarHeight + extendHeight, 0.0)
            self.collectionView.contentInset = insets
            self.collectionView.scrollIndicatorInsets = insets
        }
    }
    
    func setProxyKeyboardView() {
        var keyboardViewProxy = inputToolbar.contentView.textView.inputAccessoryView?.superview
        let windows = UIApplication.shared.windows
        for window in windows.reversed() {
            let className = NSStringFromClass(type(of: window))
            if className == "UIRemoteKeyboardWindow" {
                for subview in window.subviews {
                    for hostview in subview.subviews {
                        let hostClassName = NSStringFromClass(type(of: hostview))
                        if hostClassName == "UIInputSetHostView" {
                            keyboardViewProxy = hostview
                        }
                    }
                }
            }
        }
        uiviewKeyboard = keyboardViewProxy
    }
    
    // MARK: scroll view delegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            let scrollViewCurrentOffset = scrollView.contentOffset.y
            var dragDistanceY = scrollViewCurrentOffset - floatScrollViewOriginOffset
            //print("current offset: \(scrollViewCurrentOffset)")
            if dragDistanceY < 0
                && (toolbarContentView.mediaContentShow || toolbarContentView.boolKeyboardShow)
                && !boolClosingToolbarContentView && scrollView.isScrollEnabled == true {
                if toolbarContentView.boolKeyboardShow {
                    if uiviewKeyboard.frame.origin.y >= screenHeight {
                        return
                    }
                    let keyboardHeight = uiviewKeyboard.frame.height
                    if -dragDistanceY > keyboardHeight {
                        dragDistanceY = -keyboardHeight
                    }
                    setContraintsWhenInputBarMove(inputBarToBottom: keyboardHeight + dragDistanceY, keyboard: true, isScrolling: true)
                    if uiviewKeyboard != nil {
                        UIView.animate(withDuration: 0, delay: TimeInterval(0), options: [.beginFromCurrentState], animations: {
                            self.uiviewKeyboard.frame.origin.y = screenHeight - keyboardHeight - dragDistanceY
                        }, completion: nil)
                    }
                } else {
                    if -dragDistanceY > floatToolBarContentHeight {
                        dragDistanceY = -floatToolBarContentHeight
                    }
                    setContraintsWhenInputBarMove(inputBarToBottom: floatToolBarContentHeight + dragDistanceY, keyboard: false, isScrolling: true)
                }
            }
            if scrollViewCurrentOffset < 1 && !boolLoadingPreviousMessages {
                loadPreviousMessages()
            }
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == collectionView {
            floatScrollViewOriginOffset = scrollView.contentOffset.y
        }
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView == collectionView {
            let scrollViewCurrentOffset = scrollView.contentOffset.y
            if scrollViewCurrentOffset - floatScrollViewOriginOffset < -5 {
                UIView.setAnimationsEnabled(false)
                self.inputToolbar.contentView.textView.resignFirstResponder()
                UIView.setAnimationsEnabled(true)
                
                boolClosingToolbarContentView = true
                UIView.animate(withDuration: 0.1, animations: {
                    self.setContraintsWhenInputBarMove(inputBarToBottom: 0, keyboard: false)
                    if self.uiviewKeyboard != nil {
                        self.uiviewKeyboard.frame.origin.y = screenHeight
                    }
                }, completion: { (_) -> Void in
                    self.toolbarContentView.closeAll()
                    self.resetToolbarButtonIcon()
                    self.toolbarContentView.cleanUpSelectedPhotos()
                    self.boolClosingToolbarContentView = false
                })
            }
        }
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    }

    // MARK: quick photo picker
    func showFullAlbum() {
        closeToolbarContentView()
        boolGoToFullContent = true
        let layout = UICollectionViewFlowLayout()
        let vcFullAlbum = FullAlbumCollectionViewController(collectionViewLayout: layout)
        vcFullAlbum.imageDelegate = self
        navigationController?.pushViewController(vcFullAlbum, animated: true)
    }
    
    // MARK: handle events after user took a photo/video
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        let type = info[UIImagePickerControllerMediaType] as! String
        switch type {
        case (kUTTypeImage as String as String):
            let picture = info[UIImagePickerControllerOriginalImage] as! UIImage
            
            sendMessage(picture: picture, date: Date())
            
            UIImageWriteToSavedPhotosAlbum(picture, self, #selector(ChatViewController.image(_:didFinishSavingWithError:contextInfo:)), nil)
        case (kUTTypeMovie as String as String):
            let movieURL = info[UIImagePickerControllerMediaURL] as! URL
            
            //get duration of the video
            let asset = AVURLAsset(url: movieURL)
            let duration = CMTimeGetSeconds(asset.duration)
            let seconds = Int(ceil(duration))
            
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            var time = asset.duration
            time.value = 0
            
            //get snapImage
            var snapImage = UIImage()
            do {
                let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                snapImage = UIImage(cgImage: imageRef)
            } catch {
                //Handle failure
            }
            
            var imageData = UIImageJPEGRepresentation(snapImage, 1)
            let factor = min(5000000.0 / CGFloat(imageData!.count), 1.0)
            imageData = UIImageJPEGRepresentation(snapImage, factor)
            
            let path = movieURL.path
            let data = FileManager.default.contents(atPath: path)
            sendMessage(video: data, videoDuration: seconds, snapImage: imageData, date: Date())
            break
        default:
            break
        }
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    // after saving the photo, refresh the album
    func image(_ image: UIImage, didFinishSavingWithError error: NSError, contextInfo: AnyObject?) {
        appWillEnterForeground()
    }
    
    // MARK: mini-map picker
    func showFullLocationView(_ sender: UIButton) {
        // TODO
        closeToolbarContentView()
        boolGoToFullContent = true
        let vc = SelectLocationViewController()
        vc.delegate = self
        Key.shared.selectedLoc = LocManager.shared.curtLoc.coordinate
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // BoardsSearchDelegate
    func sendLocationBack(address: RouteAddress) {
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude:  address.coordinate.latitude, longitude: address.coordinate.longitude), completionHandler: {
            (placemarks, error) -> Void in
            guard let response = placemarks?[0] else { return }
            self.addResponseToLocationExtend(response: response, withMini: false)
            self.inputToolbar.contentView.textView.becomeFirstResponder()
        })
    }
    
    func closeLocExtendView() {
        uiviewLocationExtend.isHidden = true
        let insets = UIEdgeInsetsMake(0.0, 0.0, collectionView.contentInset.bottom - floatLocExtendHeight, 0.0)
        self.collectionView.contentInset = insets
        self.collectionView.scrollIndicatorInsets = insets
        btnSend.isEnabled = inputToolbar.contentView.textView.text.characters.count > 0
    }
    
    func sendLocationMessageFromMini(_ sender: UIButton) {
        if let mapview = toolbarContentView.viewMiniLoc.mapView {
            UIGraphicsBeginImageContext(mapview.frame.size)
            mapview.layer.render(in: UIGraphicsGetCurrentContext()!)
            if let screenShotImage = UIGraphicsGetImageFromCurrentImageContext() {
                uiviewLocationExtend.setAvator(image: screenShotImage)
                let location = CLLocation(latitude: mapview.camera.centerCoordinate.latitude, longitude: mapview.camera.centerCoordinate.longitude)
                CLGeocoder().reverseGeocodeLocation(location, completionHandler: {
                    (placemarks, error) -> Void in
                    guard let response = placemarks?[0] else { return }
                    self.addResponseToLocationExtend(response: response, withMini: true)
                })
            }
        }
    }
    
    func addResponseToLocationExtend(response: CLPlacemark, withMini: Bool) {
        var texts: [String] = []
        texts.append((response.subThoroughfare)! + " " + (response.thoroughfare)!)
        var cityText = response.locality
        if response.administrativeArea != nil {
            cityText = cityText! + ", " + (response.administrativeArea)!
        }
        if response.postalCode != nil {
            cityText = cityText! + " " + (response.postalCode)!
        }
        texts.append(cityText!)
        texts.append((response.country)!)
        uiviewLocationExtend.setLabel(texts: texts)
        uiviewLocationExtend.location = CLLocation(latitude: toolbarContentView.viewMiniLoc.mapView.camera.centerCoordinate.latitude, longitude: toolbarContentView.viewMiniLoc.mapView.camera.centerCoordinate.longitude)
        
        uiviewLocationExtend.isHidden = false
        let extendHeight = uiviewLocationExtend.isHidden ? 0 : floatLocExtendHeight
        var distance = floatInputBarHeight + extendHeight
        if withMini {
            distance += floatToolBarContentHeight
        }
        let insets = UIEdgeInsetsMake(0.0, 0.0, distance, 0.0)
        self.collectionView.contentInset = insets
        self.collectionView.scrollIndicatorInsets = insets
        scrollToBottom(false)
        btnSend.isEnabled = true
    }
    
    // MARK: heart button related
    @objc private func heartButtonTapped() {
        if animatingHeartTimer != nil {
            animatingHeartTimer.invalidate()
            animatingHeartTimer = nil
        }
        //animateHeart()
        if !boolJustSentHeart {
            sendMessage(sticker: #imageLiteral(resourceName: "pinDetailLikeHeartFullLarge"), isHeartSticker: true, date: Date())
            boolJustSentHeart = true
        }
    }
    
    @objc private func actionHoldingLikeButton(_ sender: UIButton) {
        if animatingHeartTimer == nil {
            animatingHeartTimer = Timer.scheduledTimer(timeInterval: 0.15, target: self, selector: #selector(animateHeart), userInfo: nil, repeats: true)
        }
    }
    
    @objc private func actionLeaveLikeButton(_ sender: UIButton) {
        if animatingHeartTimer != nil {
            animatingHeartTimer.invalidate()
            animatingHeartTimer = nil
        }
    }
    
    @objc private func animateHeart() {
        imgHeart = UIImageView(frame: CGRect(x: 0, y: 0, width: 26, height: 22))
        imgHeart.image = #imageLiteral(resourceName: "pinDetailLikeHeartFull")
        imgHeart.layer.opacity = 0
        inputToolbar.contentView.addSubview(imgHeart)
        
        let randomX = CGFloat(arc4random_uniform(150))
        let randomY = CGFloat(arc4random_uniform(50) + 100)
        let randomSize: CGFloat = (CGFloat(arc4random_uniform(40)) - 20) / 100 + 1
        
        let transform: CGAffineTransform = CGAffineTransform(translationX: inputToolbar.contentView.heartButton.center.x, y: inputToolbar.contentView.heartButton.center.y)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0), transform: transform)
        path.addLine(to: CGPoint(x: randomX - 75, y: -randomY), transform: transform)
        
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform")
        scaleAnimation.values = [NSValue(caTransform3D: CATransform3DMakeScale(1, 1, 1)), NSValue(caTransform3D: CATransform3DMakeScale(randomSize, randomSize, 1))]
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        scaleAnimation.duration = 1
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.fromValue = 1.0
        fadeAnimation.toValue = 0.0
        fadeAnimation.duration = 1
        fadeAnimation.delegate = self
        
        let orbit = CAKeyframeAnimation(keyPath: "position")
        orbit.duration = 1
        orbit.path = path
        orbit.calculationMode = kCAAnimationPaced
        imgHeart.layer.add(orbit, forKey: "Move")
        imgHeart.layer.add(fadeAnimation, forKey: "Opacity")
        imgHeart.layer.add(scaleAnimation, forKey: "Scale")
        imgHeart.layer.position = CGPoint(x: inputToolbar.contentView.heartButton.center.x, y: inputToolbar.contentView.heartButton.center.y)
    }
    
    // CAAnimationDelegate
    func animationDidStart(_ anim: CAAnimation) {
        if anim.duration == 1 {
            imgHeartDic[anim] = imgHeart
            let seconds = 0.5
            let delay = seconds * Double(NSEC_PER_SEC) // nanoseconds per seconds
            let dispatchTime = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                self.inputToolbar.contentView.sendSubview(toBack: self.imgHeartDic[anim]!)
            })
        }
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim.duration == 1 && flag {
            imgHeartDic[anim]?.removeFromSuperview()
            imgHeartDic[anim] = nil
        }
    }
    
    // MARK: utilities
    
    private func setAvatar() {
        createAvatars()
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 39, height: 39)
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 39, height: 39)
        if collectionView != nil {
            collectionView.reloadData()
        }
    }
    
    private func createAvatars() {
        let currentUserAvatar = avatarDic[Key.shared.user_id] != nil ? JSQMessagesAvatarImage(avatarImage: avatarDic[Key.shared.user_id], highlightedImage: avatarDic[Key.shared.user_id], placeholderImage: avatarDic[Key.shared.user_id]) : JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        let withUserAvatar = avatarDic[Int(realmWithUser!.userID)!] != nil ? JSQMessagesAvatarImage(avatarImage: avatarDic[Int(realmWithUser!.userID)!], highlightedImage: avatarDic[Int(realmWithUser!.userID)!], placeholderImage: avatarDic[Int(realmWithUser!.userID)!]) : JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        avatarDictionary = ["\(Key.shared.user_id)": currentUserAvatar!, realmWithUser!.userID: withUserAvatar!]
    }
    
    // scroll to the bottom of all messages
    func scrollToBottom(_ animated: Bool) {
        let item = collectionView(collectionView!, numberOfItemsInSection: 0) - 1
        if item >= 0 {
            let lastItemIndex = IndexPath(item: item, section: 0)
            collectionView?.scrollToItem(at: lastItemIndex, at: UICollectionViewScrollPosition.top, animated: animated)
        }
    }
    
    // dismiss the toolbar content view
    func closeToolbarContentView() {
        resetToolbarButtonIcon()
        moveDownInputBar()
        scrollToBottom(false)
        toolbarContentView.closeAll()
    }
    
    // change every button to its origin state
    fileprivate func resetToolbarButtonIcon() {
        btnKeyBoard.setImage(UIImage(named: "keyboardEnd"), for: UIControlState())
        btnKeyBoard.setImage(UIImage(named: "keyboardEnd"), for: .highlighted)
        btnSticker.setImage(UIImage(named: "sticker"), for: UIControlState())
        btnSticker.setImage(UIImage(named: "sticker"), for: .highlighted)
        btnImagePicker.setImage(UIImage(named: "imagePicker"), for: .highlighted)
        btnImagePicker.setImage(UIImage(named: "imagePicker"), for: UIControlState())
        btnVoiceRecorder.setImage(UIImage(named: "voiceMessage"), for: UIControlState())
        btnVoiceRecorder.setImage(UIImage(named: "voiceMessage"), for: .highlighted)
        btnLocation.setImage(UIImage(named: "shareLocation"), for: UIControlState())
        btnSend.isEnabled = !uiviewLocationExtend.isHidden
    }
    
    // allow adding timestamp to message (used in SendLoadMessages)
    func enableTimeStamp() {
        boolSentInLast5s = false
    }
    
    // show alert message
    func showAlertView(withWarning text: String) {
        let alert = UIAlertController(title: text, message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
 
    // need to refresh the album because user might take a photo outside the app
    func appWillEnterForeground() {
        collectionView.reloadData()
        toolbarContentView.reloadPhotoAlbum()
    }

    func appendEmoji(_ name: String) { }
    
    func deleteLastEmoji() { }
    
    func respondToSwipeGesture(_ gesture: UIGestureRecognizer) { }
}
