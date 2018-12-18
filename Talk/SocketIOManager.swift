//
//  SocketIOManager.swift
//  SocketChat
//
//  Created by Kevin Forbes on 2016-12-29.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()
    var socket: SocketIOClient = SocketIOClient(socketURL: URL(string: "http://yourkpnaddress:3000")!)
    
    override init() {
        super.init()
    }
    
    func establishConnection(){
        socket.connect()
        
        socket.off("connect")
        socket.on("connect") {(dataArray, socketAck) -> Void in
            
            NotificationCenter.default.post(name: Notification.Name("onConnectedNotification"), object: nil)
        }
    }
    
    func closeConnection(){
        socket.disconnect()
        
        socket.off("connect")
    }
    
    func isConnected() -> Bool{
        return socket.status == .connected;
    
    }
    
    func connectToServerWithNickname(_ nickname:String,_ accountName:String, completionHandler: @escaping (_ roomList: [[String: AnyObject]]?) -> Void )  {
        socket.emit("connectUser", nickname, accountName)
        
        socket.on("userList") {(dataArray, ack) -> Void in
            completionHandler(dataArray[0] as? [[String: AnyObject]])
        }
        
    }
    
    func joinRoom(_ nickname:String,_ accountName:String,_ roomName:String,_ roomSPID:String,_ memberList:[String])  {
        socket.emit("joinRoom", nickname, accountName, roomName, roomSPID, memberList, "ios")
    }
    
    func leaveRoom(_ nickname:String,_ accountName:String,_ roomName:String,_ roomSPID:String)  {
        socket.emit("leaveRoom", nickname, accountName, roomName, roomSPID, "ios")
    }
    
    func exitChatWithNickName(_ nickname:String, completionHandler: @escaping () -> Void){
        socket.emit("exitUser", nickname)
        completionHandler()
    }
    
    func sendMessage(message: String, withNickName nickname: String){
        socket.emit("chatMessage", nickname, message)
    }
    
    func sendFile(fileData: String, withNickName nickname: String){
        socket.emit("sendFile", nickname, fileData )
    }
    
    func inviteUser(roomSPID: String, accountName: String){
        socket.emit("inviteUser", roomSPID, accountName);
    }
    
    func getChatMessage(_ completionHandler: @escaping (_ messageInfo: [String: AnyObject]) -> Void) {
        socket.off("newChatMessage")
        socket.on("newChatMessage") { (dataArray, socketAck) -> Void in
            var messageDictionary = [String: AnyObject]()
            messageDictionary["id"] = dataArray[0] as AnyObject
            messageDictionary["accountName"] = dataArray[1] as AnyObject
            messageDictionary["nickName"] = dataArray[2] as AnyObject
            messageDictionary["message"] = dataArray[3] as AnyObject
            messageDictionary["date"] = dataArray[4] as AnyObject
            messageDictionary["msgType"] = "SMS" as AnyObject
            
            completionHandler(messageDictionary)
        }
    }
    
    func getSentFile(_ completionHandler: @escaping (_ messageInfo: [String: AnyObject]) -> Void) {
        socket.off("onSentFile")
        socket.on("onSentFile") { (dataArray, socketAck) -> Void in
            var messageDictionary = [String: AnyObject]()
            messageDictionary["id"] = dataArray[0] as AnyObject
            messageDictionary["accountName"] = dataArray[1] as AnyObject
            messageDictionary["nickName"] = dataArray[2] as AnyObject
            messageDictionary["base64Encoding"] = dataArray[3] as AnyObject
            messageDictionary["date"] = dataArray[4] as AnyObject
            messageDictionary["msgType"] = "MMS" as AnyObject
            
            completionHandler(messageDictionary)
        }
    }
    
    func listenForOtherMessages()
    {
        socket.off("onJoinedRoom")
        socket.on("onJoinedRoom") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: Notification.Name("onJoinedRoomNotification"), object: dataArray[0] as! [String: AnyObject])
        }
        
        socket.off("onLeavedRoom")
        socket.on("onLeavedRoom") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: Notification.Name("onLeavedRoomNotification"), object: dataArray[0] as! [String: AnyObject])
        }
        
        socket.off("userTypingUpdate")
        socket.on("userTypingUpdate") { (dataArray, socketAck) -> Void in
            NotificationCenter.default.post(name: Notification.Name("userTypingNotification"), object: dataArray[0] as? [String: AnyObject])
        }
        
        socket.off("onSuccessChat")
        socket.on("onSuccessChat") { (dataArray, socketAck) -> Void in

            NotificationCenter.default.post(name: Notification.Name("successChatNotification"), object: dataArray[0] as? Int)
        }
        
        socket.off("onSuccessInviteUser")
        socket.on("onSuccessInviteUser") { (dataArray, socketAck) -> Void in
            
            NotificationCenter.default.post(name: Notification.Name("successInviteUserNotification"), object: dataArray[0] as? String)
        }
    }
    
    func removeListenForOtherMessages()
    {
        socket.off("connect")
        socket.off("disconnect")
        socket.off("onJoinedRoom");
        socket.off("onLeavedRoom");
        socket.off("userTypingUpdate");
        socket.off("onSuccessChat");
        socket.off("onSuccessInviteUser");
    }
    
    func sendStartTypingMessage(nickname: String) {
        socket.emit("startType", nickname)
    }
    
    func sendStopTypingMessage(nickname: String) {
        socket.emit("stopType", nickname)
    }
}
