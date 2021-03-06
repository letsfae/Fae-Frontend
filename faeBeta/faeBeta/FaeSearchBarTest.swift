//
//  FaeSearchBarTest.swift
//  faeBeta
//
//  Created by Vicky on 2017-07-28.
//  Copyright © 2017 fae. All rights reserved.
//

import UIKit

@objc protocol FaeSearchBarTestDelegate: class {
    func searchBarTextDidBeginEditing(_ searchBar: FaeSearchBarTest)
    func searchBar(_ searchBar: FaeSearchBarTest, textDidChange searchText: String)
    func searchBarSearchButtonClicked(_ searchBar: FaeSearchBarTest)
    func searchBarClearButtonClicked(_ searchBar: FaeSearchBarTest)
    @objc optional func backspacePressed(_ searchBar: FaeSearchBarTest, isBackspace: Bool)
}

class FaeSearchBarTest: UIView, UITextFieldDelegate {
    weak var delegate: FaeSearchBarTestDelegate?
    var imgSearch: UIImageView!
    var btnClear: UIButton!
    var txtSchField: UITextField!
    var text: String? {
        didSet {
            guard let content = text else { return }
            guard txtSchField != nil else { return }
            txtSchField.attributedText = nil
            reloadTextFieldAttributes()
            txtSchField.text = content
        }
    }
    var attributedText: NSAttributedString? {
        didSet {
            guard let content = attributedText else { return }
            guard txtSchField != nil else { return }
            txtSchField.text = nil
            txtSchField.attributedText = content
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func setUpUI() {
        imgSearch = UIImageView()
        imgSearch.image = #imageLiteral(resourceName: "Search")
        imgSearch.contentMode = .scaleAspectFill
        addSubview(imgSearch)
//        let padding = (self.frame.size.height - 15) / 2
        addConstraintsWithFormat("V:|-17-[v0(15)]", options: [], views: imgSearch)
        
        btnClear = UIButton()
        btnClear.setImage(#imageLiteral(resourceName: "mainScreenSearchClearSearchBar"), for: .normal)
        btnClear.setImage(#imageLiteral(resourceName: "Settings_exclamation"), for: .selected)
        addSubview(btnClear)
        btnClear.addTarget(self, action: #selector(self.actionDeleteSearchTxt(_:)), for: .touchUpInside)
        addConstraintsWithFormat("V:|-0-[v0]-0-|", options: [], views: btnClear)
        
        txtSchField = UITextField()
        txtSchField.delegate = self
        addSubview(txtSchField)
        addConstraintsWithFormat("V:|-13-[v0(25)]", options: [], views: txtSchField)
        addConstraintsWithFormat("H:|-10-[v0(15)]-9-[v1]-5-[v2(30)]-21-|", options: [], views: imgSearch, txtSchField, btnClear)
        
        btnClear.isHidden = true
        
        txtSchField.textColor = UIColor._898989()
        txtSchField.font = UIFont(name: "AvenirNext-Medium", size: 18)
        txtSchField.clearButtonMode = .never
        txtSchField.contentHorizontalAlignment = .left
        txtSchField.textAlignment = .left
        txtSchField.contentVerticalAlignment = .center
        txtSchField.tintColor = UIColor._2499090()
        txtSchField.autocapitalizationType = .none
        txtSchField.autocorrectionType = .no
        txtSchField.returnKeyType = .search
        txtSchField.addTarget(self, action: #selector(self.actionTextFieldDidChange(_:)), for: .editingChanged)
    }
    
    public func reloadTextFieldAttributes() {
        txtSchField.textColor = UIColor._898989()
        txtSchField.font = UIFont(name: "AvenirNext-Medium", size: 18)
    }
    
    @objc func actionDeleteSearchTxt(_ sender: UIButton) {
        txtSchField.text = ""
        btnClear.isHidden = true
        delegate?.searchBar(self, textDidChange: "")
        delegate?.searchBarClearButtonClicked(self)
    }
    
    @objc func actionTextFieldDidChange(_ textField: UITextField) {
        if textField.text != "" {
            btnClear.isHidden = false
        } else {
            btnClear.isHidden = true
        }
        delegate?.searchBar(self, textDidChange: textField.text!)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.searchBarTextDidBeginEditing(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.searchBarSearchButtonClicked(self)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let  char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        if isBackSpace == -92 {
            print("Backspace was pressed")
            delegate?.backspacePressed?(self, isBackspace: true)
        }
        return true
    }
}

