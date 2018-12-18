//
//  SettingController.swift
//  KissTalk
//
//  Created by Kibaek Kim on 12/5/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//
import UIKit

class SettingController: UIViewController
{
    
    @IBOutlet var settingSound: UISwitch!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let preferences = UserDefaults.standard
        
        settingSound.setOn(preferences.bool(forKey: "settingSound"), animated: false);
    }
    
    @IBAction func changeSwitch(_ sender: UISwitch) {
        
        let preferences = UserDefaults.standard
        preferences.set(sender.isOn, forKey: "settingSound")
        
    }
    
    
}
