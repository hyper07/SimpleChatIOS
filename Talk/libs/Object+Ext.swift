//
//  Object+Ext.swift
//  KissTalk
//
//  Created by Kibaek Kim on 12/10/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

extension Object {
    
    func toDictionary() -> [String:AnyObject] {
        //let properties = self.objectSchema.properties.map { $0.name }
        //let dictionary = self.dictionaryWithValues(forKeys: properties)
        
        var data = [String:AnyObject]()
        
        for prop in self.objectSchema.properties as [Property]! {
            // find lists
            data[prop.name] = self[prop.name] as AnyObject
        }
        return data;
    }
}
