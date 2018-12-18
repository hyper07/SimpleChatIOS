//
//  CLImageViewPopup.swift
//  poplearning
//
//  Created by Vineeth Vijayan on 01/05/16.
//  Copyright © 2016 creativelogics. All rights reserved.
//
import UIKit

class CLImageViewPopup: UIImageView {
    var originRect: CGRect?
    
    public var msgID: Int!
    public var originImage: UIImage!
    private var zoomView: GTZoomableImageView!
    
    var animated: Bool = true
    var intDuration = 0.25
    //MARK: Life cycle
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.setGesture();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.setGesture();
    }
    
    func setGesture()
    {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTapGesture));
        self.addGestureRecognizer(tapGesture);
        self.isUserInteractionEnabled = true;
    }
    
    func loadPhoto()
    {
        self.loadingIndicator(true);
        
        let params = ["chatID":String(msgID), "accountName":(UIApplication.shared.delegate as! AppDelegate).accountName] as! [String : String]
        
        let task = HTTPHelper.httpPostDataDic(postURL: "https://yourkpnaddress/socketchat/db/loadPhoto.php", postData: params) { (responseResult, error) -> Void in
            
            self.loadingIndicator(false);
            
            if error != nil
            {
                print(error as Any)
            }
            else
            {
                print("completed loading origin photo");
                
                if let resutlData = responseResult
                {
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        let result = resutlData["result"] as! Bool;
                        
                        if( result == true )
                        {
                            let base64Photo = resutlData["data"] as! String;
                            let imgData = Data(base64Encoded: base64Photo, options: .ignoreUnknownCharacters);
                            self.originImage = UIImage(data: imgData!)
                        }
                        
                        self.popUpImageToFullScreen();
                    })
                }
            }
        }
        
        task.resume();
    }
    func popUpImageToFullScreen()
    {
        if let window = UIApplication.shared.delegate?.window {
            let parentView = self.findParentViewController(self)!.view
            let point:CGRect = self.convert(self.bounds, to: parentView)
            
            self.zoomView = GTZoomableImageView(frame: UIScreen.main.bounds);
            self.zoomView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.exitFullScreen)))
            self.zoomView.frame = point
            self.zoomView.backgroundColor = UIColor(white: 1, alpha: 1)
            originRect = point
            self.zoomView.image = self.originImage == nil ? self.image : self.originImage;
            window?.addSubview(self.zoomView)
            
            let sendEmailBtn:UIButton = UIButton(frame: CGRect(x: ((parentView?.frame.width)! - 110), y: 30, width: 100, height: 30))
            //sendEmailBtn.backgroundColor = .black
            sendEmailBtn.setTitleColor(UIColor.black, for: .normal);
            sendEmailBtn.setTitleColor(UIColor.gray, for: .selected);
            sendEmailBtn.setTitle("Send Email", for: .normal)
            sendEmailBtn.addTarget(self, action:#selector(self.onTapSendEmailBtn), for: .touchUpInside)
            self.zoomView?.addSubview(sendEmailBtn)
            
            if animated {
                UIView.animate(withDuration: intDuration, animations: {
                    self.zoomView.alpha = 1
                    self.zoomView.frame = UIScreen.main.bounds;//CGRect(x: 0, y: 0, width: (parentView?.frame.width)!, height: (parentView?.frame.width)!)
                    self.zoomView.center = (parentView?.center)!
                }, completion: { (finished: Bool ) in
                })
            }
        }
    }
    
    
    
    @objc func onTapSendEmailBtn()
    {
        let attachImage:UIImage = (self.originImage == nil ? self.image : self.originImage)!;
        let chatViewController:ChatViewController = UIApplication.topViewController() as! ChatViewController;
        chatViewController.openSendEmailForm(attachImage: attachImage);
        
        self.exitFullScreen();
    }
    
    
    @objc func exitFullScreen ()
    {
        UIView.animate(withDuration: intDuration, animations: {
            self.zoomView.frame = self.originRect!
            self.zoomView.alpha = 0
        }, completion: { (bol) in
            //self.zoomView.removeGestureRecognizer(gesture);
            self.zoomView.removeFromSuperview()
        })
    }
    
    
    //MARK: Actions of Gestures
    
    
    @objc func onTapGesture()
    {
        if( self.originImage == nil )
        {
            loadPhoto();
        }
        else
        {
            popUpImageToFullScreen();
        }
    }
    
    @objc func move(sender:UIPanGestureRecognizer)
    {
        let translation = sender.translation(in: sender.view)
        sender.view?.center = CGPoint(x: (sender.view?.center.x)! + translation.x, y: (sender.view?.center.y)! + translation.y)
        sender.setTranslation(CGPoint.zero, in: sender.view)
        
    }
    
    func findParentViewController(_ view: UIView) -> UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
