//
//  ChatCell.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class ChatCell: BaseCell {

    @IBOutlet weak var lblChatMessage: UILabel!
    @IBOutlet weak var lblNickName: UILabel!
    @IBOutlet weak var lblMessageDetails: UILabel!
    @IBOutlet weak var picImageView: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
