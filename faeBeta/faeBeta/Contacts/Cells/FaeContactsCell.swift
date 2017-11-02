//
//  FaeContactsCell.swift
//  FaeContacts
//
//  Created by 子不语 on 2017/6/13.
//  Copyright © 2017年 Yue. All rights reserved.
//

import UIKit
import SwiftyJSON

class FaeContactsCell: UITableViewCell {
    
    var imgAvatar: UIImageView!
    var lblUserName: UILabel!
    var lblUserSaying: UILabel!
    var bottomLine: UIView!
    var userId: Int = -1
    var lblStatus: UILabel!
    var friendStatus: FriendStatus = .accepted
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
        selectionStyle = .none
        loadFriendsCellContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        friendStatus = .accepted
        lblStatus.text = ""
    }
    
    func getFriendStatus(id: Int) {
        FaeUser().getUserRelation(String(id)) { (status: Int, message: Any?) in
            if status / 100 == 2 {
                let json = JSON(message!)
                let relation = Relations(json: json)
                if relation.blocked {   // blocked & blocked_by
                    self.friendStatus = .blocked
                    self.lblStatus.text = "Blocked"
                }
            } else {
                print("[get friend status fail] - \(status) \(message!)")
            }
        }
    }
    
    fileprivate func loadFriendsCellContent() {
        imgAvatar = UIImageView(frame: CGRect(x: 14, y: 12, width: 50, height: 50))
        imgAvatar.layer.cornerRadius = 25
        imgAvatar.contentMode = .scaleAspectFill
        imgAvatar.clipsToBounds = true
        addSubview(imgAvatar)
        
        lblUserName = UILabel()
        lblUserName.textAlignment = .left
        lblUserName.textColor = UIColor._898989()
        lblUserName.font = UIFont(name: "AvenirNext-Medium", size: 18)
        addSubview(lblUserName)
        addConstraintsWithFormat("H:|-84-[v0]-58-|", options: [], views: lblUserName)
        
        lblUserSaying = UILabel()
        lblUserSaying.textAlignment = .left
        lblUserSaying.textColor = UIColor._155155155()
        lblUserSaying.font = UIFont(name: "AvenirNext-Medium", size: 13)
        addSubview(lblUserSaying)
        addConstraintsWithFormat("H:|-84-[v0]-58-|", options: [], views: lblUserSaying)
        addConstraintsWithFormat("V:|-17-[v0(20)]-0-[v1(20)]", options: [], views: lblUserName, lblUserSaying)
        
        bottomLine = UIView()
        bottomLine.backgroundColor = UIColor._200199204()
        addSubview(bottomLine)
        addConstraintsWithFormat("H:|-73-[v0]-0-|", options: [], views: bottomLine)
        addConstraintsWithFormat("V:[v0(1)]-0-|", options: [], views: bottomLine)
        
        lblStatus = FaeLabel(CGRect(x: screenWidth - 65, y: 29, width: 50, height: 18), .right, .demiBold, 13, UIColor._155155155())
        addSubview(lblStatus)
    }
}
