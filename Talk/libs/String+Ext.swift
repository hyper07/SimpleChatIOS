//
//  String+Ext.swift
//  Talk
//
//  Created by Kibaek Kim on 11/17/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import Foundation

extension String {
    var length:Int {
        return self.count
    }
    
    func indexOf(target: String) -> Int? {
        
        let range = (self as NSString).range(of: target)
        
        guard Range.init(range) != nil else {
            return nil
        }
        
        return range.location
        
    }
    
    func lastIndexOf(target: String) -> Int? {
        
        let range = (self as NSString).range(of: target, options: NSString.CompareOptions.backwards)
        
        guard Range.init(range) != nil else {
            return nil
        }
        
        return self.length - range.location - 1
        
    }
    func contains(s: String) -> Bool {
        return (self.range(of: s) != nil) ? true : false
    }
    
    func exportOnlyAccount() -> String {
        
        var userAccount:String;
        
        if let myIdx1:Int = self.indexOf(target: "@") {
            if( myIdx1 > -1 ){
                let tokenList = self.components(separatedBy: "@");
                userAccount = tokenList[0];
            } else {
                userAccount = self;
            }
        } else if let myIdx2:Int = self.indexOf(target: "\\") {
            if( myIdx2 > -1 ){
                let tokenList = self.components(separatedBy: "\\");
                userAccount = tokenList[0];
            } else {
                userAccount = self;
            }
        } else {
            userAccount = self;
        }
        
        return userAccount.lowercased();
    }
}
