//
//  BingTranslate.swift
//  DriveinKorea
//
//  Created by DongningWang on 4/14/15.
//  Copyright (c) 2015 wandonye. All rights reserved.
//

import Foundation
/*
class BingTranslate: NSObject {
    
    private struct internalParas {
        static let SCOPE_URL: NSString = "http://api.microsofttranslator.com"
        static let OAUTH_URL: NSString = "https://datamarket.accesscontrol.windows.net/v2/OAuth2-13"
        static let AZURE_TRANSLATE_API_URL: NSString = "http://api.microsofttranslator.com/V2/Ajax.svc/Translate?%s"
        static let GRANT_CLIENT_CREDENTIALS_ONLY: NSString = "client_credentials"
    }
    
    private var clientId: NSString = "wangwangxianbei_2014"
    private var clientSecret: NSString = "ZhzP5sHEpYemPvnccRxO5dfc6Oytxi2ZrfZfDwTQG60="
    private var authParas: NSDictionary
    
    private var last_auth_token_refresh: NSString = ""
    private var token: NSString = ""
    private var expiry: NSDate? = nil
    
    func setParas(client_id:NSString, client_secret:NSString) ->Void {
        self.authParas = ["client_id": self.clientId , "client_secret": self.clientSecret, "scope": internalParas.SCOPE_URL, "grant_type":internalParas.GRANT_CLIENT_CREDENTIALS_ONLY] as NSDictionary
    }
    
    init(client_id:NSString, client_secret:NSString){
        super.init()
        self.clientId = client_id
        self.clientSecret = client_secret
        self.last_auth_token_refresh = ""
        self.token = getAuthenticationToken()
    }
    
    func getAuthenticationToken() ->NSString {
        let urlPath: String = internalParas.SCOPE_URL
        var url: NSURL = NSURL(string: urlPath)!
        var request: NSURLRequest = NSURLRequest(URL: url)
        
        request.setValuesForKeysWithDictionary(self.authParas)
        
        var response: AutoreleasingUnsafeMutablePointer<NSURLResponse?>=nil
        var error: NSErrorPointer = nil
        var dataVal: NSData =  NSURLConnection.sendSynchronousRequest(request, returningResponse: response, error:nil)!
        var err: NSError
        println(response)
        var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
        println("Synchronous\(jsonResult)")
        
        return ""
    }
    
    func isValid() ->Bool {
        if (self.token.length<=0 || self.expiry==nil){
            return false
        }
        //check 10 mins
        if (self.expiry!.timeIntervalSinceNow < -560){
            return false
        }
        return true
    }
}
*/