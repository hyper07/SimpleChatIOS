//
//  RoomsViewController.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import UserNotifications

class MembersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate,
    JCActionSheetDelegate {
    
    static var isNeedUpdateMemberInfo:Bool = false;

    @IBOutlet weak var tblMembersList: UITableView!
    
    
    var accountName:String = "";
    var roomName:String = "";
    var roomSPID:String = "";
    var memberMap:[String:AnyObject]!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.registerForPushNotifications(self.accountName);
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleWillEnterForegroundNotification), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil);
        
        automaticallyAdjustsScrollViewInsets = false;
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UNUserNotificationCenter.current().delegate = self;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        configureTableView();
        configureNavigationBar();
        
        if( MembersViewController.isNeedUpdateMemberInfo == true )
        {
            self.updateNewMemberList();
            MembersViewController.isNeedUpdateMemberInfo = false;
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
    

    
    // MARK:- IBAction Methods
    
    
    
    // MARK:- Custom Methods
    
    
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
                    DispatchQueue.main.async(execute: { () -> Void in
                        let result = resultData["result"] as! Bool;
                        
                        if( result == true )
                        {
                            //let myMemberList = resultData["data"] as! [[String:AnyObject]];
                            
                            
                            self.tblMembersList.reloadData();
                            self.tblMembersList.isHidden = false;
                            
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
    
    func configureNavigationBar() {
        //navigationItem.backBarButtonItem?.title = "Logout";
        //navigationItem.title = "Talk"
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.title = "Talk - V" + version;
        }
    }
    
    
    func configureTableView() {
        tblMembersList.delegate = self
        tblMembersList.dataSource = self
        tblMembersList.register(UINib(nibName: "MemberCell", bundle: nil), forCellReuseIdentifier: "idCellMember")
        //tblMembersList.isHidden = true
        tblMembersList.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func callNumber(phoneNumber:String) {
        
        if let phoneCallURL = URL(string: "tel://\(phoneNumber)") {
            
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                application.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    public func updateNewMemberList()
    {
        self.memberMap = [String:AnyObject]();
        
        let memberList:[[String:AnyObject]] = appDelegate.getNewMemberList(roomSPID: self.roomSPID);
        if( memberList.count == 0 )
        {
            let alertController = UIAlertController(title: "Alert", message: "This room was closed.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default, handler:onCloseRoom);
            alertController.addAction(OKAction)
            
            self.present(alertController, animated: true)
        }
        else
        {
            for member in memberList
            {
                let memberAccountName = member["samaccountname"] as! String;
                self.memberMap[memberAccountName.exportOnlyAccount()] = member as AnyObject;
            }
        }
        
        self.tblMembersList.reloadData();
    }
    
    func onCloseRoom(alert: UIAlertAction)
    {
        navigationController?.popViewController(animated: true);
    }
    
    
    // MARK:- UITableView Delegate and Datasource methods and override
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        guard memberMap != nil  else {
            return 0;
        }
        
        return memberMap.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellMember", for: indexPath) as! MemberCell
        
        let memberKey = Array(self.memberMap.keys)[indexPath.row] as String;
        let member = memberMap[memberKey];
        cell.setMember(member!);
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let memberKey = Array(self.memberMap.keys)[indexPath.row] as String;
        let member = memberMap[memberKey] as AnyObject;
        
        let mobileNumber = member["mobile"] as? String;
        var extNumber = member["ext"] as? String;
        
        if( mobileNumber?.length == 0 && extNumber?.length == 0 )
        {
            let alert = UIAlertController(title: "Alert", message: "There is no phone number.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            /*
            if let base64String = member["thumbnailphoto"] as? String
            {
                if( base64String.isEmpty == false && base64String.length > 0 )
                {
                    let decodedData = NSData(base64Encoded: base64String, options: NSData.Base64DecodingOptions(rawValue: 0));
                    let profileImage:UIImage = UIImage(data: decodedData! as Data)!;
                    
                    let screenWidth = alert.view.bounds.width
                    let imageView = UIImageView(frame: CGRect(x:(screenWidth-120)/2 - 10, y:-130, width:120, height:120))
                    imageView.image = profileImage;
                    imageView.layer.borderWidth = 1
                    imageView.layer.masksToBounds = false
                    imageView.layer.borderColor = UIColor.lightGray.cgColor
                    imageView.layer.cornerRadius = 60;
                    imageView.clipsToBounds = true;
                    imageView.contentMode = .scaleAspectFill;
                    alert.view.addSubview(imageView);
                }
                
            }
             */
            
            
            
            return
        }
        
        let alertViewController = UIAlertController(title: "", message: "Do you want to call?", preferredStyle: .actionSheet)
        
        if( mobileNumber?.length != 0 )
        {
            let mobileCall = UIAlertAction(title: "MOBILE : \(mobileNumber!)", style: .default, handler: { (alert) in
                self.callNumber(phoneNumber: mobileNumber!);
            })
            alertViewController.addAction(mobileCall)
        }
        
        if( extNumber?.length != 0 )
        {
            if( extNumber!.length < 5 )
            {
                extNumber = "516-941-\(extNumber!)";
            }
            
            let extCall = UIAlertAction(title: "OFFICE : \(extNumber!)", style: .default, handler: { (alert) in
                self.callNumber(phoneNumber: "\(extNumber!)");
            })
            alertViewController.addAction(extCall)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
            
        }
        alertViewController.addAction(cancel)
        self.present(alertViewController, animated: true, completion: nil)
        
        if let base64String = member["thumbnailphoto"] as? String
        {
            if( base64String.isEmpty == false && base64String.length > 0 )
            {
                let decodedData = NSData(base64Encoded: base64String, options: NSData.Base64DecodingOptions(rawValue: 0));
                let profileImage:UIImage = UIImage(data: decodedData! as Data)!;
                
                let screenWidth = alertViewController.view.bounds.width;
                let imageView = UIImageView(frame: CGRect(x:(screenWidth-120)/2 - 10, y:-130, width:120, height:120))
                imageView.image = profileImage;
                imageView.layer.borderWidth = 1
                imageView.layer.masksToBounds = false
                imageView.layer.borderColor = UIColor.lightGray.cgColor
                imageView.layer.cornerRadius = 60;
                imageView.clipsToBounds = true;
                imageView.contentMode = .scaleAspectFill;
                alertViewController.view.addSubview(imageView);
            }
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
        if( MembersViewController.isNeedUpdateMemberInfo == true )
        {
            self.updateNewMemberList();
            MembersViewController.isNeedUpdateMemberInfo = false;
        }
    }
    

}
