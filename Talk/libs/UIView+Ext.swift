//
//  UIView+Ext.swift
//  SocketChat
//
//  Created by Kibaek Kim on 10/12/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//
import Foundation
import UIKit

extension UIView {
    func loadingIndicator(_ show: Bool) {
        
        DispatchQueue.main.async(execute: { () -> Void in
        
            let tag = 808404
            if show {
                let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
                myActivityIndicator.center = self.center
                myActivityIndicator.hidesWhenStopped = true
                myActivityIndicator.tag = tag
                myActivityIndicator.isOpaque = false;
                myActivityIndicator.startAnimating()
                myActivityIndicator.backgroundColor = Color.black.withAlphaComponent(0.2);
                myActivityIndicator.frame = UIScreen.main.bounds;
                self.addSubview(myActivityIndicator)
                
            } else {
                self.alpha = 1.0
                if let indicator = self.viewWithTag(tag) as? UIActivityIndicatorView {
                    indicator.stopAnimating()
                    indicator.removeFromSuperview()
                }
            }

        })
    }
}
