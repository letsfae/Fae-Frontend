//
//  FaeNavBar.swift
//  faeBeta
//
//  Created by Yue on 5/1/17.
//  Copyright © 2017 fae. All rights reserved.
//

import UIKit

class FaeNavBar: UIView {

    public var leftBtnWidth = 10.5
    public var leftBtnPadding = 30.0
    var leftBtn = UIButton()
    var rightBtn = UIButton()
    var lblTitle = UILabel()
    var bottomLine = UIView()
    
    override init(frame: CGRect = CGRect.zero) {
        let newFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: screenWidth, height: 65 + device_offset_top))
        super.init(frame: newFrame)
        
        backgroundColor = .white
        
        // Line at y = 64
        bottomLine = UIView(frame: CGRect(x: 0, y: 64 + device_offset_top, width: screenWidth, height: 1))
        bottomLine.layer.borderWidth = screenWidth
        bottomLine.layer.borderColor = UIColor._200199204cg()
        addSubview(bottomLine)
        
        leftBtn.setImage(#imageLiteral(resourceName: "mainScreenSearchToFaeMap"), for: .normal)
        addSubview(leftBtn)
        
        rightBtn.setImage(#imageLiteral(resourceName: "pinDetailMoreOptions"), for: UIControlState())
        addSubview(rightBtn)
        
        lblTitle.text = ""
        lblTitle.font = UIFont(name: "AvenirNext-Medium", size: 20)
        lblTitle.textColor = UIColor._898989()
        lblTitle.textAlignment = .center
        addSubview(lblTitle)
        // Vicky 07/28/17
        addConstraintsWithFormat("H:|-70-[v0]-70-|", options: [], views: lblTitle)
        // Vicky 07/28/17 End
        //addConstraintsWithFormat("H:|-100-[v0]-100-|", options: [], views: lblTitle)
        addConstraintsWithFormat("V:|-(\(28+device_offset_top))-[v0(27)]", options: [], views: lblTitle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func loadBtnConstraints() {
        addConstraintsWithFormat("H:|-0-[v0(\(leftBtnPadding+leftBtnWidth))]", options: [], views: leftBtn)
        addConstraintsWithFormat("V:|-(\(22+device_offset_top))-[v0(38)]", options: [], views: leftBtn)
        addConstraintsWithFormat("H:[v0(101)]-(-22)-|", options: [], views: rightBtn)
        addConstraintsWithFormat("V:|-(\(22+device_offset_top))-[v0(38)]", options: [], views: rightBtn)
    }
    
    public func setBtnTitle() {
        leftBtn.setTitle("Cancel", for: .normal)
        leftBtn.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 18)
        leftBtn.setTitleColor(UIColor._155155155(), for: .normal)
    }
}
