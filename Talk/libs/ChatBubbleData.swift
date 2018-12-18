//
//  ChatBubbleData.swift
//  ChatBubble
//
//  Created by Sauvik Dolui on 8/21/15.
//  Copyright (c) 2015 Innofied Solution Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit // For using UIImage
import Realm
import RealmSwift

// 1. Type Enum
/**
Enum specifing the type

- Mine:     Chat message is outgoing
- Opponent: Chat message is incoming
*/
enum BubbleDataType: Int{
    case mine = 0
    case opponent
}

/// DataModel for maintaining the message data for a single chat bubble
class ChatBubbleData {
    // 2.Properties
    var id: Int?
    var accountName: String?
    var nickName: String?
    var text: String?
    var thumbnail: UIImage?
    var image: UIImage?
    var date: Date?
    var type: BubbleDataType
    var profilePhoto: UIImage?
    var hasProfilePhoto: Bool = false
    var unreadCnt: Int?
    var unreadLog: String?
    
    // 3. Initialization
    init(id: Int?, accountName: String?, nickName: String?, text: String?, image: UIImage?, thumbnail: UIImage?, date: Date? , type:BubbleDataType = .mine, unreadCnt: Int? = -1, unreadLog: String? = "") {
        // Default type is Mine
        self.id = id
        self.accountName = accountName
        self.nickName = nickName
        self.text = text
        self.thumbnail = thumbnail
        self.image = image
        self.date = date
        self.type = type
        self.profilePhoto = getProfileImage(accountName!)
        self.unreadCnt = unreadCnt;
        self.unreadLog = unreadLog;
    }
    
    func getProfileImage(_ accountName:String)->UIImage
    {
        if let profileImage = (UIApplication.shared.delegate as! AppDelegate).getProfileImage(accountName)
        {
            hasProfilePhoto = true
            return profileImage
        }
        else
        {
            var nameList:[String];
            if( self.nickName?.length == 0 )
            {
                nameList = self.accountName!.components(separatedBy: ".");
            }
            else
            {
                nameList = self.nickName!.components(separatedBy: " ");
            }
            
            var initial = "";
            if( nameList.count > 1 )
            {
                let firstName = nameList[0];
                let lastName = nameList[1];
                initial = "\(firstName[firstName.startIndex]).\(lastName[lastName.startIndex])";
            }
            else
            {
                let fullName = nameList[0];
                let index = fullName.index(fullName.startIndex, offsetBy: 2)
                initial = "\(fullName[index])";
            }
            
            let profileImage = UIImage.InitialImage(text: initial.uppercased(), backgroundColor: UIColor.almondColor(), circular: true)
            
            hasProfilePhoto = false
            
            return profileImage
        }
        //===========================================================================
    }
    
    public func getCreatedDate() -> String
    {
        var dateString:String;
        let formatter = DateFormatter();
        formatter.dateFormat = "HH:mm MM/dd/yyyy";
        
        if( self.id == -1 )
        {
            dateString = formatter.string(from: self.date!);
        }
        else
        {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate;
            let createdDate = self.date?.add(hours: appDelegate.getOffsetHour());
            dateString = formatter.string(from: createdDate!);
        }
    
        return dateString;
    }
    
    public func getUnreadCnt() -> String
    {
        if( self.id == -1 )
        {
            return "\u{1F4A8}";
        }
        else if( self.unreadCnt! < 1 )
        {
            return "";
        }
        else
        {
            return String(format:"%d",self.unreadCnt!);
        }
    }
}
