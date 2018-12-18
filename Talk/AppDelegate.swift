//
//  AppDelegate.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import UserNotifications
import Realm
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var accountName: String?
    var appIsStarting: Bool = true;
    var deviceToken: String?
    
    var badgeMap:[String:Int]?
    
    var offsetHour:Int = 0;
    
    var newRoomData: [[String:AnyObject]]!
    
    let OFFSET_HOUR_SERVER:Int = -4;
    var realm:Realm? = nil;
    
    enum APPSTATUS : String
    {
        case suspend = "SUSPEND", background = "BACKGROUND", inactive = "INACTIVE", active = "ACTIVE"
    }
    
    // MARK:- ======== For Push Notification ================
    
    func getNotificationOption()->UNAuthorizationOptions
    {
        let preferences = UserDefaults.standard
        if( preferences.bool(forKey: "settingSound") == false)
        {
            return [.alert, .badge];
        }
        else
        {
            return [.alert, .sound, .badge];
        }
    }
    
    func getNotificationOption()->UNNotificationPresentationOptions
    {
        let preferences = UserDefaults.standard
        if( preferences.bool(forKey: "settingSound") == false)
        {
            return [.alert, .badge];
        }
        else
        {
            return [.alert, .sound, .badge];
        }
    }
    
    func registerForPushNotifications(_ accountName:String){
        
        self.accountName = accountName;
        
        UNUserNotificationCenter.current().requestAuthorization(options: getNotificationOption()) { (granted, error) in
            print("Permission granted: \(granted)")
            
            guard granted else {
                
                let alertController = UIAlertController (title: "Permission Error", message: "You need to allow for Push Notification in order to use Kiss Talk.", preferredStyle: .alert)
                
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: "\(UIApplicationOpenSettingsURLString)KissTalk") else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)") // Prints true
                        })
                    }
                }
                alertController.addAction(settingsAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                alertController.addAction(cancelAction)
                
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                
                return
                
            }
            self.getNotificationSettings();
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK:-
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        self.deviceToken = tokenParts.joined()
        print("Device Token: \(self.deviceToken!)")
        
        saveDeviceToken(self.accountName!, self.deviceToken!);
        updateStatus(APPSTATUS.active);
        
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)");
        
    }
    
    private func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings)
    {
        application.registerForRemoteNotifications()
    }
    
    // --------------------------------------------------

    func saveDeviceToken(_ accountName:String, _ deviceToken:String)
    {
        let params = ["accountName":accountName, "deviceToken":deviceToken, "deviceOs":"ios"] as [String : String];
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/updateDeviceToken.php", postData: params) { (responseResult, error) -> Void in
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed save device");
                
                if let resutlData = responseResult
                {
                    //To get rid of optional
                    //print(resutlData)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        let result = resutlData["result"] as! Bool;
                        let resultCode = resutlData["code"] as! String;
                        
                        if( result == true )
                        {
                            /*
                            let msg = resutlData["msg"] as! String;
                            let alertController = UIAlertController(title: "Info", message: msg, preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "Close", style: .default);
                            alertController.addAction(OKAction)
                            
                            self.window?.rootViewController?.present(alertController, animated: true);
                            */
                        }
                        else
                        {
                            if( resultCode == "205" )
                            {
                                // TO DO
                                let msg = resutlData["msg"] as! String;
                                let alertController = UIAlertController(title: "Alert", message: msg, preferredStyle: .alert)
                                let OKAction = UIAlertAction(title: "Close", style: .default);
                                alertController.addAction(OKAction)
                                
                                self.window?.rootViewController?.present(alertController, animated: true);
                            }
                            else
                            {
                                let msg = resutlData["msg"] as! String;
                                let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                                let OKAction = UIAlertAction(title: "Close", style: .default);
                                alertController.addAction(OKAction)
                                
                                self.window?.rootViewController?.present(alertController, animated: true);
                            }
                            
                        }
                    })
                }
            }
        }
        
        task.resume();
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let preferences = UserDefaults.standard
        
        if(( preferences.object(forKey: "settingSound") ) == nil)
        {
            preferences.set(true, forKey: "settingSound")
        }
        
        offsetHour = TimeZone.current.secondsFromGMT()/3600;
        
        if( TimeZone.current.isDaylightSavingTime() )
        {
            offsetHour -= 1;
        }
        
        migrationRealm();
        
        realm = try! Realm();
        
        return true
    }
    
    func migrationRealm(){
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 1) {
                    // The enumerateObjects(ofType:_:) method iterates
                    // over every Person object stored in the Realm file
                    migration.enumerateObjects(ofType: Participant.className()) { oldObject, newObject in
                        // combine name fields into a single field
                        let samaccountname = oldObject!["samaccountname"] as! String
                        let roomID = oldObject!["roomID"] as! String
                        let mobile = oldObject!["mobile"] as! String
                        let displayname = oldObject!["displayname"] as! String
                        let thumbnailphoto = oldObject!["thumbnailphoto"] as! String

                        newObject!["samaccountname"] = samaccountname
                        newObject!["roomID"] = roomID
                        newObject!["mobile"] = mobile
                        newObject!["displayname"] = displayname
                        newObject!["thumbnailphoto"] = thumbnailphoto
                        newObject!["department"] = ""
                        newObject!["title"] = ""
                        newObject!["ext"] = ""
                    }
                }
        })
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        //SocketIOManager.sharedInstance.closeConnection()
        
        self.appIsStarting = false;
        
        updateStatus(APPSTATUS.inactive);
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //SocketIOManager.sharedInstance.removeListenForOtherMessages()
        self.appIsStarting = false;
        updateStatus(APPSTATUS.background);
        SocketIOManager.sharedInstance.closeConnection()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        //SocketIOManager.sharedInstance.listenForOtherMessages()
        self.appIsStarting = true;
        updateStatus(APPSTATUS.active);
        
        if( realm == nil )
        {
            registerForPushNotifications(self.accountName!)
        }
    }

    
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.appIsStarting = true;
        updateStatus(APPSTATUS.active);
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        SocketIOManager.sharedInstance.closeConnection()
        
        if( self.deviceToken == nil )
        {
            return;
        }
        
        let params = ["deviceToken":self.deviceToken!, "status":APPSTATUS.suspend.rawValue, "accountName":self.accountName] as! [String : String];
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/updateStatus.php", postData: params) { (responseResult, error) -> Void in
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                //print("completed update status");
            }
            semaphore.signal()
        }
        
        task.resume();
        _ = semaphore.wait(timeout: .distantFuture)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("################ didReceiveRemoteNotification ################");
        
        if let msgType = userInfo["categoryIdentifier"] as? String
        {
            if( msgType == "updateRoom" )
            {
                self.loadRoomWithMember(accountName: self.accountName!);
            }
        }
    }
    
    func updateStatus(_ status:APPSTATUS)
    {
        if( self.deviceToken == nil )
        {
            return;
        }
        
        let params = ["deviceToken":self.deviceToken!, "status":status.rawValue, "accountName":self.accountName] as! [String : String];
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/updateStatus.php", postData: params) { (responseResult, error) -> Void in
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                //print("completed update status");
            }
            semaphore.signal()
        }
        
        task.resume();
        _ = semaphore.wait(timeout: .distantFuture)
    }

    func getOffsetHour()->Int
    {
        return OFFSET_HOUR_SERVER - self.offsetHour;
    }
    
    func loadRoomWithMember(accountName:String)
    {
        let params = ["API_ID":"TALK_GETROOM", "accountName":accountName, "isIncludedMember":"true"] as [String : String]
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourapiserveraddress/CallAPI.php", postData: params) { (responseResult, error) -> Void in
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                if let resultData = responseResult
                {                    
                    DispatchQueue.background(delay:1.0, background: {
                        
                        print("backgroundThread Start");
                        
                        let result = resultData["result"] as! Bool;
                        
                        if( result == true )
                        {
                            self.newRoomData = resultData["data"] as! [[String:AnyObject]];
                            self.updateMemberTable();
                        }
                    }, completion: {
                        
                        print("backgroundThread Completion");
                    })
                }
            }
        }
        
        task.resume();
    }
    
    func updateMemberTable()
    {
        try! realm?.write {
            realm?.deleteAll();
        }
        
        for( _, room ) in self.newRoomData.enumerated()
        {
            let roomID:String = room["ID"] as! String;
            let memberList:[[String:AnyObject]] = room["members"] as! [[String:AnyObject]];
            
            for (_, member) in memberList.enumerated()
            {
                let participant = Participant()
                participant.samaccountname = member["samaccountname"] as! String
                participant.roomID = roomID
                
                if let mobile = member["mobile"] as? String{
                    participant.mobile = mobile;
                } else {
                    participant.mobile = "";
                }
                
                if let displayname = member["displayname"] as? String {
                    participant.displayname = displayname;
                } else {
                    participant.displayname = "";
                }
                
                if let thumbnailphoto = member["thumbnailphoto"] as? String{
                    participant.thumbnailphoto = thumbnailphoto;
                } else {
                    participant.thumbnailphoto = "";
                }
                
                guard let _:String = member["samaccountname"] as? String else
                {
                    continue
                }
                
                try! realm?.write {
                    realm?.add(participant);
                }
            }
        }
        
        RoomsViewController.isNeedUpdateRoomInfo = true;
        ChatViewController.isNeedUpdateMemberInfo = true;
        MembersViewController.isNeedUpdateMemberInfo = true;
        
        if( appIsStarting )
        {
            if let window = UIApplication.shared.delegate?.window {
                let rootVC = window!.rootViewController
                if(rootVC is UINavigationController)
                {
                    if( (rootVC as! UINavigationController).visibleViewController is RoomsViewController )
                    {
                        let roomVC:RoomsViewController = (rootVC as! UINavigationController).visibleViewController as! RoomsViewController;
                        roomVC.updateNewRoomList();
                        RoomsViewController.isNeedUpdateRoomInfo = false;
                    }
                    else if( (rootVC as! UINavigationController).visibleViewController is ChatViewController )
                    {
                        let chatVC:ChatViewController = (rootVC as! UINavigationController).visibleViewController as! ChatViewController;
                        chatVC.updateNewMemberList();
                        ChatViewController.isNeedUpdateMemberInfo = false;
                    }
                    else if( (rootVC as! UINavigationController).visibleViewController is MembersViewController )
                    {
                        let memberVC:MembersViewController = (rootVC as! UINavigationController).visibleViewController as! MembersViewController;
                        memberVC.updateNewMemberList();
                        MembersViewController.isNeedUpdateMemberInfo = false;
                    }
                }
            }
        }
    }
    
    public func updateProfilePhoto(accountName:String, base64Photo:String)
    {
        let memberResults:Results<Participant> = realm!.objects(Participant.self).filter("samaccountname = '\(accountName)'");
        print(memberResults)
        for( _, member ) in memberResults.enumerated()
        {
            try! realm?.write {
                member.thumbnailphoto = base64Photo
            }
        }
        
        let memberResults1:Results<Participant> = realm!.objects(Participant.self).filter("samaccountname = '\(accountName)'");
        print(memberResults1)
    }
    
    public func getProfileImage(_ accountName:String)->UIImage?
    {
        //=============== update thumbnailphoto for member from Realm ===============
        let memberResults:Results<Participant> = realm!.objects(Participant.self).filter("samaccountname = '\(accountName)'");
        
        let foundMember = memberResults.first;
        
        if foundMember != nil && foundMember?.thumbnailphoto.isEmpty == false
        {
            let foundMember:Participant = memberResults[0] as Participant;
            let decodedData = NSData(base64Encoded: foundMember.thumbnailphoto, options: NSData.Base64DecodingOptions(rawValue: 0))
            let profileImage:UIImage = UIImage(data: decodedData! as Data)!
            
            return profileImage;
        }
        else
        {
            return nil;
        }
        //===========================================================================
    }
    
    public func addMember(roomID:String, member:[String:AnyObject])
    {
        let memberAccountName = member["samaccountname"] as! String;
        let memberResults:Results<Participant> = realm!.objects(Participant.self).filter("roomID = %@ AND samaccountname = %@", roomID, memberAccountName);
        print(memberResults);
        
        if let foundMember = memberResults.first
        {
            try! realm?.write {
                foundMember.mobile = member["mobile"] as! String;
                foundMember.displayname = member["displayname"] as! String;
                foundMember.department = member["department"] as! String;
                foundMember.title = member["title"] as! String;
                foundMember.ext = member["ext"] as! String;
                
                if let thumbnailphoto = member["thumbnailphoto"] as? String {
                    if( thumbnailphoto.isEmpty == false ){
                        foundMember.thumbnailphoto = thumbnailphoto;
                    }
                }
            }
        }
        else
        {
            let participant = Participant()
            participant.samaccountname = member["samaccountname"] as! String
            participant.roomID = roomID
            
            if let mobile = member["mobile"] as? String{
                participant.mobile = mobile;
            } else {
                participant.mobile = "";
            }
            
            if let displayname = member["displayname"] as? String {
                participant.displayname = displayname;
            } else {
                participant.displayname = "";
            }
            
            if let thumbnailphoto = member["thumbnailphoto"] as? String{
                participant.thumbnailphoto = thumbnailphoto;
            } else {
                participant.thumbnailphoto = "";
            }
            
            if let department = member["department"] as? String{
                participant.department = department;
            } else {
                participant.department = "";
            }
            
            if let title = member["title"] as? String{
                participant.title = title;
            } else {
                participant.title = "";
            }
            
            if let ext = member["ext"] as? String{
                participant.ext = ext;
            } else {
                participant.ext = "";
            }
            
            try! realm?.write {
                realm?.add(participant);
            }
        }
    }
    
    public func getNewMemberList(roomSPID:String)->[[String:AnyObject]]
    {
        var myMembers:[[String:AnyObject]] = [[String:AnyObject]]();
        
        for( _, room ) in self.newRoomData.enumerated()
        {
            let roomID:String = room["ID"] as! String;
            
            if( roomID == roomSPID )
            {
                myMembers = room["members"] as! [[String:AnyObject]];
            }
        }
        
        return myMembers;
    }
    
}



