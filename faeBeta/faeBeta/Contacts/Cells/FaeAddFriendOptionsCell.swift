//
//  FaeAddFriendOptionsCell.swift
//  FaeContacts
//
//  Created by Justin He on 6/15/17.
//  Copyright © 2017 Yue. All rights reserved.
//

import UIKit

class FaeAddFriendOptionsCell: UITableViewCell {
    
    // MARK: - Properties
    var imgIcon: UIImageView!
    var lblOption: UILabel!
    private var imgArrow: UIImageView!
    var bottomLine: UIView!
    
    // MARK: - init
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
        selectionStyle = .none
        loadAddFriendOptionsCellContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Set up
    private func loadAddFriendOptionsCellContent() {
        imgIcon = UIImageView()
        imgIcon.frame = CGRect(x: 15, y: 12, width: 28, height: 28)
        imgIcon.contentMode = .scaleAspectFit
        addSubview(imgIcon)
        
        lblOption = UILabel()
        lblOption.textAlignment = .left
        lblOption.textColor = UIColor._898989()
        lblOption.font = UIFont(name: "AvenirNext-Medium", size: 18)
        addSubview(lblOption)
        addConstraintsWithFormat("H:|-63-[v0]-0-|", options: [], views: lblOption)
        addConstraintsWithFormat("V:|-0-[v0]-0-|", options: [], views: lblOption)
        
        imgArrow = UIImageView()
        imgArrow.frame = CGRect(x: screenWidth - 25, y: 19, width: 8.57, height: 15)
        imgArrow.contentMode = .scaleAspectFit
        imgArrow.image = #imageLiteral(resourceName: "addFriendOptionArrowIcon")
        addSubview(imgArrow)
        
        bottomLine = UIView()
        bottomLine.backgroundColor = UIColor._200199204()
        addSubview(bottomLine)
        addConstraintsWithFormat("H:|-0-[v0]-0-|", options: [], views: bottomLine)
        addConstraintsWithFormat("V:[v0(1)]-0-|", options: [], views: bottomLine)
    }
}
