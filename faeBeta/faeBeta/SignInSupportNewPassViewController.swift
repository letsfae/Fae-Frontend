//
//  SignInSupportNewPassViewController.swift
//  faeBeta
//
//  Created by blesssecret on 8/15/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

enum EnterFromMode {
    case login, settings
}

class SignInSupportNewPassViewController: RegisterBaseViewController {
    // MARK: - Properties
    var cellPassword: RegisterTextfieldTableViewCell!
    var oldPassword: String?
    private var password: String?
    var faeUser = FaeUser()
    var email: String?
    var phone: String?
    var code: String?
    var strVerified: String?
    var enterMode: EnterVerifyCodeMode!
    var enterFrom: EnterFromMode!
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        createBottomView(getInfoView())
        createTableView(59 + 135 * screenHeightFactor)
        btnContinue.setTitle("Update", for: UIControlState())
        registerCell()
        
        tableView.delegate = self
        tableView.dataSource = self
        super.createTopView("")
        super.imgProgress.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cellPassword.makeFirstResponder()
    }
    
    private func getInfoView() -> UIView {
        let uiviewInfo = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 85 * screenHeightFactor))
        let imgInfoPwd = UIImageView(frame: CGRect(x: view.frame.size.width / 2.0 - 160 * screenWidthFactor, y: 0, width: 320 * screenWidthFactor, height: 85 * screenHeightFactor))
        imgInfoPwd.image = UIImage(named: "InfoPassword")
        uiviewInfo.addSubview(imgInfoPwd)
        
        return uiviewInfo
    }
    
    private func registerCell() {
        tableView.register(TitleTableViewCell.self, forCellReuseIdentifier: "TitleTableViewCellIdentifier")
        tableView.register(SubTitleTableViewCell.self, forCellReuseIdentifier: "SubTitleTableViewCellIdentifier")
        tableView.register(RegisterTextfieldTableViewCell.self, forCellReuseIdentifier: "RegisterTextfieldTableViewCellIdentifier")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Button actions
    override func backButtonPressed() {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
    
    override func continueButtonPressed() {
        view.endEditing(true)
        updatePasswordInUser()
    }
    
    private func updatePasswordInUser() {
        shouldShowActivityIndicator(true)
        if enterMode == .email {
            let param = ["email": email!,
                         "code": code!,
                         "password": password!]
            postToURL("/reset_login/password", parameter: param, authentication: Key.shared.headerAuthentication()) { [weak self] (status: Int, message: Any?) in
                guard let `self` = self else { return }
                if status / 100 == 2 {
                    if self.enterFrom == .login {
                        let user = FaeUser()
                        user.whereKey("email", value: self.email!)
                        user.whereKey("password", value: self.password!)
                        user.whereKey("device_id", value: Key.shared.headerDeviceID)
                        user.whereKey("is_mobile", value: "true")
                        user.logInBackground { [weak self] (status: Int, message: Any?) in
                            guard let `self` = self else { return }
                            self.shouldShowActivityIndicator(false)
                            if status / 100 == 2 {
                                self.navigationController?.popToRootViewController(animated: false)
                                if let vcRoot = UIApplication.shared.keyWindow?.rootViewController {
                                    if vcRoot is InitialPageController {
                                        if let vc = vcRoot as? InitialPageController {
                                            vc.goToFaeMap()
                                        }
                                    }
                                }
                            } else { // TODO: error code undecided
                                print("[Fail to Login]: \(status), [LOGIN ERROR MESSAGE]: \(message!)")
                            }
                        }
                    } else {   // enterFrom == .settings
                        self.shouldShowActivityIndicator(false)
                        let vc = SetAccountViewController()
                        vc.boolResetPswd = true
                        var arrViewControllers = self.navigationController?.viewControllers
                        arrViewControllers?.removeLast()
                        arrViewControllers?.removeLast()
                        arrViewControllers?.removeLast()
                        arrViewControllers?.removeLast()
                        arrViewControllers?.append(vc)
                        self.navigationController?.setViewControllers(arrViewControllers!, animated: false)
                    }
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "resetPasswordSucceed"), object: nil)
                } else { // TODO: error code undecided
                    print("[Fail to Reset Password] \(status) \(message!)")
                }
            }
        } else if enterMode == .phone {
            let param = ["phone": phone!,
                         "code": code!,
                         "password": password!]
            postToURL("/reset_login/password", parameter: param, authentication: Key.shared.headerAuthentication()) { [weak self] (status: Int, message: Any?) in
                guard let `self` = self else { return }
                if status / 100 == 2 {
                    if self.enterFrom == .login {
                        let user = FaeUser()
                        user.whereKey("phone", value: (self.phone)!)
                        user.whereKey("password", value: (self.password)!)
                        user.whereKey("device_id", value: Key.shared.headerDeviceID)
                        user.whereKey("is_mobile", value: "true")
                        user.logInBackground { [weak self] (status: Int, message: Any?) in
                            guard let `self` = self else { return }
                            self.shouldShowActivityIndicator(false)
                            if status / 100 == 2 {
                                self.navigationController?.popToRootViewController(animated: false)
                                if let vcRoot = UIApplication.shared.keyWindow?.rootViewController {
                                    if vcRoot is InitialPageController {
                                        if let vc = vcRoot as? InitialPageController {
                                            vc.goToFaeMap()
                                        }
                                    }
                                }
                            } else { // TODO: error code undecided
                                print("[Fail to Login]: \(status), [LOGIN ERROR MESSAGE]: \(message!)")
                            }
                        }
                    } else {   // enterFrom == .settings
                        self.shouldShowActivityIndicator(false)
                        let vc = SetAccountViewController()
                        vc.boolResetPswd = true
                        var arrViewControllers = self.navigationController?.viewControllers
                        arrViewControllers?.removeLast()
                        arrViewControllers?.removeLast()
                        arrViewControllers?.removeLast()
                        arrViewControllers?.removeLast()
                        arrViewControllers?.append(vc)
                        self.navigationController?.setViewControllers(arrViewControllers!, animated: false)
                    }
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "resetPasswordSucceed"), object: nil)
                } else { // TODO: error code undecided
                    print("[Fail to Reset Password] \(status) \(message!)")
                }
            }
        } else {  // enterMode == .oldPswd
            faeUser.whereKey("old_password", value: oldPassword!)
            faeUser.whereKey("new_password", value: password!)
            faeUser.updatePassword { [weak self] (status: Int, message: Any?) in
                guard let `self` = self else { return }
                if status / 100 == 2 {
                    let vc = SetAccountViewController()
                    vc.boolResetPswd = true
                    var arrViewControllers = self.navigationController?.viewControllers
                    arrViewControllers?.removeLast()
                    arrViewControllers?.removeLast()
                    arrViewControllers?.removeLast()
                    arrViewControllers?.append(vc)
                    self.navigationController?.setViewControllers(arrViewControllers!, animated: false)
                } else { // TODO: error code undecided
                    print("[Fail to Reset Password] \(status) \(message!)")
                }
            }
        }
    }
}

// MARK: - UITableView
extension SignInSupportNewPassViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleTableViewCellIdentifier") as! TitleTableViewCell
            cell.setTitleLabelText("Protect your Account \n with a Strong Password!")
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SubTitleTableViewCellIdentifier") as! SubTitleTableViewCell
            cell.setSubTitleLabelText("Must be at least 8 characters!")
            return cell
        case 2:
            if cellPassword == nil {
                cellPassword = tableView.dequeueReusableCell(withIdentifier: "RegisterTextfieldTableViewCellIdentifier") as! RegisterTextfieldTableViewCell
                cellPassword.setPlaceholderLabelText("New Password", indexPath: indexPath)
                cellPassword.setRightPlaceHolderDisplay(true)
                cellPassword.delegate = self
                cellPassword.setCharacterLimit(16)
            }
            return cellPassword
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleTableViewCellIdentifier") as! TitleTableViewCell
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 59
        case 1:
            return 60 * screenHeightFactor
        case 2:
            return 75 * screenHeightFactor
        default:
            return 0
        }
    }
}

// MARK: - RegisterTextfieldProtocol
extension SignInSupportNewPassViewController: RegisterTextfieldProtocol {
    func textFieldDidBeginEditing(_ indexPath: IndexPath) {
        activeIndexPath = indexPath
    }
    
    func textFieldShouldReturn(_ indexPath: IndexPath) {
        switch indexPath.row {
        case 2:
            cellPassword.endAsResponder()
        default: break
        }
    }
    
    func textFieldDidChange(_ text: String, indexPath: IndexPath) {
        switch indexPath.row {
        case 2:
            password = text
            cellPassword.updateTextColorAccordingToPassword(text)
        default: break
        }
        validation()
    }
    
    private func validation() {
        var boolIsValid = false
        boolIsValid = password != nil && password?.count > 7
        enableContinueButton(boolIsValid)
    }
}
