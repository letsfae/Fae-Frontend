//
//  JSQStickerMediaItem.swift
//  quickChat
//
//  Created by User on 7/24/16.
//  Copyright © 2016 User. All rights reserved.
//

import Foundation
import JSQMessagesViewController

//this is a class that subclass JSQPhotoMediaItem, to show sticker in a chat bubble.
// it overrided the size of chat bubble
class JSQStickerMediaItem: JSQPhotoMediaItem {
    //inheritance from JSQPhoto
    var imgCached: UIImageView!
    var sizeCustomize : CGSize!
    var floatHeartButtonTopOffset: CGFloat = 5
    
    override func mediaView() -> UIView! {
        if self.image == nil {
            return nil
        }
        if sizeCustomize != nil {
            let imageSize = self.mediaViewDisplaySize()
            let view = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            let imageView = UIImageView(image: self.image)
            imageView.frame = CGRect(x: 0, y: floatHeartButtonTopOffset, width: imageSize.width, height: imageSize.height - floatHeartButtonTopOffset * 2)
            imageView.contentMode = .scaleAspectFit
            view.addSubview(imageView)
            self.imgCached = view 
        } else {
            let imageSize = self.mediaViewDisplaySize()
            let imageView = UIImageView(image: self.image)
            imageView.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
            imageView.contentMode = .scaleAspectFit
            self.imgCached = imageView
        }
        return imgCached
    }
    
    // overridde the photo size to the stick size
    override func mediaViewDisplaySize() -> CGSize {
        return sizeCustomize != nil ? CGSize(width: sizeCustomize.width, height: sizeCustomize.height + floatHeartButtonTopOffset * 2) : CGSize(width: 120, height: 90)
    }
    
}
