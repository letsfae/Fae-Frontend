//
//  FaeLabel.swift
//  faeBeta
//
//  Created by Yue Shen on 9/1/17.
//  Copyright © 2017 fae. All rights reserved.
//

import UIKit

enum FaeLabelFontType: String {
    case regular = "Regular"
    case medium = "Medium"
    case demiBold = "DemiBold"
    case bold = "Bold"
}

class FaeLabel: UILabel {
    
    init(_ frame: CGRect = .zero, _ align: NSTextAlignment = .left, _ fontType: FaeLabelFontType = .regular, _ size: CGFloat, _ color: UIColor = UIColor._898989()) {
        super.init(frame: frame)
        self.textAlignment = align
        self.font = UIFont(name: "AvenirNext-\(fontType)", size: size)
        self.textColor = color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
