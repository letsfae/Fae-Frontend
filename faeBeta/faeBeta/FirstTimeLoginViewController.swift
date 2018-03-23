//
//  FirstTimeLoginViewController.swift
//  faeBeta
//
//  Created by Yue on 12/15/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import SwiftyJSON
import RealmSwift
import Photos

protocol ButtonFinishClickedDelegate: class {
    func jumpToEnableNotification()
}

class FirstTimeLoginViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ChooseAvatarDelegate {
    
    weak var delegate: ButtonFinishClickedDelegate?
    var uiViewSetPicture: UIView!
    var labelTitle: UILabel!
    var buttonAvatar: UIButton!
    var textFieldDisplayName: UITextField!
    var buttonFinish: UIButton!
    var dimBackground: UIView!
    var imageViewAvatar: UIImageView!
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showGenderAge()
        firstTimeLogin()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, animations: {
            self.dimBackground.alpha = 1
        }, completion: nil)
    }
    
    func showGenderAge() {
        let updateGenderAge = FaeUser()
        updateGenderAge.whereKey("show_gender", value: "true")
        updateGenderAge.whereKey("show_age", value: "true")
        updateGenderAge.updateNameCard { status, _ in
            if status / 100 == 2 {
                // print("[showGenderAge] Successfully update namecard")
            } else {
                print("[showGenderAge] Fail to update namecard")
            }
        }
    }
    
    func updateDefaultProfilePic() {
        if Key.shared.gender == "female" {
            self.imageViewAvatar.image = #imageLiteral(resourceName: "PeopleWomen")
        } else {
            self.imageViewAvatar.image = #imageLiteral(resourceName: "PeopleMen")
        }
        let getSelfInfo = FaeUser()
        getSelfInfo.getAccountBasicInfo({ (status: Int, message: Any?) in
            if status / 100 != 2 {
                return
            }
            let selfUserInfoJSON = JSON(message!)
            if let gender = selfUserInfoJSON["gender"].string {
                Key.shared.gender = gender
                if gender == "female" {
                    self.imageViewAvatar.image = #imageLiteral(resourceName: "PeopleWomen")
                } else {
                    self.imageViewAvatar.image = #imageLiteral(resourceName: "PeopleMen")
                }
            }
        })
    }
    
    func firstTimeLogin() {
        dimBackground = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
        dimBackground.backgroundColor = UIColor(red: 107 / 255, green: 105 / 255, blue: 105 / 255, alpha: 0.5)
        dimBackground.alpha = 0
        view.addSubview(dimBackground)
        
        var offset = 116 * screenWidthFactor
        if screenHeight == 812 {
            offset = 175
        }
        uiViewSetPicture = UIView(frame: CGRect(x: 62 * screenWidthFactor, y: offset, width: 290 * screenWidthFactor, height: 334 * screenWidthFactor))
        uiViewSetPicture.backgroundColor = UIColor.white
        uiViewSetPicture.layer.cornerRadius = 16
        dimBackground.addSubview(uiViewSetPicture)
        
        labelTitle = UILabel(frame: CGRect(x: 48 * screenWidthFactor, y: 27 * screenWidthFactor, width: 194 * screenWidthFactor, height: 44 * screenWidthFactor))
        labelTitle.text = "Set your Profile Picture\n & Display Name"
        labelTitle.numberOfLines = 0
        labelTitle.textAlignment = NSTextAlignment.center
        labelTitle.textColor = UIColor._898989()
        labelTitle.font = UIFont(name: "AvenirNext-Medium", size: 16 * screenWidthFactor)
        uiViewSetPicture.addSubview(labelTitle)
        
        imageViewAvatar = UIImageView(frame: CGRect(x: 100, y: 88, w: 90, h: 90))
        updateDefaultProfilePic()
        imageViewAvatar.layer.cornerRadius = 45 * screenWidthFactor
        imageViewAvatar.clipsToBounds = true
        imageViewAvatar.contentMode = .scaleAspectFill
        uiViewSetPicture.addSubview(imageViewAvatar)
        
        buttonAvatar = UIButton(frame: CGRect(x: 100, y: 88, w: 90, h: 90))
        uiViewSetPicture.addSubview(buttonAvatar)
        buttonAvatar.addTarget(self, action: #selector(addProfileAvatar(_:)), for: .touchUpInside)
        
        textFieldDisplayName = UITextField(frame: CGRect(x: 0, y: 203, w: 160, h: 34))
        textFieldDisplayName.center.x = uiViewSetPicture.frame.size.width / 2
        //textFieldDisplayName.placeholder = "Display Name"
        textFieldDisplayName.attributedPlaceholder = NSAttributedString(string: "Display Name", attributes: [NSAttributedStringKey.foregroundColor: UIColor._155155155()])
        textFieldDisplayName.font = UIFont(name: "AvenirNext-Regular", size: 25 * screenWidthFactor)
        textFieldDisplayName.tintColor = UIColor._2499090()
        textFieldDisplayName.textColor = UIColor._2499090()
        textFieldDisplayName.textAlignment = .center
        textFieldDisplayName.addTarget(self, action: #selector(displayNameValueChanged(_:)), for: .editingChanged)
        textFieldDisplayName.textColor = UIColor._898989()
        textFieldDisplayName.autocorrectionType = .no
        uiViewSetPicture.addSubview(textFieldDisplayName)
        
        buttonFinish = UIButton(frame: CGRect(x: 40, y: 269, w: 210, h: 40))
        buttonFinish.layer.cornerRadius = 20 * screenWidthFactor
        buttonFinish.setTitle("Save", for: .normal)
        buttonFinish.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 16 * screenWidthFactor)
        buttonFinish.backgroundColor = UIColor._255160160()
        uiViewSetPicture.addSubview(buttonFinish)
        buttonFinish.isEnabled = false
        buttonFinish.addTarget(self, action: #selector(buttonFinishClicked(_:)), for: .touchUpInside)
    }
    
    @objc func buttonFinishClicked(_ sender: UIButton) {
        activityIndicator = UIActivityIndicatorView()
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor._2499090()
        view.addSubview(activityIndicator)
        view.bringSubview(toFront: activityIndicator)
        activityIndicator.startAnimating()
        //uploadProfileAvatar()
        SetAvatar.uploadUserImage(image: imageViewAvatar.image!, vc: self, type: "firstTimeLogin") {
            self.modifyDisplayName()
        }
    }
    
    func uploadProfileAvatar() {
        let avatar = FaeImage()
        avatar.image = imageViewAvatar.image
        avatar.faeUploadProfilePic { (code: Int, _: Any?) in
            if code / 100 == 2 {
                self.modifyDisplayName()
            } else {
                print("[uploadProfileAvatar] fail")
                self.activityIndicator.stopAnimating()
                self.showAlert(title: "Upload Profile Avatar Failed", message: "please try again")
                return
            }
        }
    }
    
    func modifyDisplayName() {
        let user = FaeUser()
        if let displayName = textFieldDisplayName.text {
            if displayName == "" {
                activityIndicator.stopAnimating()
                showAlert(title: "Please Enter Display Name", message: "try again")
                return
            }
            user.whereKey("nick_name", value: displayName)
            user.updateNameCard { (status: Int, _: Any?) in
                if status / 100 == 2 {
                    self.activityIndicator.stopAnimating()
                    self.textFieldDisplayName.resignFirstResponder()
                    self.updateUserRealm()
                    UIView.animate(withDuration: 0.3, animations: {
                        self.dimBackground.alpha = 0
                    }) { _ in
                        self.dismiss(animated: false, completion: nil)
                    }
                } else if status != 422 {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Tried to Change Display Name but Failed", message: "please try again")
                } else {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(title: "Please follow the rules to create a display name:", message: "1. Up to 50 characters\n2. No limits on uppercase or lowercase letters\n3. No limits on this symbols: !@#$%^&*)(+=._-, and space, but can't be all of them")
                }
            }
        }
    }
    
    func updateUserRealm() {
        let realm = try! Realm()
        let userRealm = FaeUserRealm()
        userRealm.userId = Int(Key.shared.user_id)
        userRealm.firstUpdate = true
        try! realm.write {
            realm.add(userRealm, update: true)
        }
    }
    
    @objc func displayNameValueChanged(_ sender: UITextField) {
        if sender.text != "" {
            buttonFinish.backgroundColor = UIColor._2499090()
            buttonFinish.isEnabled = true
        } else {
            buttonFinish.backgroundColor = UIColor._255160160()
            buttonFinish.isEnabled = false
        }
    }
    @objc func addProfileAvatar(_ sender: UIButton) {
        SetAvatar.addUserImage(vc: self, type: "firstTimeLogin")
    }
    /*@objc func addProfileAvatar(_ sender: UIButton) {
        SetAvatar.addUserImage(vc: self, type: "firstTimeLogin")
        let menu = UIAlertController(title: nil, message: "Choose image", preferredStyle: .actionSheet)
        menu.view.tintColor = UIColor._2499090()
        let showLibrary = UIAlertAction(title: "Choose from library", style: .default) { (alert: UIAlertAction) in
            var photoStatus = PHPhotoLibrary.authorizationStatus()
            if photoStatus != .authorized {
                PHPhotoLibrary.requestAuthorization({ (status) in
                    photoStatus = status
                    if photoStatus != .authorized {
                        self.showAlert(title: "Cannot access photo library", message: "Open System Setting -> Fae Map to turn on the camera access")
                        return
                    }
                    let imagePicker = FullAlbumCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
                    imagePicker.imageDelegate = self
                    imagePicker.vcComeFromType = .firstTimeLogin
                    imagePicker.vcComeFrom = self
                    imagePicker._maximumSelectedPhotoNum = 1
                    self.present(imagePicker, animated: true, completion: nil)
                })
            } else {
                let albumPicker = FullAlbumCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
                albumPicker.imageDelegate = self
                albumPicker.vcComeFromType = .firstTimeLogin
                albumPicker.vcComeFrom = self
                albumPicker._maximumSelectedPhotoNum = 1
                self.present(albumPicker, animated: true, completion: nil)
            }
        }
        let showCamera = UIAlertAction(title: "Take photos", style: .default) { (alert: UIAlertAction) in
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            var photoStatus = PHPhotoLibrary.authorizationStatus()
            if photoStatus != .authorized {
                PHPhotoLibrary.requestAuthorization({ (status) in
                    photoStatus = status
                    if photoStatus != .authorized {
                        self.showAlert(title: "Cannot access photo library", message: "Open System Setting -> Fae Map to turn on the camera access")
                        return
                    }
                    menu.removeFromParentViewController()
                    self.present(imagePicker, animated: true, completion: nil)
                })
            } else {
                menu.removeFromParentViewController()
                self.present(imagePicker, animated: true, completion: nil)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction) in
     
        }
        menu.addAction(showLibrary)
        menu.addAction(showCamera)
        menu.addAction(cancel)
        self.present(menu, animated: true, completion: nil)
    }*/
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String: AnyObject]?) {
        imageViewAvatar.image = image
        //uploadProfileAvatar()
        SetAvatar.uploadUserImage(image: image, vc: self, type: "firstTimeLogin")
        picker.dismiss(animated: true, completion: nil)
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.destructive)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    func finishChoosingAvatar(with faePHAsset: FaePHAsset) {
        SetAvatar.uploadUserImage(image: UIImage(data: faePHAsset.fullResolutionImageData!)!, vc: self, type: "firstTimeLogin")
    }
    func sendImages(_ images: [UIImage]) {
        print("send image for avatar")
        imageViewAvatar.image = images[0]
    }
    
}
