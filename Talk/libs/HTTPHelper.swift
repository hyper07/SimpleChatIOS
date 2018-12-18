

import Foundation

class HTTPHelper{
    class func httpPostDataDic(postURL:String, postData:[String:String], completionHandler:@escaping (NSDictionary?, NSError?) -> Void ) -> URLSessionTask{
        
        let postString:String = getPostString(from: postData)!;
        var responseResultData: NSDictionary = NSDictionary()
        var request = URLRequest(url: URL(string: postURL)!)
        request.httpMethod = "POST";// Compose a query string
        request.httpBody = postString.data(using: String.Encoding.utf8)
        request.timeoutInterval = 1200.0
        
        //print(postString);
        
        let task = URLSession.shared.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            if error != nil
            {
                print("error=\(String(describing: error))")
                completionHandler(nil, error! as NSError)
                return
            }
            // You can print out response object
            //let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            
            //            print("responseString = \(responseString)")
            //if let responseString = responseString {
            //    print("responseString = \(responseString)")
            //}
            //Let's convert response sent from a server side script to a NSDictionary object:
            do {
                
                print(data as Any);
                
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                responseResultData=myJSON!
                completionHandler(responseResultData, nil)
            } catch {
                print(error)
            }
            
            //semaphore.signal()
        }
        
        return task;
        
        //_ = semaphore.wait(timeout: DispatchTime.distantFuture);
        
    }
    
    class func getPostString(from paramList: [String:String]) -> String?
    {
        let allowedCharacterSet = (CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[] ").inverted)
        
        var paramString = "";
        
        for (key, value) in paramList
        {
            paramString = paramString + key + "=" + value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)! + "&"
        }
        
        return paramString;
    }
    
    class func notPrettyString(from object: Any) -> String? {
        if let objectData = try? JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            let objectString = String(data: objectData, encoding: .utf8)
            return objectString
        }
        return nil
    }
    
}
