//
//  ChatViewController.swift
//  ChatBubbleFinal
//
//  Created by Sauvik Dolui on 02/09/15.
//  Copyright (c) 2015 Innofied Solution Pvt. Ltd. All rights reserved.
//

import UIKit
import UserNotifications
import MessageUI

class ChatViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UNUserNotificationCenterDelegate, JCActionSheetDelegate, MFMailComposeViewControllerDelegate {
    
    static var isNeedUpdateMemberInfo:Bool = false;
    
    @IBOutlet var messageComposingView: UIView!
    @IBOutlet weak var messageCointainerScroll: UIScrollView!
    @IBOutlet weak var buttomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var lblOtherUserActivityStatus: UILabel!
    @IBOutlet weak var lblNewsBanner: UILabel!
    @IBOutlet weak var lblRoomMemo: UILabel!
    @IBOutlet weak var imgRoomFile: CLImageViewPopup!
    @IBOutlet weak var roomInfoBoxHeightConstraint:NSLayoutConstraint!
    @IBOutlet weak var messageBoxHeightConstraint:NSLayoutConstraint!
    
    var nickName: String!
    var accountName: String!
    var roomSPID: String!
    var roomName: String!
    var roomMemo: String!
    var attachFile: UIImage!
    var attachThumb: UIImage!
    var memberMap:[String:AnyObject]!
    
    var selectedImage : UIImage?
    var lastChatBubbleY: CGFloat = 10.0
    var insertChatBubbleY: CGFloat = 0.0
    var internalPadding: CGFloat = 8.0
    var lastMessageType: BubbleDataType?
    
    var imagePicker = UIImagePickerController()
    
    var configurationOK = false
    
    var bannerLabelTimer: Timer!
    
    var lastChatID: Int = -1
    
    var historyPage: Int = 1
    
    var isForcedHideKeyboard:Bool = false;
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(ChatViewController.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        //refreshControl.tintColor = UIColor.red
        
        return refreshControl
    }()
    
    // MARK:- Override Method
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configurationOK = false
        lastChatID = -1
        
        automaticallyAdjustsScrollViewInsets = false
        
        textView.delegate = self;
        textView.isScrollEnabled = false;
        textView.isEditable = true;
        textView.layer.borderColor = UIColor.lightGray.cgColor;
        textView.layer.borderWidth = 1.0;
        textView.layer.cornerRadius = 4;
        
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false //2
        imagePicker.sourceType = .photoLibrary //3
        sendButton.isEnabled = false
        
        self.messageCointainerScroll.contentSize = CGSize(width: messageCointainerScroll.frame.width, height: lastChatBubbleY + internalPadding)
        self.messageCointainerScroll.addSubview(self.refreshControl)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.down
        swipeGestureRecognizer.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(self.handleConnectedNotification), name: Notification.Name("onConnectedNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleError), name: Notification.Name("ERROR-2:401:3"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleDisconnectedNotification), name: Notification.Name("onDisconnectedNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleJoinedUserUpdateNotification), name: Notification.Name("onJoinedRoomNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleDisconnectedUserUpdateNotification), name: Notification.Name("onLeavedRoomNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleUserTypingNotification), name: Notification.Name("userTypingNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSuccessChatNotification), name: Notification.Name("successChatNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSuccessInviteUserNotification), name: Notification.Name("successInviteUserNotification"), object: nil)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleWillEnterForegroundNotification), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil);
        
        if( roomMemo.isEmpty && attachThumb == nil )
        {
            roomInfoBoxHeightConstraint.constant = 0;
            self.view.layoutIfNeeded()
        }
        else
        {
            if( roomMemo != nil )
            {
                lblRoomMemo.text = roomMemo;
            }
            
            if( attachThumb != nil )
            {
                imgRoomFile.image = attachThumb;
                imgRoomFile.originImage = attachFile;
            }
            
            roomInfoBoxHeightConstraint.constant = 40;
            self.view.layoutIfNeeded()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if !configurationOK {
            configureNewsBannerLabel()
            configureOtherUserActivityLabel()
        }
        
        self.readMsg();
        
        UNUserNotificationCenter.current().delegate = self;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        navigationItem.title = self.roomName;
        self.messageCointainerScroll.alwaysBounceVertical = true;
        
        if( ChatViewController.isNeedUpdateMemberInfo == true )
        {
            self.updateNewMemberList();
            ChatViewController.isNeedUpdateMemberInfo = false;
        }
        
        if( SocketIOManager.sharedInstance.isConnected() == false )
        {
            SocketIOManager.sharedInstance.establishConnection();
        }
        else
        {
            self.doLoadHistory();
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
    
    override func didMove(toParentViewController parent: UIViewController?) {
        super.didMove(toParentViewController: parent);
        if( parent == self.navigationController?.parent )
        {
            print("Back Tapped");
            self.roomMemo = "";
            self.attachFile = nil;
            self.attachThumb = nil;
            self.leaveRoom();
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let identifier = segue.identifier
        {
            if identifier == "idSegueGoAlbum"
            {
                var photoTalkList:Array<ChatBubbleData> = Array();
                let chatBubbleList:Array<UIView> = self.messageCointainerScroll.subviews;
                for chatBubble:UIView in chatBubbleList
                {
                    if ( chatBubble is ChatBubble && (chatBubble as! ChatBubble).chatData!.image != nil )
                    {
                        photoTalkList.append((chatBubble as! ChatBubble).chatData!);
                    }
                }
                
                let albumViewController = segue.destination as! AlbumViewController;
                albumViewController.roomName = self.roomName;
                albumViewController.roomSPID = self.roomSPID;
                albumViewController.accountName = self.accountName;
                
                let backItem = UIBarButtonItem()
                backItem.title = "Back"
                navigationItem.backBarButtonItem = backItem
            }
            else if identifier == "idSegueGoMember"
            {
                let membersViewController = segue.destination as! MembersViewController;
                membersViewController.roomName = self.roomName;
                membersViewController.roomSPID = self.roomSPID;
                membersViewController.accountName = self.accountName;
                membersViewController.memberMap = self.memberMap;
                
                let backItem = UIBarButtonItem()
                backItem.title = "Back"
                navigationItem.backBarButtonItem = backItem
            }
        }
    }

    
    
    // MARK:- IBActions
    
    @IBAction func prepareAddUser(_ sender: AnyObject)
    {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Invite User", message: "Please enter an accountName to join.", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Only accountName(ex:kibaek.kim)";
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            print("Text field: \(textField?.text ?? "")")
            self.inviteUser((textField?.text)!);
        }));
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func sendButtonClicked(_ sender: AnyObject) {
        
        if (textView.text?.count)! > 0 {
            sendText(textView.text!);
            textView.text = "";
            self.textViewDidChange(textView);
        }
        textView.resignFirstResponder()
    }
    
    @IBAction func cameraButtonClicked(_ sender: AnyObject)
    {
        let alertViewController = UIAlertController(title: "", message: "Choose your option", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default, handler: { (alert) in
            self.openCamera()
        })
        let gallery = UIAlertAction(title: "Gallery", style: .default) { (alert) in
            self.openGallary()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
            
        }
        alertViewController.addAction(camera)
        alertViewController.addAction(gallery)
        alertViewController.addAction(cancel)
        self.present(alertViewController, animated: true, completion: nil)
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
    
    func prepareTalk()
    {
        SocketIOManager.sharedInstance.listenForOtherMessages();
        SocketIOManager.sharedInstance.joinRoom(nickName, accountName, roomName, roomSPID, Array(memberMap.keys));
        SocketIOManager.sharedInstance.getChatMessage { (messageInfo) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                
                let senderAccount = messageInfo["accountName"] as! String;
                let senderNickName = messageInfo["nickName"] as! String;
                let chatBubbleData = ChatBubbleData(id: messageInfo["id"] as? Int,
                                                    accountName: senderAccount,
                                                    nickName: senderNickName,
                                                    text: messageInfo["message"] as? String,
                                                    image:nil,
                                                    thumbnail: nil,
                                                    date: Date(),
                                                    type: (senderAccount == self.accountName ? .mine : .opponent))
                self.addChatBubble(chatBubbleData)
            })
        }
        
        SocketIOManager.sharedInstance.getSentFile { (messageInfo) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                let senderAccount = messageInfo["accountName"] as! String;
                let senderNickName = messageInfo["nickName"] as! String;
                let base64Encoding = messageInfo["base64Encoding"] as! String;
                let decodedData = Data(base64Encoded: base64Encoding, options: .ignoreUnknownCharacters);
                let chatBubbleData = ChatBubbleData(id: messageInfo["id"] as? Int,
                                                    accountName: senderAccount,
                                                    nickName: senderNickName,
                                                    text: messageInfo["message"] as? String,
                                                    image:nil,
                                                    thumbnail: UIImage(data: decodedData!),
                                                    date: Date(),
                                                    type: (senderAccount == self.accountName ? .mine : .opponent))
                self.addChatBubble(chatBubbleData)
            })
        }
    }
    
    func doLoadHistory()
    {
        if !configurationOK
        {
            configurationOK = true;
            self.loadHistory(page: self.historyPage);
        }
        else
        {
            if( self.lastChatID > -1 )
            {
                self.loadHistory(page: 1, onlyNew: true);
            }
        }
    }
    
    func configureNewsBannerLabel() {
        lblNewsBanner.layer.cornerRadius = 15.0
        lblNewsBanner.clipsToBounds = true
        lblNewsBanner.alpha = 0.0
    }
    
    
    func configureOtherUserActivityLabel() {
        lblOtherUserActivityStatus.isHidden = true
        lblOtherUserActivityStatus.text = ""
    }
    
    func loadHistory(page:Int, onlyNew:Bool=false)
    {
        self.view.loadingIndicator(true);
        
        var params = ["SP_ID":self.roomSPID, "roomName":self.roomName, "page":String(page), "accountName":(UIApplication.shared.delegate as! AppDelegate).accountName] as! [String : String]
        
        if( onlyNew )
        {
            params["lastChatID"] = String(self.lastChatID);
        }
        
        print("************ loading history page \(params)) ************");
        
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/loadHistories.php", postData: params) { (responseResult, error) -> Void in
            
            self.view.loadingIndicator(false);
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                //print("completed loading history");
                
                if let resutlData = responseResult
                {
                    //To get rid of optional
                    //print(resutlData)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        self.refreshControl.endRefreshing();
                        
                        if( self.roomSPID == nil )
                        {
                            return;
                        }
                        
                        let result = resutlData["result"] as! Bool;
                        
                        if( result == true )
                        {
                            let msgList = resutlData["data"] as! [AnyObject];
                            
                            //print("Result \(resutlData)")
                            
                            if( page > 1 )
                            {
                                self.insertChatBubbleY = 0
                            }
                            
                            for msgObj in msgList
                            {
                                let myAccount = msgObj["ACCOUNT"] as! String;
                                let myNickName = msgObj["NICKNAME"] as! String;
                                let myIDStr = msgObj["ID"] as! String;
                                let myID = Int(myIDStr);
                                let myMsg = msgObj["MSG"] as? String ?? ""
                                let unreadCnt = msgObj["UNREAD_CNT"] as? String ?? "0"
                                let unreadLog = msgObj["UNREAD_LOG"] as? String ?? ""
                                
                                let myCreatedStr = msgObj["CREATED"] as! String;
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                let myDate = formatter.date(from: myCreatedStr)
                                
                                if( (msgObj["MSG_TYPE"] as! String) == "SMS" )
                                {
                                    let chatBubbleData = ChatBubbleData(id: myID,
                                                                        accountName: myAccount,
                                                                        nickName: myNickName,
                                                                        text: myMsg, image:nil,
                                                                        thumbnail:nil,
                                                                        date: myDate,
                                                                        type: (myAccount == self.accountName ? .mine : .opponent),
                                                                        unreadCnt: Int(unreadCnt),
                                                                        unreadLog: unreadLog)
                                    self.addChatBubble(chatBubbleData, page > 1)
                                }
                                else
                                {
                                    let thumbnail = msgObj["THUMBNAIL"] as! String;
                                    let originImage = msgObj["FILE"] as! String;
                                    let thumbData = Data(base64Encoded: thumbnail, options: .ignoreUnknownCharacters);
                                    let imgData = Data(base64Encoded: originImage, options: .ignoreUnknownCharacters);
                                    let chatBubbleData = ChatBubbleData(id: myID,
                                                                        accountName: myAccount,
                                                                        nickName: myNickName,
                                                                        text: "",
                                                                        image:UIImage(data: imgData!),
                                                                        thumbnail:UIImage(data: thumbData!),
                                                                        date: myDate,
                                                                        type: (myAccount == self.accountName ? .mine : .opponent),
                                                                        unreadCnt: Int(unreadCnt),
                                                                        unreadLog: unreadLog)
                                    self.addChatBubble(chatBubbleData, page > 1)
                                }
                            }
                            
                            if( page > 1 )
                            {
                                let chatBubbleList:Array<UIView> = self.messageCointainerScroll.subviews;
                                
                                var idx = 0;
                                for chatBubble:UIView in chatBubbleList
                                {
                                    if ( chatBubble is ChatBubble )
                                    {
                                        if( idx > msgList.count-1 )
                                        {
                                            let frame:CGRect = chatBubble.frame
                                            chatBubble.frame = CGRect(x: frame.minX, y: frame.minY + self.insertChatBubbleY, width: frame.width, height: frame.height)
                                        }
                                        idx += 1
                                    }
                                }
                                
                                
                                self.lastChatBubbleY = self.lastChatBubbleY + self.insertChatBubbleY
                                self.messageCointainerScroll.contentSize = CGSize(width: self.messageCointainerScroll.frame.width, height: self.lastChatBubbleY + self.internalPadding)
                                self.moveToMessage(self.insertChatBubbleY + self.messageCointainerScroll.frame.height - 50, false)
                            }
                            
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
    
    func getProfileImage(_ accountName:String)->UIImage
    {
        var profileImage:UIImage = UIImage();
        if let member = self.memberMap[accountName.exportOnlyAccount()]
        {
            if (member.allKeys as NSArray).contains("thumbnailphoto") && (member["thumbnailphoto"] as! String) != ""
            {
                let base64String = member["thumbnailphoto"] as! String;
                let decodedData = NSData(base64Encoded: base64String, options: NSData.Base64DecodingOptions(rawValue: 0))
                profileImage = UIImage(data: decodedData! as Data)!
            }
            else
            {
                let displayName = member["displayname"] as! String;
                let nameList:[String] = displayName.components(separatedBy: " ");
                
                var initial = "";
                if( nameList.count > 1)
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
                
                profileImage = UIImage.InitialImage(text: initial.uppercased(), backgroundColor: UIColor.almondColor(), circular: true)
            }
            
        }
        
        return profileImage;
    }
    
    func sendText(_ msg:String)
    {
        if( SocketIOManager.sharedInstance.isConnected() == false )
        {
            self.openSimpleAlert(title: "Alert", msg: "Not connected to Talk Server. \nPlease contact to IT Department")
        }
        else
        {
            SocketIOManager.sharedInstance.sendMessage(message: msg, withNickName: self.nickName)
            let chatBubbleData = ChatBubbleData(id: -1,
                                                accountName: self.accountName,
                                                nickName: self.nickName,
                                                text: msg,
                                                image:nil,
                                                thumbnail: nil,
                                                date: Date(),
                                                type: .mine)
            self.addChatBubble(chatBubbleData)
        }
    }
    
    func sendImage(_ img:UIImage)
    {
        let fixedImage = img.fixImageOrientation()!;
        
        let imageData:NSData = UIImageJPEGRepresentation(fixedImage, 0.1)! as NSData
        
        //let imageData:NSData = UIImagePNGRepresentation(profileImage.image!)!
        let base64String = imageData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        SocketIOManager.sharedInstance.sendFile(fileData: base64String, withNickName: self.nickName)
        
        let chatBubbleData = ChatBubbleData(id: -1,
                                            accountName: self.accountName,
                                            nickName: self.nickName,
                                            text: nil,
                                            image:img,
                                            thumbnail: img,
                                            date: Date(),
                                            type: .mine)
        self.addChatBubble(chatBubbleData)
    }
    
    func showBannerLabelAnimated() {
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 1.0
            
        }, completion: { (finished) -> Void in
            self.bannerLabelTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(ChatViewController.hideBannerLabel), userInfo: nil, repeats: false)
        })
    }
    
    
    @objc func hideBannerLabel() {
        if bannerLabelTimer != nil {
            bannerLabelTimer.invalidate()
            bannerLabelTimer = nil
        }
        
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 0.0
            
        }, completion: { (finished) -> Void in
        })
    }
    
    @objc func dismissKeyboard()
    {
        if textView.isFirstResponder
        {
            textView.resignFirstResponder()
            SocketIOManager.sharedInstance.sendStopTypingMessage(nickname: nickName)
        }
    }
    
    func leaveRoom() -> Void{
        SocketIOManager.sharedInstance.leaveRoom(self.nickName, self.accountName, self.roomName, self.roomSPID);
        
        self.nickName = nil;
        self.accountName = nil;
        self.roomName = nil;
        self.roomSPID = nil;
        
        SocketIOManager.sharedInstance.removeListenForOtherMessages();
        NotificationCenter.default.removeObserver(self);
        SocketIOManager.sharedInstance.closeConnection()
    }
    
    func addChatBubble(_ data: ChatBubbleData, _ isInsert: Bool=false) {
        
        if( data.id! > -1 && isInsert == false )
        {
            if( self.lastChatID >= data.id!)
            {
                return;
            }
            
            self.lastChatID = data.id!;
        }
        
        let padding:CGFloat = lastMessageType == data.type ? internalPadding/3.0 :  internalPadding
        let chatBubble = ChatBubble(data: data, startY: isInsert ? insertChatBubbleY + padding : lastChatBubbleY + padding)
        
        if( isInsert )
        {
            insertChatBubbleY = chatBubble.frame.maxY
            self.messageCointainerScroll.insertSubview(chatBubble, at: 0)
        }
        else
        {
            lastChatBubbleY = chatBubble.frame.maxY
            self.messageCointainerScroll.addSubview(chatBubble)
            self.messageCointainerScroll.contentSize = CGSize(width: messageCointainerScroll.frame.width, height: lastChatBubbleY + internalPadding)
            self.moveToLastMessage()
        }
        
        lastMessageType = data.type
        
        if( data.type == .mine )
        {
            textView.text = ""
            sendButton.isEnabled = false
        }
    }
    
    func moveToMessage(_ position:CGFloat, _ animated:Bool=true) {
        
        if messageCointainerScroll.contentSize.height > messageCointainerScroll.frame.height {
            let contentOffSet = CGPoint(x: 0.0, y: position - messageCointainerScroll.frame.height)
            self.messageCointainerScroll.setContentOffset(contentOffSet, animated: animated)
        }
    }
    
    func moveToLastMessage(_ animated:Bool=true) {
        
        if messageCointainerScroll.contentSize.height > messageCointainerScroll.frame.height {
            let contentOffSet = CGPoint(x: 0.0, y: messageCointainerScroll.contentSize.height - messageCointainerScroll.frame.height)
            self.messageCointainerScroll.setContentOffset(contentOffSet, animated: animated)
        }
    }
    
    func inviteUser(_ accountName:String)
    {
        if( SocketIOManager.sharedInstance.isConnected() == false )
        {
            self.openSimpleAlert(title: "Alert", msg: "Not connected to Talk Server. \nPlease contact to IT Department");
        }
        else
        {
            SocketIOManager.sharedInstance.inviteUser(roomSPID: self.roomSPID, accountName:accountName);
        }
    }
    
    func readMsg()
    {
        if( appDelegate.deviceToken == nil )
        {
            return;
        }
        
        let params = ["deviceToken":appDelegate.deviceToken!, "roomSPID":self.roomSPID, "accountName":(UIApplication.shared.delegate as! AppDelegate).accountName] as! [String : String]
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/readMsg.php", postData: params) { (responseResult, error) -> Void in
            
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed adding unread msg");
                
                if let resutlData = responseResult
                {
                    //To get rid of optional
                    print(resutlData);
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        let result = resutlData["result"] as! Bool;
                        
                        if( result == true )
                        {
                            let unreadMsgMap = resutlData["data"] as! [String:Int];
                            var unreadMsgCnt:Int = 0;
                            for (_, obj) in unreadMsgMap.enumerated()
                            {
                                unreadMsgCnt += obj.value;
                            }
                            UIApplication.shared.applicationIconBadgeNumber = unreadMsgCnt;
                        }
                        else
                        {
                            let msg = resutlData["msg"] as! String;
                            let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "Close", style: .default);
                            alertController.addAction(OKAction)
                            
                            self.present(alertController, animated: true)
                        }
                    });
                }
            }
        }
        
        task.resume();
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
    }
    
    func onCloseRoom(alert: UIAlertAction)
    {
        navigationController?.popViewController(animated: true);
    }
    
    func updateMsgIDForMine(newMsgID:Int)
    {
        let chatBubbleList:Array<UIView> = self.messageCointainerScroll.subviews;
        for chatBubble:UIView in chatBubbleList
        {
            if ( chatBubble is ChatBubble && (chatBubble as! ChatBubble).chatData!.id == -1 )
            {
                (chatBubble as! ChatBubble).updateMsgID(newMsgID: newMsgID);
                break;
            }
        }
    }
    
    public func openSendEmailForm(attachImage:UIImage)
    {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.addAttachmentData(UIImageJPEGRepresentation(attachImage, CGFloat(1.0))!, mimeType: "image/jpeg", fileName:  "attach.jpeg");
        
        if MFMailComposeViewController.canSendMail()
        {
            //composer.setToRecipients(["Email1", "Email2"])
            //composer.setSubject("Test Mail")
            //composer.setMessageBody("Text Body", isHTML: false)
            
            self.present(composer, animated: true, completion: nil);
        }
    }
    
    // MARK:- NotificationCenter Observer
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.historyPage = self.historyPage + 1
        self.loadHistory(page: self.historyPage);
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue

        UIView.animate(withDuration: 1.0, animations: { () -> Void in
            //self.buttomLayoutConstraint = keyboardFrame.size.height
            self.buttomLayoutConstraint.constant = keyboardFrame.size.height

            }, completion: { (completed: Bool) -> Void in
                    self.moveToLastMessage()
        }) 
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 1.0, animations: { () -> Void in
            self.buttomLayoutConstraint.constant = 0.0
            }, completion: { (completed: Bool) -> Void in
                self.moveToLastMessage()
        }) 
    }
    
    
    
    @objc func handleConnectedNotification(notification: Notification) {
        prepareTalk();
        doLoadHistory();
    }
    
    @objc func handleError(notification: Notification) {
        
        let alertController = UIAlertController(title: "Debug", message: "Adjusted Index of message for out of range.", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default);
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true)
 
        
        //prepareTalk();
        //doLoadHistory();
    }
    
    @objc func handleUserTypingNotification(notification: NSNotification) {
        if let typingUsersDictionary = notification.object as? [String: AnyObject] {
            var names = ""
            var totalTypingUsers = 0
            for (typingUser, _) in typingUsersDictionary {
                if typingUser != nickName {
                    names = (names == "") ? typingUser : "\(names), \(typingUser)"
                    totalTypingUsers += 1
                }
            }
            
            if totalTypingUsers > 0 {
                let verb = (totalTypingUsers == 1) ? "is" : "are"
                
                lblOtherUserActivityStatus.text = "\(names) \(verb) now typing a message..."
                lblOtherUserActivityStatus.isHidden = false
            }
            else {
                lblOtherUserActivityStatus.isHidden = true
            }
        }
        
    }
    
    @objc func handleDisconnectedUserUpdateNotification(notification: NSNotification) {
        let leavedUserInfo = notification.object as! [String: AnyObject];
        let disconnectedUserNickName = leavedUserInfo["name"] as? String;
        lblNewsBanner.text = "User \(disconnectedUserNickName!.uppercased()) has left."
        showBannerLabelAnimated()
    }
    
    @objc func handleJoinedUserUpdateNotification(notification: Notification) {
        let connectedUserInfo = notification.object as! [String: AnyObject]
        let connectedUserNickName = connectedUserInfo["name"] as? String
        lblNewsBanner.text = "User \(connectedUserNickName!.uppercased()) was just connected."
        showBannerLabelAnimated()
    }
    
    @objc func handleSuccessChatNotification(notification: Notification) {
        //print(notification.object as Any);
        let newId = notification.object as! Int
        self.lastChatID = newId;
        self.updateMsgIDForMine(newMsgID:newId);
    }
    
    @objc func handleSuccessInviteUserNotification(notification: Notification) {
        //print(notification.object as Any);
        let msg = notification.object as! String;        
        self.openSimpleAlert(title: "Invitation User Result", msg: msg);
    }
    
    @objc func handleDisconnectedNotification(notification: Notification) {
        
    }
    
    @objc func handleWillEnterForegroundNotification(notification: Notification)
    {
        if( ChatViewController.isNeedUpdateMemberInfo == true )
        {
            self.updateNewMemberList();
            ChatViewController.isNeedUpdateMemberInfo = false;
        }
        
        if( SocketIOManager.sharedInstance.isConnected() == false )
        {
            SocketIOManager.sharedInstance.establishConnection();
        }
        else
        {
            self.doLoadHistory();
        }
    }
    
    // MARK:- MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK:- UserNotification DELEGATE METHODS
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // some other way of handling notification
        
        let userInfo = notification.request.content.userInfo;
        
        if let msgType = userInfo["categoryIdentifier"] as? String
        {
            if( msgType == "updateRoom" )
            {
                appDelegate.loadRoomWithMember(accountName: self.accountName);
            }
            else if( msgType == "updateUnreadMsg" )
            {
                
            }
            else if( msgType == "normalMsg" )
            {
                if( self.roomName != notification.request.content.title )
                {
                    completionHandler(appDelegate.getNotificationOption());
                }
            }
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
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
    
    
    // MARK:- TEXT FILED DELEGATE METHODS
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        SocketIOManager.sharedInstance.sendStartTypingMessage(nickname: nickName)
        
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        
        textView.resignFirstResponder()
        
        if( self.isForcedHideKeyboard == false )
        {
            if (textView.text?.count)! > 0 {
                sendText(textView.text!);
                textView.text = "";
                self.textViewDidChange(textView);
            }
        }
        
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if( text == "" && textView.text == "" )
        {
            sendButton.isEnabled = false;
            return true;
        }
        
        var texttmp: String
        
        if text.count > 0 {
            texttmp = String(format:"%@%@",textView.text!, text);
        } else {
            let string:NSString = textView.text! as NSString
            texttmp = string.substring(to: string.length - 1) as String
        }
        if texttmp.count > 0 {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        
        messageBoxHeightConstraint.constant = newSize.height + 16;
        self.view.layoutIfNeeded()
    }
    
    // MARK:- UIGestureRecognizerDelegate Methods & UIImagePickerControllerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handleTap(sender: AnyObject?)
    {
        //textView.resignFirstResponder()
        isForcedHideKeyboard = true;
        self.view.endEditing(true)
    }
    
    
    // MARK:- Camera Functions
    
    func openCamera()
    {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            
            // Setup and present default Camera View Controller
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
        else
        {
            let alertController = UIAlertController(title: "Warning", message: "You don't have camera.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default);
            alertController.addAction(OKAction)
            
            self.present(alertController, animated: true)
        }
    }
    
    func openGallary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            // Setup and present default Camera View Controller
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // Dismiss the view controller a
        picker.dismiss(animated: true, completion: nil)
        
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        sendImage(image);
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("Cancel")
        picker.dismiss(animated: true, completion: nil)
    }
    
    func convertImageToBase64(_ image: UIImage) -> String? {
        return UIImageJPEGRepresentation(image, 1)?.base64EncodedString()
    }
    
}
