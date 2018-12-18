//
//  Results.swift
//  Talk
//
//  Created by Kibaek Kim on 12/10/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import Realm
import RealmSwift

extension Results {
    func toArray<T>(ofType: T.Type) -> [[String:AnyObject]] {
        var array = [[String:AnyObject]]()
        for i in 0 ..< count {
            if let result = self[i] as? Object {
                array.append(result.toDictionary())
            }
        }
        
        return array
    }
}
