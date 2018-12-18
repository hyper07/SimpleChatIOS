//
//  LoginController.swift
//  LoginScreenApp
//


import UIKit
import UserNotifications

class LoginController: UIViewController {

    
    let api_url = "https://yourapiserveraddress/CallAPI.php"
    let login_apikey = "TALK_LOGIN";
    let checksession_apikey = "TALK_CHECKSESSION"

    
    @IBOutlet var username_input: UITextField!
    @IBOutlet var password_input: UITextField!
    @IBOutlet var login_button: UIButton!
    
    var loginSession:String = ""
    var accountName:String = ""
    var nickName:String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "session") != nil
        {
            self.loginSession = preferences.object(forKey: "session") as! String
            
            if(( preferences.object(forKey: "accountName") ) != nil)
            {
                self.accountName = (preferences.object(forKey: "accountName") as! String).lowercased()
            }
            
            if(( preferences.object(forKey: "nickName") ) != nil)
            {
                self.nickName = preferences.object(forKey: "nickName") as! String
            }
            
            check_session()
        }
        else
        {
            username_input.isEnabled = true
            password_input.isEnabled = true
            login_button.isEnabled = true
            login_button.setTitle("Login", for: .normal)
        }        
    }


    @IBAction func DoLogin(_ sender: AnyObject) {
       
        if(username_input.text == "" || password_input.text == "" )
        {
            check_session()
        }
        else
        {
            login_now(username:username_input.text!, password: password_input.text!)
        }
        
    }
    
    
    func login_now(username:String, password:String)
    {
        let userAccount:String = username.exportOnlyAccount();
        
        self.view.loadingIndicator(true);
        login_button.isEnabled = false;
        
        let post_data: NSDictionary = NSMutableDictionary()

        post_data.setValue(login_apikey, forKey: "API_ID")
        post_data.setValue(userAccount, forKey: "accountName")
        post_data.setValue(password, forKey: "password")

        let url:URL = URL(string: api_url)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
            
        var paramString = ""
        
        for (key, value) in post_data
        {
            paramString = paramString + (key as! String) + "=" + (value as! String) + "&"
        }
            
        request.httpBody = paramString.data(using: String.Encoding.utf8)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
        (
            data, response, error) in
            
            self.view.loadingIndicator(false);
            self.login_button.isEnabled = true

            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                DispatchQueue.main.async(execute: self.onFailLogIn)
                return
            }
            
            let json: Any?
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: [])                
            }
            catch
            {
                DispatchQueue.main.async(execute: self.onFailLogIn)
                return
            }
            
            guard let server_response = json as? NSDictionary else
            {
                return
            }
            
            print(server_response as Any)
            
            if let data_block = server_response["data"] as? NSDictionary
            {
                if let session_data = data_block["session"] as? String
                {
                    self.loginSession = session_data
                    self.accountName = userAccount.lowercased()
                    self.nickName = data_block["displayName"] as! String
                    
                    let preferences = UserDefaults.standard
                    preferences.set(session_data, forKey: "session")
                    preferences.set(userAccount, forKey: "accountName")
                    preferences.set(self.nickName, forKey: "nickName")
                    
                    DispatchQueue.main.async(execute: self.onSuccessLogin)
                }
                else
                {
                    DispatchQueue.main.async(execute: self.onFailLogIn)
                }
            }
            else
            {
                DispatchQueue.main.async(execute: self.onFailLogIn)
            } 
        })
            
        task.resume()
    }

    
    
    
    
    func check_session()
    {
        //let message:String = "97:0{\"sid\":\"0dJpKK43Cm_gqgs-AAEl\",\"upgrades\":[\"websocket\"],\"pingInterval\":25000,\"pingTimeout\":60000}";
        //let by:Int  = 3;
        //var currentIndex:String.Index = message.startIndex;
        //print("----------------------");
        //print(message);
        //print(currentIndex);
        //print(by);
        
        //currentIndex = message.index(currentIndex, offsetBy: by)
        //print(currentIndex)
        //print(message[currentIndex])
        
        self.view.loadingIndicator(true);
        login_button.isEnabled = false
        
        let post_data: NSDictionary = NSMutableDictionary()
        
        post_data.setValue(checksession_apikey, forKey: "API_ID")
        post_data.setValue(accountName, forKey: "accountName")
        post_data.setValue(loginSession, forKey: "session")
        
        let url:URL = URL(string: api_url)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        var paramString = ""
        
        
        for (key, value) in post_data
        {
            paramString = paramString + (key as! String) + "=" + (value as! String) + "&"
        }
        
        request.httpBody = paramString.data(using: String.Encoding.utf8)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (
            data, response, error) in
            
            self.view.loadingIndicator(false);
            self.login_button.isEnabled = true;
            
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                
                DispatchQueue.main.async(execute: self.onFailLogIn)
                return
            }
            
            
            //print(data as Any)
            
            let json: Any?
            
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            }
            catch
            {
                DispatchQueue.main.async(execute: self.onFailLogIn)
                return
            }
           
            guard let server_response = json as? NSDictionary else
            {
                DispatchQueue.main.async(execute: self.onFailLogIn)
                return
            }
            
            if let response_code = server_response["response_code"] as? Int
            {
                if(response_code == 200)
                {
                    DispatchQueue.main.async(execute: self.onSuccessLogin)
                }
                else
                {
                    DispatchQueue.main.async(execute: self.onFailLogIn)
                }
            }
            else
            {
                DispatchQueue.main.async(execute: self.onFailLogIn)
            }
            
            
            
        })
        
        task.resume()
        
        
    }

    
    
    
    
    func onSuccessLogin()
    {
        login_button.isEnabled = true
        performSegue(withIdentifier: "goToWaitingRoom", sender: nil)
    }
    
    func onFailLogIn()
    {
        self.openSimpleAlert(title: "Fail Login", msg: "Authentication failed")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Create a new variable to store the instance of PlayerTableViewController
        let destinationVC = segue.destination as! RoomsViewController
        destinationVC.accountName = self.accountName
        destinationVC.nickName = self.nickName
        
        let backItem = UIBarButtonItem()
        backItem.title = "Log out"
        navigationItem.backBarButtonItem = backItem
    }
    
}

