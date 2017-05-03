//
//  PDLoadMedias.swift
//  faeBeta
//
//  Created by Yue on 12/13/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import SwiftyJSON
import RealmSwift
import SDWebImage
import IDMPhotoBrowser

extension PinDetailViewController {
    func loadMedias() {
        imgMediaArr.removeAll()
        for subview in scrollViewMedia.subviews {
            subview.removeFromSuperview()
        }
        for index in 0..<fileIdArray.count {
            var offset = 105
            var width: CGFloat = 95
            if enterMode == .collections {
                offset = 170
                width = 160
            }
            
            let imageView = UIImageView(frame: CGRect(x: CGFloat(offset*index), y: 0, width: width, height: width))
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = true
            imageView.layer.cornerRadius = 13.5
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.openThisMedia(_:)))
            imageView.addGestureRecognizer(tapRecognizer)
            imgMediaArr.append(imageView)
            scrollViewMedia.addSubview(imageView)
            
            let realm = try! Realm()
            if let mediaRealm = realm.objects(FileObject.self).filter("fileId == \(self.fileIdArray[index]) AND picture != nil").first {
                imageView.image = UIImage.sd_image(with: mediaRealm.picture as Data!)
            } else {
                let fileURL = "\(baseURL)/files/\(self.fileIdArray[index])/data"
                imageView.sd_setImage(with: URL(string: fileURL), placeholderImage: nil, options: [.retryFailed, .refreshCached], completed: { (image, error, SDImageCacheType, imageURL) in
                    if image == nil {
                        return
                    }
                    let mediaImage = FileObject()
                    mediaImage.fileId = self.fileIdArray[index]
                    mediaImage.picture = UIImageJPEGRepresentation(image!, 0.5) as NSData?
                    try! realm.write {
                        realm.add(mediaImage)
                    }
                })
            }
        }
        if self.enterMode == .collections {
            self.scrollViewMedia.contentSize = CGSize(width: fileIdArray.count * 160 - 10, height: 160)
        } else {
            self.scrollViewMedia.contentSize = CGSize(width: fileIdArray.count * 105 - 10, height: 95)
        }
        
    }
    
    func openThisMedia(_ sender: UIGestureRecognizer) {
        let imageView = sender.view as! UIImageView
        if let image = imageView.image {
            let photos = IDMPhoto.photos(withImages: [image])
            let browser = IDMPhotoBrowser(photos: photos)
            self.present(browser!, animated: true, completion: nil)
        }
    }
    
    func zoomMedia(_ type: MediaMode) {
        var width = 95
        let space = 10
        if type == .large {
            width = 160
        }
        for index in 0...imgMediaArr.count-1 {
            UIView.animate(withDuration: 0.5, animations: {
                self.imgMediaArr[index].frame.origin.x = CGFloat((width+space)*index)
                self.imgMediaArr[index].frame.size.width = CGFloat(width)
                self.imgMediaArr[index].frame.size.height = CGFloat(width)
                self.scrollViewMedia.frame.size.height = CGFloat(width)
            })
        }
        self.scrollViewMedia.contentSize = CGSize(width: CGFloat(fileIdArray.count * (width+space) - space), height: CGFloat(width))
    }
}
