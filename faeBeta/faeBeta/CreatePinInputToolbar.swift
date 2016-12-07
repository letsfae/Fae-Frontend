//
//  CreatePinself.swift
//  faeBeta
//
//  Created by YAYUAN SHI on 12/6/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit

protocol CreatePinInputToolbarDelegate: class {
    func inputToolbarFinishButtonTapped(inputToolbar: CreatePinInputToolbar)
}

class CreatePinInputToolbar: UIView {

    //MARK: - properties
    private var buttonOpenFaceGesPanel: UIButton!
    private var buttonFinishEdit: UIButton!
    private var labelCountChars: UILabel!
    
    var maximumNumberOfCharacters: Int = 200
    private var _numberOfCharactersEntered: Int = 0
    var numberOfCharactersEntered: Int{
        set{
            _numberOfCharactersEntered = newValue
            labelCountChars.text = "\(maximumNumberOfCharacters - _numberOfCharactersEntered)"
        }
        get{
            return _numberOfCharactersEntered
        }
    }
    
    weak var delegate:CreatePinInputToolbarDelegate!
    
    //MARK: - init
    init()
    {
        super.init(frame: CGRect(x: 0, y: screenHeight, width: screenWidth, height: 100))
        setup()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented, use init() instead!")
    }

    override init(frame: CGRect)
    {
        fatalError("init(frame:) has not been implemented, use init() instead!")
    }
    
    //MARK: - setup
    private func setup()
    {
        self.backgroundColor = UIColor.clear
        let darkBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 50))
        darkBackgroundView.backgroundColor = UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 0.7)
        self.addSubview(darkBackgroundView)
        self.addConstraintsWithFormat("H:|-0-[v0]-0-|", options: [], views: darkBackgroundView)
        self.addConstraintsWithFormat("V:[v0(50)]-0-|", options: [], views: darkBackgroundView)
        
        
        buttonOpenFaceGesPanel = UIButton()
        buttonOpenFaceGesPanel.setImage(UIImage(named: "faceGesture"), for: UIControlState())
        self.addSubview(buttonOpenFaceGesPanel)
        self.addConstraintsWithFormat("H:|-15-[v0(23)]", options: [], views: buttonOpenFaceGesPanel)
        self.addConstraintsWithFormat("V:[v0(22)]-14-|", options: [], views: buttonOpenFaceGesPanel)
        
        buttonFinishEdit = UIButton()
        buttonFinishEdit.setImage(UIImage(named: "finishEditing"), for: UIControlState())
        self.addSubview(buttonFinishEdit)
        self.addConstraintsWithFormat("H:[v0(49)]-14-|", options: [], views: buttonFinishEdit)
        self.addConstraintsWithFormat("V:[v0(25)]-11-|", options: [], views: buttonFinishEdit)
        buttonFinishEdit.addTarget(self, action: #selector(self.finishEditButtonTapped(_:)), for: .touchUpInside)
        
        labelCountChars = UILabel(frame: CGRect(x: screenWidth-43, y: screenHeight, width: 29, height: 20))
        labelCountChars.text = "\(maximumNumberOfCharacters)"
        labelCountChars.font = UIFont(name: "AvenirNext-Medium", size: 16)
        labelCountChars.textAlignment = .right
        labelCountChars.textColor = UIColor.white
        self.self.addSubview(labelCountChars)
        self.addConstraintsWithFormat("V:[v0(20)]-9-[v1]", options: [], views: labelCountChars, darkBackgroundView)
        self.addConstraintsWithFormat("H:[v0(29)]-|", options: [], views: labelCountChars)
    }
    
    //MARK: - button actions
    func finishEditButtonTapped(_ sender: UIButton)
    {
        self.delegate?.inputToolbarFinishButtonTapped(inputToolbar:self)
    }
}
