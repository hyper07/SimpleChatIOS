//
//  UIViewController+Ext.swift
//  SocketChat
//
//  Created by Kibaek Kim on 10/13/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

extension UIViewController
{
    func setWidthForButtonBarItems(width:CGFloat)
    {
        if let buttonList:[UIBarButtonItem] = self.navigationItem.rightBarButtonItems
        {
            for button in buttonList {
                button.width = width;
            }
        }
    }
    
    func openSimpleAlert(title:String, msg:String)
    {
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "Close", style: .default);
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true)
    }
    
    
}
