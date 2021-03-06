//
//  FAENumberKeyboard.swift
//  faeBeta
//
//  Created by Huiyuan Ren on 16/8/21.
//  Edited by Sophie Wang
//  Copyright © 2016年 fae. All rights reserved.
//

import Foundation
import UIKit

@objc protocol FAENumberKeyboardDelegate {
    // num can be -1 ~ 9. -1 means delete.
    func keyboardButtonTapped(_ num:Int)
    @objc optional func deleteAll()
}

class FAENumberKeyboard: UIView {
    // MARK: - Interface
    var uiview: UIView?
    var delegate: FAENumberKeyboardDelegate!
    var numMode = ""

    @IBOutlet var numberButtons: [UIButton]!
    @IBOutlet weak var deleteButton: UIButton!
    
    // MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
        setup()
    }
    
    //MARK: - setup
    fileprivate func loadNib() {
        uiview = Bundle.main.loadNibNamed("FAENumberKeyboard", owner: self, options: nil)![0] as? UIView
        self.insertSubview(uiview!, at: 0)
        uiview!.frame = self.bounds
        uiview!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    fileprivate func setup() {
        for button in numberButtons {
            button.backgroundColor = UIColor.clear
            button.setAttributedTitle(NSAttributedString(string: "\(button.tag)", attributes: [NSAttributedStringKey.foregroundColor: UIColor._2499090(), NSAttributedStringKey.font: UIFont(name: "AvenirNext-Regular", size: 38)!]), for: UIControlState())
            button.addTarget(self, action: #selector(numberButtonTapped(_:)), for: .touchUpInside)
        }
        let imgDeleteIcon = UIImageView(frame: CGRect(x: screenWidth / 6 - 20, y: 20 * screenHeightFactor * screenHeightFactor, width: 31, height: 22))
        imgDeleteIcon.image = #imageLiteral(resourceName: "erase")
        deleteButton.addSubview(imgDeleteIcon)
        deleteButton.addTarget(self, action: #selector(numberButtonTapped(_:)), for: .touchUpInside)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        deleteButton.addGestureRecognizer(longPress)
    }
    
    @objc func numberButtonTapped(_ sender:AnyObject) {
        let button = sender as! UIButton
        if delegate != nil {
            delegate.keyboardButtonTapped(button.tag)
        }
    }
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
//        if sender.state == .changed {
            if delegate != nil && numMode == "phoneNum" {
                delegate.deleteAll!()
            }
//        }
    }
}
