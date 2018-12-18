//
//  ChatBubble.swift
//  ChatBubbleScratch
//
//  Created by Sauvik Dolui on 02/09/15.
//  Copyright (c) 2015 Innofied Solution Pvt. Ltd. All rights reserved.
//

import UIKit

class ChatBubble: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    // Properties
    var imageViewChat: CLImageViewPopup?
    var profilePhotoViewChat: UIImageView?
    var imageViewBG: UIImageView?
    var text: String?
    var labelChatText: ActiveLabel?
    var descChatText: UILabel?
    var unreadMsgText: UILabel?
    
    public var chatData: ChatBubbleData?
    
    /**
    Initializes a chat bubble view
    
    :param: data   ChatBubble Data
    :param: startY origin.y of the chat bubble frame in parent view
    
    :returns: Chat Bubble
    */
    init(data: ChatBubbleData, startY: CGFloat)
    {
        // 1. Initializing parent view with calculated frame
        super.init(frame: ChatBubble.framePrimary(data.type, startY:startY))
        
        self.chatData = data;
        
        // Making Background transparent
        self.backgroundColor = UIColor.clear
        
        let padding: CGFloat = 10.0
        let profileSize: CGFloat = 40
        
        // 2. Drawing image if any
        if let chatImage = data.thumbnail {
            
            let width: CGFloat = min(chatImage.size.width, self.frame.width - 2 * padding)
            let height: CGFloat = chatImage.size.height * (width / chatImage.size.width)
            imageViewChat = CLImageViewPopup(frame: CGRect(x: data.type == .mine ? padding : padding+profileSize + 8, y: padding, width: width, height: height))
            imageViewChat?.image = chatImage
            imageViewChat?.msgID = data.id
            imageViewChat?.originImage = data.image
            imageViewChat?.layer.cornerRadius = 5.0
            imageViewChat?.layer.masksToBounds = true
            
            
            self.addSubview(imageViewChat!)
        }
        
        // 3. Going to add Text if any
        if let chatText = data.text {
            // frame calculation
            let startX = padding
            var startY:CGFloat = 5.0
            if let imageView = imageViewChat {
                startY += imageView.frame.maxY
            }
            labelChatText = ActiveLabel(frame: CGRect(x: data.type == .mine ? startX : startX+profileSize+7, y: startY, width: self.frame.width - 2 * startX , height: 5))
            labelChatText?.customize { label in
                label.textAlignment = .left
                label.font = UIFont.systemFont(ofSize: 14)
                label.numberOfLines = 0 // Making it multiline
                label.text = chatText
                label.sizeToFit() // Getting fullsize of it
                label.enabledTypes = [.url]
                label.handleURLTap({ (url) in
                    UIApplication.shared.open(url, options: [ : ], completionHandler: nil);
                })
            }
            
            //labelChatText?.textAlignment = data.type == .mine ? .right : .left
            
            self.addSubview(labelChatText!)
        }
        // 4. Calculation of new width and height of the chat bubble view
        var viewHeight: CGFloat = 0.0
        var viewWidth: CGFloat = 0.0
        if let imageView = imageViewChat {
            // Height calculation of the parent view depending upon the image view and text label
            
            let imgMaxX = imageView.frame.maxX;
            let imgMaxY = imageView.frame.maxY;
            
            let lblMaxX = imageView.frame.maxX;
            let lblMaxY = imageView.frame.maxY;
            
            viewWidth = max(imgMaxX, lblMaxX) + padding;
            viewHeight = max(imgMaxY, lblMaxY) + padding;
            
        } else {
            viewHeight = labelChatText!.frame.maxY + padding/2
            viewWidth = labelChatText!.frame.width + labelChatText!.frame.minX + padding
        }
        
        // 5. Adding new width and height of the chat bubble frame
        self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: viewWidth, height: viewHeight)
        
        // 6. Adding the resizable image view to give it bubble like shape
        let bubbleImageFileName = data.type == .mine ? "bubbleMine" : "bubbleSomeone"
        imageViewBG = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: self.frame.width, height: self.frame.height))
        if data.type == .mine {
            imageViewBG?.image = UIImage(named: bubbleImageFileName)?.resizableImage(withCapInsets: UIEdgeInsetsMake(14, 14, 17, 28))
        } else {
            imageViewBG?.image = UIImage(named: bubbleImageFileName)?.resizableImage(withCapInsets: UIEdgeInsetsMake(14, 22, 17, 20))
        }
        self.addSubview(imageViewBG!)
        self.sendSubview(toBack: imageViewBG!)
        
        // Frame recalculation for filling up the bubble with background bubble image
        let repsotionXFactor:CGFloat = data.type == .mine ? 0.0 : profileSize
        let bgImageNewX = imageViewBG!.frame.minX + repsotionXFactor
        let bgImageNewWidth =  imageViewBG!.frame.width + CGFloat(12.0)
        let bgImageNewHeight =  imageViewBG!.frame.height + CGFloat(6.0)
        imageViewBG?.frame = CGRect(x: bgImageNewX, y: 0.0, width: data.type == .mine ? bgImageNewWidth : bgImageNewWidth - profileSize - 8, height: bgImageNewHeight)

        
        // Keepping a minimum distance from the edge of the screen
        var newStartX:CGFloat = 0.0
        if data.type == .mine
        {
            // Need to maintain the minimum right side padding from the right edge of the screen
            let extraWidthToConsider = imageViewBG!.frame.width
            newStartX = ScreenSize.SCREEN_WIDTH - extraWidthToConsider
        }
        else
        {
            // Need to maintain the minimum left side padding from the left edge of the screen
            //newStartX = -imageViewBG!.frame.minX + 3.0
            newStartX = 3.0
        }
        
        
        // 8. Drawing profile image if any
        if let profileImage = data.profilePhoto
        {
            if data.type != .mine
            {
                profilePhotoViewChat = UIImageView(frame: CGRect(x: 3, y: frame.height - 2*profileSize/3 + 10, width: profileSize, height: profileSize))
                profilePhotoViewChat?.image = profileImage
                profilePhotoViewChat?.layer.borderWidth = 1
                profilePhotoViewChat?.layer.masksToBounds = false
                profilePhotoViewChat?.layer.borderColor = UIColor.lightGray.cgColor
                profilePhotoViewChat?.layer.cornerRadius = profileSize/2
                profilePhotoViewChat?.clipsToBounds = true
                profilePhotoViewChat?.contentMode = .scaleAspectFill;
                
                self.addSubview(profilePhotoViewChat!)
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTapProfile));
                profilePhotoViewChat?.addGestureRecognizer(tapGesture);
                profilePhotoViewChat?.isUserInteractionEnabled = true;
            }
        }
        
        if( data.hasProfilePhoto == false && data.type != .mine )
        {
            self.loadingProfilePhoto(accountName: data.accountName!);
        }
        
        // 9. Drawing date
        let dateString = data.getCreatedDate();
        
        descChatText = UILabel(frame: CGRect(x: data.type == .mine ? 0 : 50, y: imageViewBG!.frame.maxY, width: 100 , height: 10))
        descChatText?.textAlignment = data.type == .mine ? .right : .left
        descChatText?.font = UIFont.systemFont(ofSize: 10)
        descChatText?.textColor = Color.coolGrayColor()
        descChatText?.numberOfLines = 1 // Making it multiline
        descChatText?.text = data.type == .mine ? dateString : dateString + " - " + data.nickName!
        descChatText?.sizeToFit() // Getting fullsize of it
        
        if( data.type == .mine )
        {
            descChatText?.frame = CGRect(x: self.frame.width - descChatText!.frame.width, y: descChatText!.frame.minY, width: descChatText!.frame.width , height: descChatText!.frame.height)
        }
        self.addSubview(descChatText!)
        
        // 10. Drawing unreadMsg count
        unreadMsgText = UILabel(frame: CGRect(x: 0, y: 0, width: 15 , height: 15))
        unreadMsgText?.textAlignment = data.type == .mine ? .right : .left
        unreadMsgText?.font = UIFont.systemFont(ofSize: 10)
        unreadMsgText?.textColor = Color.blue;
        unreadMsgText?.numberOfLines = 1 // Making it multiline
        unreadMsgText?.text = data.getUnreadCnt();
        unreadMsgText?.sizeToFit() // Getting fullsize of it
        
        if( data.type == .mine )
        {
            unreadMsgText?.frame = CGRect(x: imageViewBG!.frame.minX - 20, y: imageViewBG!.frame.maxY - 20, width: 15 , height: 15)
        }
        else
        {
            unreadMsgText?.frame = CGRect(x: imageViewBG!.frame.maxX, y: imageViewBG!.frame.maxY - 20, width: 15 , height: 15)
        }
        self.addSubview(unreadMsgText!)
        
        self.frame = CGRect(x: newStartX, y: self.frame.minY, width: frame.width, height: frame.height + 25)
        
        if( (self.chatData?.id)! >= 5700 && self.chatData?.unreadCnt == -1 )
        {
            self.loadUnreadInfo();
        }
    }
    
    func displaySendMessageEmoji()
    {
        unreadMsgText?.text = "\u{1F4A8}";
    }
    
    func updateUnreadInfo(newUnreadCnt:Int, newUnreadLog:String)
    {
        self.chatData?.unreadCnt = newUnreadCnt;
        self.chatData?.unreadLog = newUnreadLog;
        unreadMsgText?.text = self.chatData?.getUnreadCnt();
    }
    
    public func updateMsgID(newMsgID:Int)
    {
        self.chatData?.id = newMsgID;
        self.loadUnreadInfo();
    }
    
    public func loadUnreadInfo()
    {
        if( self.chatData?.id == -1 && self.chatData?.type == .mine )
        {
            self.displaySendMessageEmoji();
        }
        else if( (self.chatData?.id)! < 5700 )
        {
            return;
        }
        
        let params = ["deviceOS":"android", "accountName":self.chatData?.accountName, "msgID":self.chatData?.id?.description] as! [String : String]
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/loadUnreadMemberByMsg.php", postData: params) { (responseResult, error) -> Void in
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed loading history");
                
                if let resutlData = responseResult
                {
                    let result = resutlData["result"] as! Bool;
                    
                    if( result == true )
                    {
                        let unreadCnt = resutlData["unreadCnt"] as! String;
                        let unreadLog = resutlData["unreadLog"] as! String;
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.updateUnreadInfo(newUnreadCnt: Int(unreadCnt)!, newUnreadLog: unreadLog);
                        })
                        
                        
                    }
                    else
                    {
                        DispatchQueue.main.async(execute: { () -> Void in
                            let msg = resutlData["msg"] as! String;
                            let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                            let OKAction = UIAlertAction(title: "Close", style: .default);
                            alertController.addAction(OKAction)
                            
                            self.window?.rootViewController?.present(alertController, animated: true);
                        })
                        
                        
                    }
                }
            }
        }
        task.resume();
    }
    
    func loadingProfilePhoto(accountName:String)
    {
        self.profilePhotoViewChat?.loadingIndicator(true);
        
        let params = ["accountName":accountName] as [String : String]
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/loadProfilePhoto.php", postData: params) { (responseResult, error) -> Void in
            
            self.profilePhotoViewChat?.loadingIndicator(false);
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed loading history");
                
                if let resutlData = responseResult
                {
                    let result = resutlData["result"] as! Bool;
                    
                    if( result == true )
                    {
                        let base64Photo = resutlData["data"] as! String;
                        
                        if base64Photo.isEmpty == false
                        {
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                
                                appDelegate.updateProfilePhoto(accountName: accountName, base64Photo: base64Photo)
                                let imgData = Data(base64Encoded: base64Photo, options: .ignoreUnknownCharacters);
                                self.profilePhotoViewChat?.image = UIImage(data: imgData!)
                            })
                        }
                    }
                }
            }
        }
        task.resume();
    }

    // 6. View persistance support
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - FRAME CALCULATION
    class func framePrimary(_ type:BubbleDataType, startY: CGFloat) -> CGRect{
        let paddingFactor: CGFloat = 0.02
        let sidePadding = ScreenSize.SCREEN_WIDTH * paddingFactor
        let maxWidth = ScreenSize.SCREEN_WIDTH * 0.65 // We are cosidering 65% of the screen width as the Maximum with of a single bubble
        let startX: CGFloat = type == .mine ? ScreenSize.SCREEN_WIDTH * (CGFloat(1.0) - paddingFactor) - maxWidth : sidePadding
        return CGRect(x: startX, y: startY, width: maxWidth, height: 5) // 5 is the primary height before drawing starts
    }

    @objc func onTapProfile()
    {
        
    }
}
