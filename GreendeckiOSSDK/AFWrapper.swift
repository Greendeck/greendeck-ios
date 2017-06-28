//
//  AFWrapper.swift
//  FoodTracker
//
//  Created by Yashvardhan Srivastava on 15/06/17.
//  Copyright © 2017 Apple Inc. All rights reserved.
//

import Foundation

import UIKit

public class AFWrapper: NSObject {
    
    class func requestPOSTURL(_ postURL: String, postHeaders: Dictionary<String, String>, postDict:Dictionary<String, Any>, success:@escaping (Dictionary<String, Any>) -> Void, failure:@escaping (Error) -> Void) -> URLSessionTask{
        
        var responseResultData: Dictionary = Dictionary<String, Any>()
        
        var request = URLRequest(url: URL(string: postURL)!)
        request.httpMethod = "POST";// Compose a query string
        
        request.allHTTPHeaderFields = postHeaders
        
        let postJSONString = dictToJSONString(dictionary: postDict)
        request.httpBody = postJSONString.data(using: String.Encoding.utf8)
        
        print(request)
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil
            {
                print("error=\(error)")
                failure(error!)
                return
            }
            // You can print out response object
            let responseString = String(data: data!, encoding: String.Encoding.utf8)
            //            print("responseString = \(responseString)")
            if let responseString = responseString {
                print("responseString = \(responseString)")
            }
            //Let's convert response sent from a server side script to a NSDictionary object:
            do {
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Dictionary<String, Any>
                responseResultData=myJSON!
                success(responseResultData)
            } catch {
                print(error)
            }
        }
        task.resume()
        return task
        
        
    }
    
    class func requestPUTURL(_ postURL: String, postHeaders: Dictionary<String, String>, postDict:Dictionary<String, Any>, success:@escaping (Dictionary<String, Any>) -> Void, failure:@escaping (Error) -> Void) -> URLSessionTask{
        
        var responseResultData: Dictionary = Dictionary<String, Any>()
        
        var request = URLRequest(url: URL(string: postURL)!)
        request.httpMethod = "PUT";// Compose a query string
        
        request.allHTTPHeaderFields = postHeaders
        
        let postJSONString = dictToJSONString(dictionary: postDict)
        request.httpBody = postJSONString.data(using: String.Encoding.utf8)
        
        print(request)
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil
            {
                print("error=\(error)")
                failure(error!)
                return
            }
            // You can print out response object
            let responseString = String(data: data!, encoding: String.Encoding.utf8)
            //            print("responseString = \(responseString)")
            if let responseString = responseString {
                print("responseString = \(responseString)")
            }
            //Let's convert response sent from a server side script to a NSDictionary object:
            do {
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Dictionary<String, Any>
                responseResultData=myJSON!
                success(responseResultData)
            } catch {
                print(error)
            }
        }
        task.resume()
        return task
        
        
    }
    
    class func requestGETURL(_ getURL: String, getHeaders: Dictionary<String, String>, success:@escaping (Dictionary<String, Any>) -> Void, failure:@escaping (Error) -> Void ) -> URLSessionTask{
        
        var responseResultData: Dictionary = Dictionary<String, Any>()
        
        var request = URLRequest(url: URL(string: getURL)!)
        
        request.allHTTPHeaderFields = getHeaders 
        
        request.httpMethod = "GET";// Compose a query string
        
        print(request)
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil
            {
                print("error=\(error)")
                failure(error!)
                return
            }
            // You can print out response object
            let responseString = String(data: data!, encoding: String.Encoding.utf8)
            //            print("responseString = \(responseString)")
            if let responseString = responseString {
                print("responseString = \(responseString)")
            }
            //Let's convert response sent from a server side script to a NSDictionary object:
            do {
                let myJSON =  try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? Dictionary<String, Any>
                responseResultData=myJSON!
                success(responseResultData)
            } catch {
                print(error)
            }
        }
        task.resume()
        return task
        
        
    }
    
    public class func dictToJSONString(dictionary: Dictionary<String, Any>) -> String{
    
        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: dictionary,
            options: [.prettyPrinted]) {
            let theJSONText = String(data: theJSONData,
                                     encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            return "\(theJSONText!)"
        }
        else{
            return "{}"
        }
    }
}
