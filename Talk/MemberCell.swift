
//
//  UserCell.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class MemberCell: BaseCell {
    
    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var department: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var ext: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        profilePhoto?.layer.borderWidth = 1
        profilePhoto?.layer.masksToBounds = false
        profilePhoto?.layer.borderColor = UIColor.lightGray.cgColor
        profilePhoto?.layer.cornerRadius = 25;
        profilePhoto?.clipsToBounds = true
        profilePhoto?.contentMode = .scaleAspectFill;
    }

    public func setMember(_ member:AnyObject)
    {
        let displayName = member["displayname"] as! String
        userName.text = displayName
        
        let departmentInfo = member["department"] as! String
        department.text = departmentInfo
        
        let titleInfo = member["title"] as! String
        title.text = titleInfo
        
        if let extInfo = member["ext"] as? String {
            if extInfo.isEmpty == false && extInfo.length > 0 {
                ext.text = "Ext. #\(extInfo)"
            } else {
                ext.text = ""
            }
            
        }
        
        let accountName = member["samaccountname"] as! String;
        
        if let profileImage = (UIApplication.shared.delegate as! AppDelegate).getProfileImage(accountName)
        {
            profilePhoto?.image = profileImage
        }
        else
        {
            var nameList:[String]
            if( displayName.length == 0 )
            {
                nameList = accountName.components(separatedBy: ".")
            }
            else
            {
                nameList = displayName.components(separatedBy: " ")
            }
            
            var initial = ""
            if( nameList.count > 1)
            {
                let firstName = nameList[0]
                let lastName = nameList[1]
                initial = "\(firstName[firstName.startIndex]).\(lastName[lastName.startIndex])"
            }
            else
            {
                let fullName = nameList[0]
                let index = fullName.index(fullName.startIndex, offsetBy: 2)
                initial = "\(fullName[index])"
            }
            
            let profileImage:UIImage = UIImage.InitialImage(text: initial.uppercased(), backgroundColor: UIColor.almondColor(), circular: true)
            
            profilePhoto?.image = profileImage
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTapProfile));
            profilePhoto?.addGestureRecognizer(tapGesture)
            profilePhoto?.isUserInteractionEnabled = true
            
            loadingProfilePhoto(accountName: accountName)
        }
       
    }
    
    func loadingProfilePhoto(accountName:String)
    {
        self.profilePhoto.loadingIndicator(true)
        
        let params = ["accountName":accountName] as [String : String]
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/loadProfilePhoto.php", postData: params) { (responseResult, error) -> Void in
            
            self.profilePhoto.loadingIndicator(false);
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                if let resutlData = responseResult
                {
                    let result = resutlData["result"] as! Bool;
                    
                    if( result == true )
                    {
                        let base64Photo:String = resutlData["data"] as! String;
                        
                        if base64Photo.isEmpty == false
                        {
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                
                                appDelegate.updateProfilePhoto(accountName: accountName, base64Photo: base64Photo)
                                let imgData = Data(base64Encoded: base64Photo, options: .ignoreUnknownCharacters);
                                self.profilePhoto.image = UIImage(data: imgData!)
                            })
                        }
                    }
                }
            }
        }
        task.resume();
    }
    
    @objc func onTapProfile()
    {
        
    }

}
