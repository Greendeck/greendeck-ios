//
//  Greendeck.swift
//  FoodTracker
//
//  Created by Yashvardhan Srivastava on 15/06/17.
//  Copyright © 2017 Apple Inc. All rights reserved.
//

import Foundation
import UIKit

public class GreendeckPerson: NSObject{
    
    override init() {
        
    }
    
    var personCode: String? = ""
    
    init(personCode: String){
        super.init()
        self.personCode = personCode
    }
}


public class Greendeck{
    
    static var uniqueInstance: Greendeck? = nil
    
    public var accessTokenString: String = ""
    public var accessTokenJSON: Dictionary<String, Any> = [:]
    public var customer: GreendeckPerson? = nil
    let userDefaults = UserDefaults.standard
    var clientId: String = ""
    var clientSecret: String = ""
    
    var AuthEndPoint = "http://api.greendeck.co/api/v1/oauth/token.json"
    var TransactionEndPoint = "http://api.greendeck.co/api/v1/transactions"
    var CustomerApiEndPoint = "http://api.greendeck.co/api/v1/people"
    var EventApiEndPoint = "http://api.greendeck.co/api/v1/events"
    var FetchApiEndPoint = "http://api.greendeck.co/api/v1/fetch"
    
    public func initialize(clientId: String, clientSecret: String) ->Greendeck {
        self.clientId = clientId
        self.clientSecret = clientSecret
        
        print("initializing Greendeck")
        
        if Greendeck.uniqueInstance == nil {
            print("ui nil")
            Greendeck.uniqueInstance = Greendeck(clientId: clientId, clientSecret: clientSecret)
        }
        else if isTokenExpired(accessTokenJSONObject: self.accessTokenJSON){
            print("old ui exists")
            Greendeck.uniqueInstance = Greendeck(clientId: clientId, clientSecret: clientSecret)
        }
        else{
            print("new ui exists")
        }
        return Greendeck.uniqueInstance!
    }
    
    public init(){
    
        
    }
    
    public init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        
        let accessTokenJSONLocal = userDefaults.dictionary(forKey: "access_token_dict")
        
        if (accessTokenJSONLocal?.isEmpty)! {
            getAccessToken(id: self.clientId, secret: self.clientSecret, url: self.AuthEndPoint)
        }
        else{
            if isTokenExpired (accessTokenJSONObject: accessTokenJSONLocal!) {
                getAccessToken(id: self.clientId, secret: self.clientSecret, url: self.AuthEndPoint)
            } else {
                
                print("TOKEN received")
                
                self.accessTokenString =  accessTokenJSONLocal?["access_token"] as! String
                self.accessTokenJSON = accessTokenJSONLocal!
                userDefaults.set(self.accessTokenJSON, forKey: "access_token_dict")
                print("TOKEN:  \(self.accessTokenString)")
            }
        }
        
    }
    
    public func isTokenExpired(accessTokenJSONObject: Dictionary<String, Any>) -> Bool{
        do{
            
            if !accessTokenJSONObject.isEmpty{
                let expiresIn = Int64(accessTokenJSON["expires_in"] as! Double)
                print("expires_in: \(expiresIn)")
                let createdAt = Int64(accessTokenJSON["created_at"] as! Double)
                print("created at: \(createdAt)")
                
                let currentTime = Int64(Date().timeIntervalSince1970)
                print("current: \(currentTime)")
                
                return ((createdAt + expiresIn) < currentTime)
            }
            else{
            
                return true
            }
        
            
        }
        catch{
            return true
        }
        
    }
    
    public func getAccessToken(id: String, secret: String, url: String) {
        let defaultHeaders = ["Content-Type": "application/json"]
        let paramsDict = ["grant_type": "client_credentials", "client_id": id,
                          "client_secret": secret, "scope": "public read write"]
        
        AFWrapper.requestPOSTURL(url, postHeaders: defaultHeaders, postDict: paramsDict, success: {
            (JSONResponse) -> Void in
            //print(JSONResponse)
            
            self.accessTokenJSON = JSONResponse
            
            print("TOKEN received")
            
            if(self.isTokenExpired(accessTokenJSONObject: self.accessTokenJSON)){
                self.getAccessToken(id: id, secret: secret, url: url)
            }
            else{
                self.accessTokenString =   JSONResponse["access_token"] as! String
                self.userDefaults.set(JSONResponse, forKey: "access_token_dict")
                print("\(self.accessTokenString )")
            }
            
        }) {
            (error) -> Void in
            print(error)
        }
    }
    
    public func identify(){
        
        let personCodeLocal = userDefaults.string(forKey: "person_code")
        
        
        
        if (personCodeLocal?.isEmpty)!{
            let guestIdentifier = String(Int(arc4random_uniform(100000000) + 1))
            var guestIdentifierToSend = "greendeck_guest_\(guestIdentifier)"
            identify(identifier: guestIdentifierToSend)
        }
    }
    
    public func identify(identifier: String){
        
        let personCodeLocal = userDefaults.string(forKey: "person_code")
        
        if (personCodeLocal?.isEmpty)!{
            
            identify(identifier: identifier, properties: nil)
        }
        else{
        
            if (personCodeLocal?.contains("greendeck"))! {
                changeAlias(oldPersonCode: personCodeLocal!, newPersonCode: identifier)
            }
            else{
                identify(identifier: identifier, properties: nil)
            }
        }
        
        
    }
    
    public func identify(identifier: String, properties: Dictionary<String, Any>?){
        let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
        let url = "\(self.CustomerApiEndPoint)/?person_code=\(identifier)"
        
        let personCodeLocal = userDefaults.string(forKey: "person_code")
        
        if (personCodeLocal?.isEmpty)!{
            
            AFWrapper.requestGETURL(url, getHeaders: defaultHeaders, success: {
                (JSONResponse) -> Void in
                
                
                let person = JSONResponse["person"] as! Dictionary<String, Any>
                
                if !person.isEmpty {
                    
                    let personCode = person["person_code"] as! String
                    
                    self.customer = GreendeckPerson(personCode: personCode)
                    
                    self.userDefaults.set(personCode, forKey: "person_code")
                    
                    print("CUSTOMER with identifier: \(identifier) found")
                }
                else{
                    //customer with this identifier not present
                    print("CUSTOMER with identifier: \(identifier) not found. Creating customer now.")
                    if properties != nil {
                        self.createCustomer(identifier: identifier, properties: properties)
                    }
                    else {
                        self.createCustomer(identifier: identifier)
                    }
                }
                
            }) {
                (error) -> Void in
                print(error)
            }
        }
        else{
            
            if (personCodeLocal?.contains("greendeck"))! {
                changeAlias(oldPersonCode: personCodeLocal!, newPersonCode: identifier)
            }
            else{
                AFWrapper.requestGETURL(url, getHeaders: defaultHeaders, success: {
                    (JSONResponse) -> Void in
                    
                    
                    let person = JSONResponse["person"] as! Dictionary<String, Any>
                    
                    if !person.isEmpty {
                        
                        let personCode = person["person_code"] as! String
                        
                        self.customer = GreendeckPerson(personCode: personCode)
                        
                        self.userDefaults.set(personCode, forKey: "person_code")
                        
                        print("CUSTOMER with identifier: \(identifier) found")
                    }
                    else{
                        //customer with this identifier not present
                        print("CUSTOMER with identifier: \(identifier) not found. Creating customer now.")
                        if properties != nil {
                            self.createCustomer(identifier: identifier, properties: properties)
                        }
                        else {
                            self.createCustomer(identifier: identifier)
                        }
                    }
                    
                }) {
                    (error) -> Void in
                    print(error)
                }
            }
        }
        
    }
    
    public func createCustomer(identifier: String){
        createCustomer(identifier: identifier, properties: nil)
    }
    
    public func createCustomer(identifier: String, properties: Dictionary<String, Any>?){
        
        let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
        let url = "\(self.CustomerApiEndPoint)/?person_code\(identifier)"
        
        var customerToSend: Dictionary<String, Any> = [:]
        
        if properties != nil{
            customerToSend = getCustomerJSON(identifier: identifier, properties: properties!)
        }
        else{
            customerToSend = getCustomerJSON(identifier: identifier)
        }
        
        AFWrapper.requestPOSTURL(url,  postHeaders: defaultHeaders, postDict: customerToSend, success: {
            (JSONResponse) -> Void in
            
            let person = JSONResponse["person"] as! Dictionary<String, Any>
            
            if !person.isEmpty {
                
                let personCode = person["person_code"] as! String
                self.customer = GreendeckPerson(personCode: personCode)
                self.userDefaults.set(personCode, forKey: "person_code")
                
                print("CUSTOMER with identifier: \(identifier) created")
            }
            else{
                //customer with this identifier not present
                print("CUSTOMER with identifier: \(identifier) not created.")
            }
            
        }) {
            (error) -> Void in
            print(error)
        }
        
        
    }
    
    public func changeAlias(newPersonCode: String){
        
        let personCodeLocal = userDefaults.string(forKey: "person_code")
        
        if (personCodeLocal?.isEmpty)!{
            
            print("Error: changeAlias: No guest found")

        }
        else{
            
            if (personCodeLocal?.contains("greendeck"))! {
                let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
                var url = self.CustomerApiEndPoint
                url += "/alias?person_code=\(personCodeLocal)"
                
                var personToSend: Dictionary<String, Any> = [:]
                personToSend = ["person": ["new_person_code": newPersonCode]]
                
                AFWrapper.requestPUTURL(url, postHeaders: defaultHeaders, postDict: personToSend, success: {
                    (JSONResponse) -> Void in
                    
                    print("Success: changeAlias: \(personToSend)")
                    self.customer = GreendeckPerson(personCode: newPersonCode)
                    self.userDefaults.set(newPersonCode, forKey: "person_code")
                    
                }) {
                    (error) -> Void in
                    print(error)
                    print("Error: changeAlias: \(personToSend)")
                }

            }
            else{
                print("Error: changeAlias: No guest found")
            }
        }
        
        
    }
    
    public func changeAlias(oldPersonCode: String, newPersonCode: String){
    
        let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
        var url = self.CustomerApiEndPoint
        url += "/alias?person_code=\(oldPersonCode)"
        
        var personToSend: Dictionary<String, Any> = [:]
        personToSend = ["person": ["new_person_code": newPersonCode]]
        
        AFWrapper.requestPUTURL(url, postHeaders: defaultHeaders, postDict: personToSend, success: {
            (JSONResponse) -> Void in
            
            print("Success: changeAlias: \(personToSend)")
            self.customer = GreendeckPerson(personCode: newPersonCode)
            self.userDefaults.set(newPersonCode, forKey: "person_code")
            
        }) {
            (error) -> Void in
            print(error)
            print("Error: changeAlias: \(personToSend)")
        }

    }
    
    public func trackWithoutCustomer(eventName: String){
        trackWithoutCustomer(eventName: eventName, productCode: nil, properties: nil)
    }
    
    public func trackWithoutCustomer(eventName: String, properties: Dictionary<String, Any>){
        trackWithoutCustomer(eventName: eventName, productCode: nil, properties: properties)
    }
    
    private func trackWithoutCustomer(eventName: String, productCode: String?, properties: Dictionary<String, Any>?){
        
        let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
        let url = self.EventApiEndPoint
        
        var eventToSend: Dictionary<String, Any> = [:]

        if properties != nil{
            eventToSend = getEventJSON(eventName: eventName, personCode: nil, productCode: productCode, properties: properties!)
        }
        else{
            eventToSend = getEventJSON(eventName: eventName, personCode: nil, productCode: productCode)
        }
        
        AFWrapper.requestPOSTURL(url, postHeaders: defaultHeaders, postDict: eventToSend, success: {
            (JSONResponse) -> Void in
            
            print("EventTrackedWithoutCustomer: \(eventName)")
            
        }) {
            (error) -> Void in
            print(error)
            print("Error: EventTrackedWithoutCustomer: \(eventName)")
        }
        
    }
    
    public func track(eventName: String){
        track(eventName: eventName, productCode: nil, properties: nil)
    }
    
    public func track(eventName: String, properties: Dictionary<String, Any>){
        track(eventName: eventName, productCode: nil, properties: properties)
    }
    
    private func track(eventName: String, productCode: String?, properties: Dictionary<String, Any>?){
        
        let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
        let url = self.EventApiEndPoint
        
        var eventToSend: Dictionary<String, Any> = [:]
        
        let personCode = self.customer?.personCode
        
        if properties != nil{
            eventToSend = getEventJSON(eventName: eventName, personCode: personCode, productCode: productCode, properties: properties!)
        }
        else{
            eventToSend = getEventJSON(eventName: eventName, personCode: personCode, productCode: productCode)
        }
        
        AFWrapper.requestPOSTURL(url, postHeaders: defaultHeaders, postDict: eventToSend, success: {
            (JSONResponse) -> Void in
            
            print("EventTracked: \(eventName)")
            
        }) {
            (error) -> Void in
            print(error)
            print("Error: EventTracked: \(eventName)")
        }
        
    }
    
    public func transact(transactionCode: String, quantity: Float, price: Float, productCode: String){
        transact(transactionCode: transactionCode, quantity: quantity, price: price, productCode: productCode, properties: nil)
    }
    
    public func transact(transactionCode: String, quantity: Float, price: Float, productCode: String?, properties: Dictionary<String, Any>?){
        
        let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
        let url = self.TransactionEndPoint
        
        var transactionToSend: Dictionary<String, Any> = [:]
        var transactionDict: Dictionary<String, Any>? = nil
        var transactionInternalDict: Dictionary<String, Any>? = nil
        
        if properties != nil {
            transactionInternalDict = properties!
        }
        else{
            
        }
        
        let personCode = self.customer?.personCode
        
        if personCode != nil && personCode != "" {
            
            transactionInternalDict?["transactionCode"] = transactionCode
            transactionInternalDict?["price"] = price
            transactionInternalDict?["quantity"] = quantity
            transactionInternalDict?["person_code"] = personCode
            
            if productCode != nil && productCode != ""{
                transactionInternalDict?["product_code"] = productCode
            }
            else{
                transactionInternalDict?["product_code"] = productCode
            }
            
            transactionDict = ["transaction": transactionInternalDict!]
            
            transactionToSend = transactionDict!
            
            AFWrapper.requestPOSTURL(url, postHeaders: defaultHeaders, postDict: transactionToSend, success: {
                (JSONResponse) -> Void in
                
                print("Transaction: \(transactionCode)")
                
            }) {
                (error) -> Void in
                print(error)
                print("Error: Transaction: \(transactionCode)")
            }
            
        }
        else{
        
            print("Error: Transaction: No customer found")
        }
        
    }
    
    public func fetch(productCode: String?, success:@escaping (Dictionary<String, Any>) -> Void, failure:@escaping (String) -> Void){
        let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
        var url = self.FetchApiEndPoint
        var personCode = self.customer?.personCode
        
        if productCode != nil && productCode != "" {
            if personCode != nil && personCode != ""{
                
                personCode = personCode?.replacingOccurrences(of: ".", with: "%2E").replacingOccurrences(of: "@", with: "%40")
                let newProductCode = productCode?.replacingOccurrences(of: ".", with: "%2E").replacingOccurrences(of: "@", with: "%40")
                
                url += "?person_code=\(personCode ?? "")&product_code=\(newProductCode ?? "")"
                
                print(url)
                
                AFWrapper.requestGETURL(url, getHeaders: defaultHeaders, success: {
                    (JSONResponse) -> Void in
                    
                    print("Fetch: \(AFWrapper.dictToJSONString(dictionary: JSONResponse))")
                    
                    success(JSONResponse)
                    
                }) {
                    (error) -> Void in
                    print(error)
                    failure("Error: Network")
                    print("Error: Fetch: \(String(describing: productCode))")
                }
            }
            else{
                print("Error: Fetch: No customer found")
                failure("Error: No customer found")
            }
        }
        else{
            print("Error: Fetch: No productCode found")
            failure("Error: No productCode found")
        }
        
    }
    
    public func setUserProperties(propertyName: String, propertyValue: Any){
    
        let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
        var url = self.FetchApiEndPoint
        var personCode = self.customer?.personCode
        
        var internalDict: Dictionary<String, Any> = [propertyName: propertyValue]
        
        var postDict = setCustomerJSONObject(properties: internalDict)
        
        if personCode != nil && personCode != ""{
            
            personCode = personCode?.replacingOccurrences(of: ".", with: "%2E").replacingOccurrences(of: "@", with: "%40")
            
            url += "?person_code=\(personCode ?? "")"
            
            print(url)
            
            AFWrapper.requestPUTURL(url, postHeaders: defaultHeaders, postDict: postDict, success: {
                (JSONResponse) -> Void in

                print("SetUserProperties: \(AFWrapper.dictToJSONString(dictionary: JSONResponse))")
                
            }) {
                (error) -> Void in
                print(error)
                print("Error: SetUserProperties")
            }
        }
        else{
            print("Error: SetUserProperties: No customer found")
        }
        
    }
    
    public func incrementUserProperties(propertyName: String, incrementBy: Float){
        
        let defaultHeaders = ["Content-Type": "application/json", "Authorization": "Bearer \(self.accessTokenString)"]
        var url = self.FetchApiEndPoint
        var personCode = self.customer?.personCode
        
        var internalDict: Dictionary<String, Any> = [propertyName: incrementBy]
        
        var postDict = incCustomerJSONObject(properties: internalDict)
        
        if personCode != nil && personCode != ""{
            
            personCode = personCode?.replacingOccurrences(of: ".", with: "%2E").replacingOccurrences(of: "@", with: "%40")
            
            url += "?person_code=\(personCode ?? "")"
            
            print(url)
            
            AFWrapper.requestPUTURL(url, postHeaders: defaultHeaders, postDict: postDict, success: {
                (JSONResponse) -> Void in
                
                print("SetUserProperties: \(AFWrapper.dictToJSONString(dictionary: JSONResponse))")
                
            }) {
                (error) -> Void in
                print(error)
                print("Error: SetUserProperties")
            }
        }
        else{
            print("Error: SetUserProperties: No customer found")
        }
        
    }
    
    private func setCustomerJSONObject(properties: Dictionary<String, Any>) ->Dictionary<String, Any>{
        
        var custInternalDict: Dictionary<String, Any> = [:]
        
        custInternalDict["person"] = methodJSONFromMap(method: "$set", properties: properties)
        
        return custInternalDict
        
    }
    
    private func incCustomerJSONObject(properties: Dictionary<String, Any>) ->Dictionary<String, Any>{
        
        var custInternalDict: Dictionary<String, Any> = [:]
        
        custInternalDict["person"] = methodJSONFromMap(method: "$inc", properties: properties)
        
        return custInternalDict
        
    }
    
    
    private func methodJSONFromMap(method: String, properties: Dictionary<String, Any>) ->Dictionary<String, Any>{
    
        var methodInternalDict: Dictionary<String, Any> = [:]
        
        methodInternalDict[method] = properties
        
        return methodInternalDict
        
    }
    
    public func getCustomerJSON(identifier: String) ->Dictionary<String, Any>{
    
        let customerDict = ["person": ["person_code": identifier]]
        return customerDict
        
    }
    
    public func getCustomerJSON(identifier: String, properties: Dictionary<String, Any>?) ->Dictionary<String, Any>{
        
        var custInternalDict: Dictionary<String, Any> = [:]
        
        if properties != nil {
            custInternalDict = properties!
            custInternalDict["person_code"]  = identifier
        }
        else{
            custInternalDict = ["person_code": identifier] as [String : Any]
        }
       
        let customerDict = ["person": custInternalDict]
        return customerDict
    }
    
    public func getEventJSON(eventName: String, personCode: String!, productCode: String!) ->Dictionary<String, Any>{
        
        var eventInternalDict = ["event_name": eventName] as [String : Any]
        if personCode != nil {
            eventInternalDict["person_code"] = personCode
        }
        if productCode != nil {
            eventInternalDict["product_code"] = productCode
        }
        let eventDict = ["event": eventInternalDict]
        return eventDict
    }
    
    public func getEventJSON(eventName: String, personCode: String!, productCode: String!, properties: Dictionary<String, Any>?) ->Dictionary<String, Any>{
      
        
        var eventInternalDict: Dictionary<String, Any> = [:]
        if properties != nil {
            eventInternalDict = properties!
            eventInternalDict["event_name"]  = eventName
        }
        else{
            eventInternalDict = ["event_name": eventName] as [String : Any]
        }
        if personCode != nil {
            eventInternalDict["person_code"] = personCode
        }
        if productCode != nil {
            eventInternalDict["product_code"] = productCode
        }
    
        let eventDict = ["event": eventInternalDict]
        return eventDict
    }
}
