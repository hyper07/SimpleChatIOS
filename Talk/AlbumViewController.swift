//
//  AlbumViewController.swift
//  SocketChat
//
//  Created by Kibaek Kim on 10/13/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class AlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UNUserNotificationCenterDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    
    let reuseIdentifier = "ImageCell"; // also enter this string as the cell identifier in the storyboard
    var chatDataList:Array<ChatBubbleData> = Array<ChatBubbleData>();
    var selectedChatID:Int = -1;
    var historyPage:Int = 1;
    var oldMMSID:Int = -1;
    var accountName:String = "";
    var roomName:String = "";
    var roomSPID:String = "";
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:#selector(self.handleRefresh), for: UIControlEvents.valueChanged)
        //refreshControl.tintColor = UIColor.red
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        collectionView.dataSource = self;
        collectionView.delegate = self;
        
        self.navigationItem.title = "Album";
        
        self.collectionView!.alwaysBounceVertical = true;
        self.collectionView.addSubview(self.refreshControl);
        
        self.oldMMSID = -1;
        self.loadHistory();
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        UNUserNotificationCenter.current().delegate = self;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationItem.title = self.roomName + "'s Album";
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        
        UNUserNotificationCenter.current().delegate = nil;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let identifier = segue.identifier
        {
            if( identifier == "idSegueGoPhoto" )
            {
                let photoViewController = segue.destination as! PhotoViewController;
                photoViewController.myChatID = self.selectedChatID;
            }
        }
    }
    
    
    // MARK:- Callback Functions
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.loadHistory();
    }
    
    // MARK:- Common Functions
    
    func loadHistory()
    {
        self.view.loadingIndicator(true);
        
        let params = ["SP_ID":self.roomSPID, "roomName":self.roomName, "oldMMSID":String(self.oldMMSID), "accountName":(UIApplication.shared.delegate as! AppDelegate).accountName] as! [String : String];
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/loadMMSHistories.php", postData: params) { (responseResult, error) -> Void in
            
            self.view.loadingIndicator(false);
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed loading history");
                
                if let resutlData = responseResult
                {
                    //To get rid of optional
                    //print(resutlData)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        self.refreshControl.endRefreshing()
                        
                        let result = resutlData["result"] as! Bool;
                        
                        if( result == true )
                        {
                            let msgList = resutlData["data"] as! [AnyObject];
                            var idx:Int = 0;
                            for msgObj in msgList
                            {
                                let myAccount = msgObj["ACCOUNT"] as! String;
                                let myNickName = msgObj["NICKNAME"] as! String;
                                let myIDStr = msgObj["ID"] as! String;
                                let myID = Int(myIDStr);
                                
                                let myCreatedStr = msgObj["CREATED"] as! String;
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                let myDate = formatter.date(from: myCreatedStr)
                                
                                let thumbnail = msgObj["THUMBNAIL"] as! String;
                                let originImage = msgObj["FILE"] as! String;
                                let thumbData = Data(base64Encoded: thumbnail, options: .ignoreUnknownCharacters);
                                let imgData = Data(base64Encoded: originImage, options: .ignoreUnknownCharacters);
                                let chatBubbleData = ChatBubbleData(id: myID, accountName:myAccount, nickName: myNickName, text: "", image:UIImage(data: imgData!), thumbnail: UIImage(data: thumbData!), date: myDate, type: (myAccount == self.accountName ? .mine : .opponent));
                                
                                if( idx == 0 )
                                {
                                    self.oldMMSID = myID!;
                                }
                                
                                self.chatDataList.insert(chatBubbleData, at: idx);
                                idx = idx+1;
                            }
                            
                            self.collectionView.reloadData();
                            
                        }
                        else
                        {
                            let msg = resutlData["msg"] as! String;
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

    // MARK:- UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.chatDataList.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! ImageCell
        cell.layer.borderColor = UIColor.lightGray.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 4
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        
        
        let chatData = self.chatDataList[indexPath.row] as ChatBubbleData
        
        if let chatImage = chatData.image
        {
            cell.thumbImg.image = chatImage
        }
        cell.thumbImg.msgID = chatData.id;
        cell.userName.text = chatData.nickName;
        cell.createdDate.text = chatData.getCreatedDate();
        
        return cell
    }
    
    // MARK:- UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        
        let chatData = self.chatDataList[indexPath.row] as ChatBubbleData;
        self.selectedChatID = chatData.id!;
        //self.performSegue(withIdentifier: "idSegueGoPhoto", sender: nil);
        
        //print("You selected cell #\(self.selectedChatID)!")
    }
    
    // MARK:- UserNotification DELEGATE METHODS
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // some other way of handling notification
        
        completionHandler(appDelegate.getNotificationOption());
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}


