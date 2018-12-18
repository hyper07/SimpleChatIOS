//
//  PhotoViewController.swift
//  SocketChat
//
//  Created by Kibaek Kim on 10/13/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class PhotoViewController : UIViewController, UNUserNotificationCenterDelegate
{
    @IBOutlet weak var photoView: UIImageView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var myChatID:Int = 0;
    
    override func viewDidLoad()
    {
        super.viewDidLoad();
                
        self.loadImage(chatID: myChatID);

        self.navigationItem.title = "Photo";
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        UNUserNotificationCenter.current().delegate = self;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        
        UNUserNotificationCenter.current().delegate = nil;
    }
    
    // MARK:- Common Functions
    
    func loadImage(chatID:Int)
    {
        self.view.loadingIndicator(true);
        
        print("loading original photo \(chatID))");
        
        let params = ["chatID":String(chatID), "accountName":(UIApplication.shared.delegate as! AppDelegate).accountName] as! [String : String]
    
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/loadPhoto.php", postData: params) { (responseResult, error) -> Void in
            
            self.view.loadingIndicator(false);
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed loading origin photo");
                
                if let resutlData = responseResult
                {
                    //To get rid of optional
                    //print(resutlData)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        let result = resutlData["result"] as! Bool;
                        
                        if( result == true )
                        {
                            let base64Photo = resutlData["data"] as! String;
                            let imgData = Data(base64Encoded: base64Photo, options: .ignoreUnknownCharacters);
                            self.photoView.image = UIImage(data: imgData!)
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
    
    // MARK:- UserNotification DELEGATE METHODS
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // some other way of handling notification
        
        completionHandler(appDelegate.getNotificationOption());
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
