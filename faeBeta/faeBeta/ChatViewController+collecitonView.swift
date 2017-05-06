//
//  ChatViewController+collecitonView.swift
//  faeBeta
//
//  Created by YAYUAN SHI on 10/3/16.
//  Copyright © 2016 fae. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import IDMPhotoBrowser
import Photos
import AVKit
import AVFoundation

extension ChatViewController {
    // MARK: - collection view delegate
    
    // JSQMessage delegate not only should handle chat bubble itself, it should handle photoQuickSelect cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCellCustom
        
        let data = messages[indexPath.row]
        
        if data.senderId == user_id.stringValue {
            cell.textView?.textColor = UIColor.white
            cell.textView?.font = UIFont(name: "Avenir Next", size: 16)
        } else {
            cell.textView?.textColor = UIColor(red: 107.0/255.0, green: 105.0/255.0, blue: 105.0/255.0, alpha: 1.0)
            cell.textView?.font = UIFont(name: "Avenir Next", size: 16)
        }
        cell.avatarImageView.layer.cornerRadius = 17.5
        cell.avatarImageView.contentMode = .scaleAspectFill
        cell.avatarImageView.layer.masksToBounds = true
        let object = objects[indexPath.row]
        switch (object["type"] as! String) {
            case "text":
                cell.contentType = Text
                break
            case "picture":
                cell.contentType = Picture
                break
            case "sticker":
                cell.contentType = Sticker
                break
            case "location":
                cell.contentType = Location
                break
            case "audio":
                cell.contentType = Audio
                break
            case "video":
                cell.contentType = Video
            // if it's a unknow message type, display a unknow message type
            default:
                cell.contentType = Text
                break
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == self.collectionView && indexPath.row == messages.count - 1{
            clearRecentCounter(chat_id)
            let object = objects[indexPath.row]

            //Do not allow user to send two heart continously
            let userId = object["senderId"] as? String
            let isOutGoingMessage = userId! == user_id.stringValue
            

            if object["type"] as! String == "sticker" && object["isHeartSticker"] != nil && object["isHeartSticker"] as! Bool == true && isOutGoingMessage{
                userJustSentHeart = true
            }else{
                userJustSentHeart = false
            }
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionViewCustom!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        return messages[indexPath.row]
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    //this delegate is used to tell which bubble image should be used on current message
    override func collectionView(_ collectionView: JSQMessagesCollectionViewCustom!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        
        if data.senderId == user_id.stringValue {
            if data.isMediaMessage {
                outgoingBubble = JSQMessagesBubbleImageFactoryCustom(bubble: UIImage(named: "avatarPlaceholder"), capInsets: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)).outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleRed())
            }
            return outgoingBubble
        } else {
            return incomingBubble
        }
    }
    
    //this is used to edit top label of every cell
    override func collectionView(_ collectionView: JSQMessagesCollectionViewCustom!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let object = objects[indexPath.row]
        if object["hasTimeStamp"] as! Bool {
            let message = messages[indexPath.item]
            
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        return nil
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionViewCustom!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayoutCustom!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        let object = objects[indexPath.row]
        if object["hasTimeStamp"] as! Bool  {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionViewCustom!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayoutCustom!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        return 0.0
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionViewCustom!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        let message = objects[indexPath.row]
        
        let status = message["status"] as! String
        
        if indexPath.row == messages.count - 1 {
            return NSAttributedString(string: status)
        } else {
            return NSAttributedString(string: "")
        }
        
    }
    // bind avatar image
    override func collectionView(_ collectionView: JSQMessagesCollectionViewCustom!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = messages[indexPath.row]
        let avatar = avatarDictionary!.object(forKey: message.senderId) as! JSQMessageAvatarImageDataSource
        
        return avatar
    }
  
    
    //taped bubble
    // function when user tap the bubble, like image, location
    override func collectionView(_ collectionView: JSQMessagesCollectionViewCustom!, didTapMessageBubbleAt indexPath: IndexPath!) {
        
        closeToolbarContentView()
        
        let object = objects[indexPath.row]
        
        if object["type"] as! String == "picture" || object["type"] as! String == "gif" {
            
            let message = messages[indexPath.row]
            
            if let mediaItem = message.media as? JSQPhotoMediaItemCustom{
                let photos = IDMPhoto.photos(withImages: [mediaItem.image])
                let browser = IDMPhotoBrowser(photos: photos)
                
                self.present(browser!, animated: true, completion: nil)
            }
        }
        
        if object["type"] as! String == "location" {
            
            let message = messages[indexPath.row]
            
            if let mediaItem = message.media as? JSQLocationMediaItemCustom {
                
                let vc = UIStoryboard(name: "Chat", bundle: nil) .instantiateViewController(withIdentifier: "ChatMapViewController")as! ChatMapViewController
                
                vc.address1 = mediaItem.address1
                vc.address2 = mediaItem.address2
                vc.address3 = mediaItem.address3

                vc.chatLatitude = mediaItem.coordinate.latitude
                vc.chatLongitude = mediaItem.coordinate.longitude
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        if object["type"] as! String == "video" {
            let message = messages[indexPath.row]
            
            if let mediaItem = message.media as? JSQVideoMediaItemCustom
            {
                if let dataUrl = mediaItem.fileURL {
                    let player = AVPlayer(url:dataUrl)
                    let playerController = AVPlayerViewController()
                    playerController.player = player
                    self.present(playerController, animated: true) {
                        player.play()
                    }
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        var returnValue = false
        
        let object = objects[indexPath.row]
        
        if object["type"] as! String == "picture" || object["type"] as! String == "text" || object["type"] as! String == "sticker"{
            returnValue = true
        }
        self.selectedIndexPathForMenu = indexPath;
        return returnValue
    }

}
