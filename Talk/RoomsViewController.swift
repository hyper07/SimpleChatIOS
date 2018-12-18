//
//  RoomsViewController.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import UserNotifications
import Realm
import RealmSwift

class RoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate,
    JCActionSheetDelegate {
    
    static var isNeedUpdateRoomInfo:Bool = false;

    @IBOutlet weak var tblRoomList: UITableView!
    
    var accountName: String!
    var nickName: String!
    var roomSPID: String!
    var roomCategory: String!
    var roomName: String!
    var roomMemo: String!
    var attachFile: UIImage!
    var attachThumb: UIImage!
    var memberList: [[String:AnyObject]]!
    
    var rooms = [[String: AnyObject]]()
    var sectionMap = [String:Array<NSMutableDictionary>]();
    
    var unreadMsgMap =  [String:Int]()
    
    
    var configurationOK = false
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureTableView()
        
        appDelegate.registerForPushNotifications(self.accountName);
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleWillEnterForegroundNotification), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil);
        
        automaticallyAdjustsScrollViewInsets = false;
        
        self.navigationItem.setHidesBackButton(true, animated:false);
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UNUserNotificationCenter.current().delegate = self;
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !configurationOK {
            configureNavigationBar()
            configurationOK = true
            loadRoom()
        }
        
        if( RoomsViewController.isNeedUpdateRoomInfo == true )
        {
            self.updateNewRoomList();
            RoomsViewController.isNeedUpdateRoomInfo = false;
        }
        
        if( self.rooms.count > 0 )
        {
            self.updateUnreadMsg();
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        
        UNUserNotificationCenter.current().delegate = nil;
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let identifier = segue.identifier {
            if identifier == "idSegueJoinRoom" {
                let chatViewController = segue.destination as! ChatViewController;
                chatViewController.nickName = nickName;
                chatViewController.accountName = accountName;
                chatViewController.roomName = roomName;
                chatViewController.roomSPID = roomSPID;
                chatViewController.roomMemo = roomMemo;
                chatViewController.attachThumb = attachThumb;
                chatViewController.attachFile = attachFile;
                
                var memberMap = [String:AnyObject]();
                for member in memberList
                {
                    //print(member as Any);
                    let memberAccountName = member["samaccountname"] as! String;
                    memberMap[memberAccountName.exportOnlyAccount()] = member as AnyObject;
                }
                
                chatViewController.memberMap = memberMap;
                
                let backItem = UIBarButtonItem()
                backItem.title = "Leave"
                navigationItem.backBarButtonItem = backItem
            }
        }
    }

    
    // MARK:- IBAction Methods
    
    @IBAction func exitChat(_ sender: AnyObject) {
        
    }
    
    @IBAction func openSetting(_ sender: AnyObject)
    {
        var selectedIndex:Int = 0;
        let preferences = UserDefaults.standard
        if(preferences.bool(forKey: "settingSound"))
        {
            selectedIndex = 0;
        }
        else
        {
            selectedIndex = 1;
        }
        
        let actionSheet = JCActionSheet.init(title: nil, delegate: self, cancelButtonTitle: "Cancel",
                                             destructiveButtonTitle: nil, otherButtonTitles: ["Sound","Silent"],
                                             textColor: UIColor.black, checkedButtonIndex:selectedIndex);
        
        self.present(actionSheet, animated: true, completion: nil);
    }
    
    // MARK:- Custom Methods
    
    func loadRoom()
    {
        print("loading history");
        
        self.view.loadingIndicator(true);
        
        let params = ["API_ID":"TALK_GETROOM", "accountName":self.accountName] as [String : String]
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourapiserveraddress/CallAPI.php", postData: params) { (responseResult, error) -> Void in
            
            self.view.loadingIndicator(false);
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed loading history");
                
                if let resultData = responseResult
                {
                    //To get rid of optional
                    //print(resultData)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        let result = resultData["result"] as! Bool;
                        
                        if( result == true )
                        {
                            let roomList = resultData["data"] as! [[String:AnyObject]];
                            
                            self.rooms = roomList;
                            //self.loadMembersFromRealm();
                            self.makeSectionData();
                            
                            self.tblRoomList.reloadData();
                            self.tblRoomList.isHidden = false;
                            
                            self.updateUnreadMsg();
                        }
                        else
                        {
                            let msg = resultData["msg"] as! String;
                            let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "Close", style: .default);
                            alertController.addAction(OKAction)
                            
                            self.present(alertController, animated: true)
                        }
                    })
                }
            }
        }
        task.resume();
    }
    
    func loadMembers(_ roomID:String)
    {
        print("loading members");
        
        self.view.loadingIndicator(true);
        
        let params = ["API_ID":"TALK_GETMEMBERS", "roomID":roomID, "accountName":(UIApplication.shared.delegate as! AppDelegate).accountName] as! [String : String]
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourapiserveraddress/CallAPI.php", postData: params) { (responseResult, error) -> Void in
            
            self.view.loadingIndicator(false);
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed loading members");
                
                if let resultData = responseResult
                {
                    let result = resultData["result"] as! Bool;
                    
                    if( result == true )
                    {
                        let realm = (UIApplication.shared.delegate as! AppDelegate).realm
                        let existResults:Results<Participant> = realm!.objects(Participant.self)
                            .filter("roomID = '\(roomID)'")
                        
                        try! realm?.write {
                            realm?.delete(existResults);
                        }
                        
                        let myMemberList = resultData["data"] as! [[String:AnyObject]];
                        self.updateMembers(roomID, myMemberList);
                        self.addMembers(roomID, myMemberList);
                        
                        self.tblRoomList.reloadData();
                        self.tblRoomList.isHidden = false;
                        
                        self.performSegue(withIdentifier: "idSegueJoinRoom", sender: nil);
                    }
                    else
                    {
                        let msg = resultData["msg"] as! String;
                        let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "Close", style: .default);
                        alertController.addAction(OKAction)
                        
                        self.present(alertController, animated: true)
                    }
                }
            }
        }
        
        task.resume();
    }
    
    func configureNavigationBar() {
        //navigationItem.backBarButtonItem?.title = "Logout";
        //navigationItem.title = "Kiss Talk"
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.title = "Kiss Talk - V" + version;
        }
    }
    
    
    func configureTableView() {
        tblRoomList.delegate = self
        tblRoomList.dataSource = self
        tblRoomList.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "idCellRoom")
        tblRoomList.isHidden = true
        tblRoomList.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func updateUnreadMsg()
    {
        if( appDelegate.deviceToken == nil )
        {
            return;
        }
        
        let params = ["deviceToken":appDelegate.deviceToken!, "accountName":(UIApplication.shared.delegate as! AppDelegate).accountName] as! [String : String]
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/loadUnreadMsg.php", postData: params) { (responseResult, error) -> Void in
            
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed loading unread msg");
                
                if let resultData = responseResult
                {
                    //To get rid of optional
                    print(resultData["data"] as Any);
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        let result = resultData["result"] as! Bool;
                        
                        if( result == true )
                        {
                            if let unreadData = resultData["data"] as? [String:AnyObject]
                            {
                                self.unreadMsgMap = unreadData as! [String : Int];
                            }
                            
                            self.tblRoomList.reloadData();
                            self.tblRoomList.isHidden = false;
                        }
                        else
                        {
                            let msg = resultData["msg"] as! String;
                            let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "Close", style: .default);
                            alertController.addAction(OKAction)
                            
                            self.present(alertController, animated: true)
                        }
                    })
                }
            }
        }
        
        task.resume();
    }
    
    func makeSectionData()
    {
        self.sectionMap = [String:Array<NSMutableDictionary>]();
        
        for (_, room) in self.rooms.enumerated()
        {
            let myCategory = room["Category"] as? String;
            if( self.sectionMap.keys.contains(myCategory!) == false )
            {
                self.sectionMap[myCategory!] = Array<NSMutableDictionary>();
            }
        
            let roomDic:NSDictionary = room as NSDictionary;
            
            self.sectionMap[myCategory!]?.append(roomDic.mutableCopy() as! NSMutableDictionary);
        }
    }
    
    func updateMembers(_ roomID:String, _ memberList:[[String:AnyObject]])
    {
        self.memberList = memberList;
        
        let roomList = self.sectionMap[self.roomCategory]!;
        
        for (_, room) in roomList.enumerated()
        {
            let roomSPID = room["ID"] as? String;
            if( roomSPID == roomID )
            {
                room["members"] = memberList;
                break;
            }
        }
    }
    
    func addMembers(_ roomID:String, _ memberList:[[String:AnyObject]])
    {
        for (_, member) in memberList.enumerated()
        {
            appDelegate.addMember(roomID: roomID, member: member)
        }
    }
    
    
    func loadMembersFromRealm()
    {
        let realm = appDelegate.realm
        
        for (key, var room) in self.rooms.enumerated()
        {
            let roomID:String = room["ID"] as! String;
            
            let memberResults:Results<Participant> = realm!.objects(Participant.self).filter("roomID = '\(roomID)'");
            let memberList = memberResults.toArray(ofType: Participant.self);
            
            if( memberList.count == 0 )
            {
                //self.rooms.remove(at: key);
            }
            else
            {
                room["members"] = memberList as NSArray;
                self.rooms[key] = room;
            }
            
        }
    }
    
    public func updateNewRoomList()
    {
        self.rooms = appDelegate.newRoomData;
        self.loadMembersFromRealm();
        self.makeSectionData();
        
        self.tblRoomList.reloadData();
        self.tblRoomList.isHidden = false;
    }
    
    
    // MARK:- UITableView Delegate and Datasource methods and override
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionMap.count;
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let myCategory = Array(self.sectionMap.keys)[section] as String;
        let sectionRoomList = self.sectionMap[myCategory]!;
        return sectionRoomList.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let myCategory = Array(self.sectionMap.keys)[section] as String;
        return myCategory;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellRoom", for: indexPath) as! UserCell
        
        let myCategory = Array(self.sectionMap.keys)[indexPath.section] as String;
        let sectionRoomList = self.sectionMap[myCategory]!;
        
        let room = sectionRoomList[indexPath.row];
        let members = room["members"] as? NSArray;
        let memberCnt = members?.count;
        
        if( members?.count == 0 )
        {
            cell.detailTextLabel?.text = "";
        }
        else
        {
            cell.detailTextLabel?.text = (memberCnt?.description)! + " people";
        }
        
        let roomSPID = room["ID"] as? String;
        
        if let unreadMsgCount = self.unreadMsgMap["roomSPID" + roomSPID!]
        {
            cell.lblUnreadCount.text = String(unreadMsgCount);
            cell.lblUnreadCount.textColor = UIColor.white;
            cell.lblUnreadCount.backgroundColor = UIColor.red;
            cell.lblUnreadCount.font = UIFont(name: "Lato-Regular", size: 11);
            cell.lblUnreadCount.textAlignment = NSTextAlignment.center;
            cell.lblUnreadCount.layer.cornerRadius = 15;
            cell.lblUnreadCount.clipsToBounds = true;
            
            cell.lblUnreadCount.isHidden = unreadMsgCount == 0;
        }
        else
        {
            cell.lblUnreadCount.text = "";
            cell.lblUnreadCount.isHidden = true;
        }
        
        cell.lblRoomLabel.text = room["Title"] as? String;
        cell.lblDescription.text = room["Memo"] as? String;
        
        //let titleRect = cell.textLabel?.frame;
        //cell.textLabel?.frame = CGRect((titleRect?.origin.x)! + 10, (titleRect?.origin.y)! - 10, (titleRect?.size.width)!, (titleRect?.size.height)!);
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        roomCategory = Array(self.sectionMap.keys)[indexPath.section] as String;
        
        let sectionRoomList = self.sectionMap[roomCategory]!;
        let room = sectionRoomList[indexPath.row];
        
        roomSPID = room["ID"] as! String;
        roomName = room["Title"] as! String;
        roomMemo = room["Memo"] as! String;
        memberList = room["members"] as! [[String:AnyObject]];

        if let attachFileData = room["attachFile"]
        {
            let decodedAttachFile = NSData(base64Encoded: attachFileData as! String, options: NSData.Base64DecodingOptions(rawValue: 0))
            attachFile = UIImage(data: decodedAttachFile! as Data)!
        }
        else
        {
            attachFile = nil;
        }
        
        
        if let attachThumbData = room["attachThumb"]
        {
            let decodedAttachThumb = NSData(base64Encoded: attachThumbData as! String, options: NSData.Base64DecodingOptions(rawValue: 0))
            attachThumb = UIImage(data: decodedAttachThumb! as Data)!
        }
        else
        {
            attachThumb = nil;
        }
        
        if( memberList.count == 0 )
        {
            self.loadMembers(roomSPID);
        }
        else
        {
            self.addMembers(roomSPID, memberList);
            self.performSegue(withIdentifier: "idSegueJoinRoom", sender: nil);
        }
    }
    

    
    // MARK:- JCActionSheetDelegate DELEGATE METHODS
    func actionSheet(_ actionSheet: JCActionSheet, clickedButtonAt buttonIndex: Int) {
        //self.currentCheckedIndex = buttonIndex;
        
        let preferences = UserDefaults.standard
        if( buttonIndex == 0 ){
            preferences.set(true, forKey: "settingSound")
        } else {
            preferences.set(false, forKey: "settingSound")
        }
    }
    
    func actionSheetCancel(_ actionSheet: JCActionSheet) {
        //do something with cancel action
    }
    
    
    // MARK:- UNUserNotificationCenterDelegate delegate
    
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // some other way of handling notification
        
        let userInfo = notification.request.content.userInfo;
        
        if let msgType = userInfo["categoryIdentifier"] as? String
        {
            if( msgType == "updateRoom" )
            {
                appDelegate.loadRoomWithMember(accountName: self.accountName);
            }
            else if( msgType == "normalMsg" )
            {
                completionHandler(appDelegate.getNotificationOption())
                
                if( self.rooms.count > 0 )
                {
                    self.updateUnreadMsg();
                }
            }
        }
        
        
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        /*
        switch response.actionIdentifier {
            case "answerOne":
                break;
            case "answerTwo":
                break;
            case "clue":
                let alert = UIAlertController(title: "Hint", message: "The answer is greater than 29", preferredStyle: .alert)
                let action = UIAlertAction(title: "Thanks!", style: .default, handler: nil)
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
            default:
                break
        }
        */
        completionHandler()
        
    }
    
    @objc func handleWillEnterForegroundNotification(notification: Notification)
    {
        if( RoomsViewController.isNeedUpdateRoomInfo == true )
        {
            self.updateNewRoomList();
            RoomsViewController.isNeedUpdateRoomInfo = false;
        }
        
        if( self.rooms.count > 0 )
        {
            self.updateUnreadMsg();
        }
    }
    

}
