//
//  SetDisplayName.swift
//  FaeSettings
//
//  Created by 子不语 on 2017/9/17.
//  Copyright © 2017年 子不语. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol PassShortIntroBackDelegate: class {
    func protSaveShortIntro(txtIntro: String?)
}

class SetShortIntro: UIViewController, UITextViewDelegate {
    // MARK: - Properties
    weak var delegate: PassShortIntroBackDelegate?
    private var btnBack: UIButton!
    private var lblTitle: UILabel!
    private var lblPlaceholder: UILabel!
    private var textView: UITextView!
    private var lblRequestResult: UILabel!
    private var lblEditIntro: UILabel!
    private var btnSave: UIButton!
    private var boolWillDisappear: Bool = false
    var strFieldText: String = ""
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addObersers()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:))))
        
        btnBack = UIButton(frame: CGRect(x: 15, y: 36 + device_offset_top, width: 18, height: 18))
        view.addSubview(btnBack)
        btnBack.setImage(#imageLiteral(resourceName: "Settings_back"), for: .normal)
        btnBack.addTarget(self, action: #selector(actionGoBack(_:)), for: .touchUpInside)
        
        lblTitle = UILabel(frame: CGRect(x: 0, y: 99 + device_offset_top, width: screenWidth, height: 27))
        view.addSubview(lblTitle)
        lblTitle.text = "Short Intro"
        lblTitle.font = UIFont(name: "AvenirNext-Medium", size: 20)
        lblTitle.textColor = UIColor._898989()
        lblTitle.textAlignment = .center
        
        textView = UITextView(frame: CGRect(x: 0, y: 174 + device_offset_top, width: 244, height: 105))
        textView.center.x = screenWidth / 2
        view.addSubview(textView)
        textView.textAlignment = .left
        textView.textColor = UIColor._898989()
        textView.tintColor = UIColor._2499090()
        textView.font = UIFont(name: "AvenirNext-Regular", size: 25)
        textView.delegate = self
        
        lblPlaceholder = UILabel(frame: CGRect(x: 0, y: 0, width: 244, height: 34))
        textView.addSubview(lblPlaceholder)
        lblPlaceholder.frame.origin.y = (textView.font?.pointSize)! / 3
        lblPlaceholder.text = "Write a Short Intro"
        lblPlaceholder.font = UIFont(name: "AvenirNext-Regular", size: 25)
        lblPlaceholder.textColor = UIColor._155155155()
        lblPlaceholder.textAlignment = .center
        
        if strFieldText != "" {
            textView.text = strFieldText
            lblPlaceholder.isHidden = true
        }
        
        lblRequestResult = UILabel(frame: CGRect(x: 0, y: 230 + device_offset_top, width: screenWidth, height: 20))
        lblRequestResult.center.x = screenWidth / 2
        lblRequestResult.font = UIFont(name: "AvenirNext-Medium", size: 13)
        lblRequestResult.textColor = UIColor._2499090()
        lblRequestResult.textAlignment = .center
        view.addSubview(lblRequestResult)
        lblRequestResult.isHidden = true
        
        let remainingCount = 30 - strFieldText.count
        
        lblEditIntro = UILabel(frame: CGRect(x: 0, y: screenHeight - 96 - 18 - device_offset_bot, width: screenWidth, height: 18))
        view.addSubview(lblEditIntro)
        lblEditIntro.text = "\(remainingCount) Characters"
        lblEditIntro.font = UIFont(name: "AvenirNext-Medium", size: 13)
        lblEditIntro.textColor = UIColor._138138138()
        lblEditIntro.textAlignment = .center
        
        btnSave = UIButton(frame: CGRect(x: 0, y: screenHeight - 30 - 50 - device_offset_bot, width: 300, height: 50))
        btnSave.center.x = screenWidth / 2
        view.addSubview(btnSave)
        btnSave.titleLabel?.textColor = .white
        btnSave.titleLabel?.textAlignment = .center
        btnSave.setTitle("Save", for: .normal)
        btnSave.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 20)
        btnSave.backgroundColor = UIColor._2499090()
        btnSave.layer.cornerRadius = 25
        btnSave.addTarget(self, action: #selector(actionSaveIntro(_: )), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        boolWillDisappear = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        boolWillDisappear = true
    }
    
    private func addObersers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // MARK: - UITextViewDelegate
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let maxCharacter: Int = 30
        return (textView.text?.utf16.count ?? 0) + text.utf16.count - range.length <= maxCharacter
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let count = textView.text.utf16.count
        lblEditIntro.text = "\(30-(count)) Characters"
        if count == 30 {
            lblEditIntro.textColor = UIColor._2499090()
        } else {
            lblEditIntro.textColor = UIColor._138138138()
        }
        lblPlaceholder.isHidden = count != 0
        lblRequestResult.isHidden = true
    }
    
    // MARK: - Button & gesture actions
    @objc private func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            textView.resignFirstResponder()
        }
    }
    
    @objc private func actionSaveIntro(_ sender: UIButton) {
        let user = FaeUser()
        user.whereKey("short_intro", value: textView.text!)
        user.updateNameCard { [weak self, weak delegate = self.delegate!] (status, message) in
            guard let `self` = self else { return }
            if status / 100 == 2 { // TODO: error code undecided
                delegate?.protSaveShortIntro(txtIntro: self.textView.text)
                if let nav = self.navigationController {
                    nav.popViewController(animated: true)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            } else if status == 500 {
                self.setRequestResult("Internal Service Error!")
            } else {
                felixprint("update short intro failed")
                let messageJSON = JSON(message!)
                if let error_code = messageJSON["error_code"].string {
                    handleErrorCode(.auth, error_code, { [weak self] (prompt) in
                        self?.setRequestResult("Save Failed! Please try later!")
                    })
                }
            }
        }
    }
    
    private func setRequestResult(_ prompt: String) {
        lblRequestResult.text = prompt
        lblRequestResult.isHidden = false
    }
    
    @objc private func actionGoBack(_ sender: UIButton) {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            textView.resignFirstResponder()
            dismiss(animated: true)
        }
    }
    
    // MARK: - Keyboard observer
    @objc func keyboardWillShow(_ notification: Notification) {
        if boolWillDisappear {
            return
        }
        let info = notification.userInfo!
        let frameKeyboard: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        UIView.animate(withDuration: 0.3, animations: {
            self.lblEditIntro.frame.origin.y = screenHeight - frameKeyboard.height - 98
            self.btnSave.frame.origin.y = screenHeight - frameKeyboard.height - 64
        })
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if boolWillDisappear {
            return
        }
        UIView.animate(withDuration: 0.3, animations: { 
            self.lblEditIntro.frame.origin.y = screenHeight - 96 - 18 - device_offset_bot
            self.btnSave.frame.origin.y = screenHeight - 30 - 50 - device_offset_bot
        })
    }
}
