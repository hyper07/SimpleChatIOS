//
//  Participant.swift
//  KissTalk
//
//  Created by Kibaek Kim on 12/9/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import Foundation
import RealmSwift

class Participant: Object {
    @objc dynamic var samaccountname: String = ""
    @objc dynamic var roomID: String = ""
    @objc dynamic var mobile: String = ""
    @objc dynamic var displayname: String = ""
    @objc dynamic var thumbnailphoto: String = ""
    @objc dynamic var department: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var ext: String = ""
    
}
