//
//  IncomingMessage.swift
//  quickChat
//
//  Created by User on 6/7/16.
//  Copyright © 2016 User. All rights reserved.
//

import Foundation
import JSQMessagesViewController

// this class is used to create JSQMessage object from information in firebase, it can be message from current user
// or the other user who current user are chatting with.

class IncomingMessage {
    var collectionView : JSQMessagesCollectionViewCustom
    init(collectionView_ : JSQMessagesCollectionViewCustom) {
        collectionView = collectionView_
    }
    
    func createMessage(dictionary : NSDictionary) -> JSQMessage? {
        
        var message : JSQMessage?
        let type = dictionary["type"] as? String
        
        if type == "text" {
            //create text message
            message = createTextMessage(dictionary)
        }
        
        if type == "location" {
            //create locaiton message
            message = createLocationMessage(dictionary)
        }
        
        if type == "picture" {
            //create pitcute message
            message = createPictureMessage(dictionary)
        }
        
        if type == "audio" {
            message = createAudioMessage(dictionary)
        }
        
        if type == "sticker" {
            message = createStickerMessage(dictionary)
        }
        
        if type == "video" {
            message = createVideoMessage(dictionary)
        }
        
        if let mes = message {
            return mes
        } else {
            return nil
        }
    }
    
    func createTextMessage(item : NSDictionary) -> JSQMessage {
        
        let name = item["senderName"] as? String
        let userId = item["senderId"] as? String
        let date = dateFormatter().dateFromString((item["date"] as? String)!)
        let text = item["message"] as? String
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, text: text)
        
    }
    
    func createLocationMessage(item : NSDictionary) -> JSQMessage {
        
        let name = item["senderName"] as? String
        let userId = item["senderId"] as? String
        let date = dateFormatter().dateFromString((item["date"] as? String)!)
        
        let latitude = item["latitude"] as? Double
        let longitude = item["longitude"] as? Double
        
        var mediaItem = JSQLocationMediaItemCustom()
        
        //        mediaItem.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusFromUser(userId!)
        
        let location = CLLocation(latitude: latitude!, longitude: longitude!)
        
        //        mediaItem.setLocation(location) {
        //            //update collectionView
        //            self.snapShotFromData(item, result: { (image) in
        //                mediaItem.cachedMapImageView = UIImageView(image: image)
        //                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMaskToMediaView(mediaItem.cachedMapImageView, isOutgoing: mediaItem.appliesMediaViewMaskAsOutgoing)
        //                mediaItem.cachedMapImageView.contentMode = .ScaleAspectFill
        //                mediaItem.cachedMapImageView.clipsToBounds = true
        //                mediaItem.mediaView()
        //            })
        //            self.collectionView.reloadData()
        //        }
        
        self.snapShotFromData(item) { (image) in
            mediaItem = JSQLocationMediaItemCustom(location: location, snapImage: image)
            
        }
        
        
        //                let location = CLLocation(latitude: latitude!, longitude: longitude!)
        //
        //                let mediaItem = JSQGoogleLocationMediaItem(location: location)
        //
        //                mediaItem.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusFromUser(userId!)
        //
        ////                mediaItem.setLocation(location, withCompletionHandler: nil)
        //
        //                    //update collectionView
        //        //            self.collectionView.reloadData()
        //                imageFromData(item) { (image) in
        //                    mediaItem.setCachedImage(image!)
        //                    mediaItem.mediaView()
        //                    self.collectionView.reloadData()
        //                }
        
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    func returnOutgoingStatusFromUser(senderId : String) -> Bool {
        
        if senderId == user_id.stringValue {
            //outgoings
            return true
        } else {
            return false
        }
    }
    
    func createPictureMessage(item : NSDictionary) -> JSQMessage {
        let name = item["senderName"] as? String
        let userId = item["senderId"] as? String
        let date = dateFormatter().dateFromString((item["date"] as? String)!)
        
        let mediaItem = JSQPhotoMediaItemCustom(image: nil)
        
        mediaItem.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusFromUser(userId!)
        
        imageFromData(item) { (image) in
            mediaItem.image = image
            self.collectionView.reloadData()
        }
        
        return JSQMessage(senderId: userId!, senderDisplayName: name!, date: date, media: mediaItem)
    }
    
    
    // create incoming audio message
    func createAudioMessage(item : NSDictionary) -> JSQMessage {
        let name = item["senderName"] as? String
        let userId = item["senderId"] as? String
        let date = dateFormatter().dateFromString((item["date"] as? String)!)
        
        let isOutGoingMessage = userId! == user_id.stringValue
        let options: AVAudioSessionCategoryOptions = [AVAudioSessionCategoryOptions.DuckOthers, AVAudioSessionCategoryOptions.DefaultToSpeaker,AVAudioSessionCategoryOptions.AllowBluetooth]
        let font = UIFont(name: "AvenirNext-DemiBold", size: 16)
        let attribute = JSQAudioMediaViewAttributesCustom(
            playButtonImage: UIImage(named: isOutGoingMessage ? "playButton_white.png" : "playButton_red.png")!,
            pauseButtonImage: UIImage(named: isOutGoingMessage ? "pauseButton_white.png" : "pauseButton_red.png")!,
            labelFont: font!,
            showFractionalSecodns:false,
            backgroundColor: isOutGoingMessage ? UIColor.faeAppRedColor() : UIColor.whiteColor(),
            tintColor: isOutGoingMessage ? UIColor.whiteColor() : UIColor.faeAppRedColor(),
            controlInsets:UIEdgeInsetsMake(7, 12, 3, 14),
            controlPadding:5,
            audioCategory:"AVAudioSessionCategoryPlayback",
            audioCategoryOptions: options)
        let mediaItem = JSQAudioMediaItemCustom(audioViewAttributes : attribute)
        
        voiceFromData(item) { (voiceData) in
            mediaItem.audioData = voiceData
            self.collectionView.reloadData()
        }
        return JSQMessage(senderId: userId!, senderDisplayName: name!, date: date, media: mediaItem)
    }

    func createVideoMessage(item : NSDictionary) -> JSQMessage {
        let name = item["senderName"] as? String
        let userId = item["senderId"] as? String
        let date = dateFormatter().dateFromString((item["date"] as? String)!)
        let image = item["snapImage"] as? UIImage
        var duration = 0
        if item["videoDuration"] != nil {
            duration = item["videoDuration"] as! Int
        }
        let mediaItem = JSQVideoMediaItemCustom(fileURL:NSURL(),snapImage:image, duration:Int32(duration), isReadyToPlay:true)

        videoFromData(item) { (videoURL) in
            self.snapShotFromData(item) { (image) in
                mediaItem.fileURL = videoURL!
                mediaItem.snapImage = image
                self.collectionView.reloadData()
            }

        }
        return JSQMessage(senderId: userId!, senderDisplayName: name!, date: date, media: mediaItem)
    }

    func createStickerMessage(item : NSDictionary) -> JSQMessage {
        
        let name = item["senderName"] as? String
        let userId = item["senderId"] as? String
        let date = dateFormatter().dateFromString((item["date"] as? String)!)
        
        let mediaItem = JSQStickerMediaItem(image: nil)
        
        mediaItem.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusFromUser(userId!)
        
        imageFromData(item) { (image) in
            mediaItem.image = image
            self.collectionView.reloadData()
        }
        
        return JSQMessage(senderId: userId!, senderDisplayName: name!, date: date, media: mediaItem)
        
    }
    
    func imageFromData(item : NSDictionary, result : (image : UIImage?) -> Void) {
        var image : UIImage?
        
        let decodedData = NSData(base64EncodedString: (item["picture"] as? String)!, options: NSDataBase64DecodingOptions(rawValue : 0))
        
        image = UIImage(data: decodedData!)
        
        result(image: image)
    }
    
    func voiceFromData(item : NSDictionary, result : (voiceData : NSData?) -> Void) {
        let decodedData = NSData(base64EncodedString: (item["audio"] as? String)!, options: NSDataBase64DecodingOptions(rawValue : 0))
        
        result(voiceData: decodedData)
    }
    
    func videoFromData(item : NSDictionary, result : (videoData : NSURL?) -> Void) {
        let str = item["video"] as? String
        let filePath = self.documentsPathForFileName("/\(str!.substringWithRange(str!.endIndex.advancedBy(-33) ..< str!.endIndex.advancedBy(-1)))).mov")

        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(filePath) {
            let videoFileURL = NSURL(fileURLWithPath: filePath)
            result(videoData: videoFileURL)
        } else {
            if let decodedData = NSData(base64EncodedString: str!, options: NSDataBase64DecodingOptions(rawValue : 0)){
                if(str!.characters.count > 50){
                    decodedData.writeToFile(filePath, atomically:true)
                    
                    let videoFileURL = NSURL(fileURLWithPath: filePath)
                    result(videoData: videoFileURL)
                }
            }
        }
    }
    
    func documentsPathForFileName(name: String) -> String {
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        return documentsPath.stringByAppendingString(name)
    }
    
    func snapShotFromData(item : NSDictionary, result : (image : UIImage?) -> Void) {
        var image : UIImage?
        if let data = item["snapImage"] {
            let decodedData = NSData(base64EncodedString: (data as? String)!, options: NSDataBase64DecodingOptions(rawValue : 0))
            
            image = UIImage(data: decodedData!)
            
        }
        result(image: image)
    }
}
