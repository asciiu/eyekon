//
//  EKServer.swift
//  Eyekon
//
//  Created by LV426 on 11/8/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

let fireRef: Firebase = Firebase(url: "https://eyekon.firebaseio.com")

class EKServer: NSObject {
    
    var authData: FAuthData?
    
    required override init() {
        super.init()
        
        authData = fireRef.authData
//        fireRef.observeAuthEventWithBlock({ authData in
//            if authData != nil {
//                self.authData = authData
//                println("logged in")
//            }
//        })
    }
    
    func logout() {
        fireRef.unauth()
    }
}

let Server = EKServer()