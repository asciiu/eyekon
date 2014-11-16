//
//  EKServer.swift
//  Eyekon
//
//  Created by LV426 on 11/8/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

let url = "https://eyekon.firebaseio.com"
let fireRef: Firebase = Firebase(url: url)

class FBClient: NSObject {
    
    var authData: FAuthData?
    let appRef: Firebase = Firebase(url: "https://eyekon.firebaseio.com")
    var usersURL: Firebase = Firebase(url: "https://eyekon.firebaseio.com/users")
    var userHomeURL: Firebase?
    var userPostsRef: Firebase?
    var username: String = ""
    var context: NSManagedObjectContext?
    var user: User?
    
    required override init() {
        super.init()
        
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        
        if (self.appRef.authData != nil) {
            authData = self.appRef.authData
            userHomeURL = self.usersURL.childByAppendingPath(self.appRef.authData.uid)
            userPostsRef = userHomeURL!.childByAppendingPath("posts")
            
//            let fullName = self.fetchUserName(self.appRef.authData.uid)
//            if (fullName != nil) {
//                username = fullName!
//            }
        }

        // invoked after login
        fireRef.observeAuthEventWithBlock({ authData in
            if authData != nil {
                
                self.authData = authData
                self.userHomeURL = self.usersURL.childByAppendingPath(authData.uid)
                self.userPostsRef = self.userHomeURL!.childByAppendingPath("posts")
                
//                let fullName = self.fetchUserName(authData.uid)
//                if (fullName != nil) {
//                    self.username = fullName!
//                }
            }
        })
    }
    
    func logout() {
        self.appRef.unauth()
        self.authData = nil
        self.userHomeURL = nil
        self.userPostsRef = nil
    }
    
    func authenticateUser(email: String, password: String) -> Bool {
        
        return true
    }
    
//    func fetchUserName(uid: String) -> String? {
//        
//        let entityDesc: NSEntityDescription = NSEntityDescription.entityForName("User", inManagedObjectContext: self.context!)!
//        
//        // create a fetch request with the entity description
//        // this works like a SQL SELECT statement
//        let request: NSFetchRequest = NSFetchRequest()
//        request.entity = entityDesc
//        
//        // set a predicate to filter results
//        // remove the predicate to fetch all results
//        let pred: NSPredicate = NSPredicate(format: "(uid = %@)", argumentArray: [uid])
//        request.predicate = pred
//        
//        //var match: NSManagedObject?
//        var error: NSError?
//        
//        let objects: [AnyObject] = self.context!.executeFetchRequest(request, error: &error)!
//        
//        if objects.count != 0 {
//            let match: User = objects[0] as User
//            self.user = match
//            
//            // address and phone are the entity's attributes
//            let first = match.valueForKey("first") as String
//            let last = match.valueForKey("last") as String
//            return first + " " + last
//        }
//        
//        return nil
//    }
    
    func sendData(post: Dictionary<String, String>, toUserID: String) {
        let postURL = url + "/users/" + toUserID + "/posts"
        
        println("Sending: " + postURL)
        
        let postRef = Firebase(url: postURL)
        postRef.setValue(post)
    }
}

let EKClient = FBClient()