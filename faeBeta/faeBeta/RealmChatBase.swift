//
//  RealmChatBase.swift
//  faeBeta
//
//  Created by User on 04/04/2017.
//  Copyright © 2017 fae. All rights reserved.
//

import Foundation
import RealmSwift


class RealmMessage: Object {
    //messageID's format: senderID_date
    dynamic var messageID : String = ""
    dynamic var withUserID : String = ""
    dynamic var senderID : String = ""
    dynamic var senderName : String = ""
    dynamic var date : String = ""
    dynamic var message : String = ""
    dynamic var delivered = false
    dynamic var hasTimeStamp = false
    dynamic var data : NSData? = nil
    dynamic var type : String = ""
    dynamic var status: String = ""
    dynamic var snapImage : NSData? = nil
    let longitude = RealmOptional<Float>()
    let latitude = RealmOptional<Float>()
    //dynamic var latitude : String? = nil
    
    // int cannot be optional
    let videoDuration = RealmOptional<Int>()
    dynamic var isHeartSticker : Bool = false
    override static func indexedProperties() -> [String] {
        return ["date"].reversed()
    }
    
    //For chat pin we may need some backlink
    override static func primaryKey() -> String? {
        return "messageID"
    }
}

class RealmRecent: Object {
    dynamic var withUserID : String = ""
    dynamic var withUserNickName : String = ""
    dynamic var date = NSDate()
    //dynamic var avatar : NSData? = nil
    dynamic var message : String = ""
    dynamic var unread : Int = 0
    
    override static func indexedProperties() -> [String] {
        return ["date"].reversed()
    }
    
    override static func primaryKey() -> String? {
        return "withUserID"
    }
}

class RealmChat {
    static func sendMessage(message : RealmMessage, completion : () -> ()){
        let realm = try! Realm()
        try! realm.write{
            realm.add(message)
            print("add message")
        }
    }
    
    static func updateRecent(recents : NSArray) {
        let realm = try! Realm()
        for message in recents{
            let recent = RealmRecent()
            //print(type(of: (message as! NSDictionary)["with_user_id"]!))
            let messageNSDict = message as! NSDictionary
            recent.withUserID =  String(messageNSDict["with_user_id"]! as! Int)
            recent.withUserNickName = messageNSDict["with_nick_name"]! as? String ?? messageNSDict["with_user_name"]! as! String
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar(identifier: .gregorian)
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
            let date = dateFormatter.date(from: messageNSDict["last_message_timestamp"] as! String)
            recent.date = date! as NSDate
            recent.message = messageNSDict["last_message"]! as! String
            recent.unread = messageNSDict["unread_count"]! as! Int
            try! realm.write{
                realm.add(recent, update: true)
                print("update recent")
            }
        }
    }
    
    static func receiveMessage(message : RealmMessage) {
        let realm = try! Realm()
        try! realm.write{
            realm.add(message);
        }
    }
    
    static func receiveMessage(message : NSDictionary, withUserID: String) {
        let realm = try! Realm()
        let timeStr = message["date"]! as! String
        if(realm.objects(RealmMessage.self).filter("messageID = '\(withUserID)_\(timeStr)'").first != nil){
            return
        }
        let message = RealmMessage()
        message.withUserID = withUserID
        message.date = timeStr
        message.delivered = true
        message.senderID = message["senderId"]! as! String
        message.type = message["type"]! as! String
        message.senderName = message["senderName"]! as! String
        message.hasTimeStamp = message["hasTimeStamp"]! as! Bool
        //message.hasTimeStamp =
//        realm.objects(RealmMessage.self).filter(
//        try! realm.write{
//            realm.add();
//        }
    }
    
    static func dateConverter(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmssSS"
        return dateFormatter.string(from: date)
    }
    
    static func dateConverter(str: String) -> Date{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddhhmmssSS"
        return dateFormatter.date(from: str)!
    }
    
    static func fetchMessageWith(userID: Int, numberOfItem: Int, offset: Int) -> [RealmMessage] {
        return []
    }
    
    static func removeRecentWith(recentItem: RealmRecent) {
        let realm = try! Realm()
        try! realm.write {
            let withUserID = recentItem.withUserID
            realm.delete(realm.objects(RealmMessage.self).filter("withUserID = '\(withUserID)'"))
            realm.delete(recentItem)
        }
    }
    
    static func cleanDatabase() {
        
    }
    
    static func printDatabase(object : Object, numerOfItem : Int, offset: Int) {
    }
    
    static func addWithUser(withUser : RealmUser){
        let realm  = try! Realm()
        try! realm.write{
            realm.add(withUser)
            print("add user")
        }
    }
    
}

