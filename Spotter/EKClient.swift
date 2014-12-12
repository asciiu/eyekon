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
    let stories: Firebase = Firebase(url: "https://eyekon.firebaseio.com/stories")
    let userStories: Firebase = Firebase(url: "https://eyekon.firebaseio.com/user-stories")
    var usersURL: Firebase = Firebase(url: "https://eyekon.firebaseio.com/users")
    var userHomeURL: Firebase?
    var userPostsRef: Firebase?
    var username: String = ""
    var context: NSManagedObjectContext?
    
    required override init() {
        super.init()
        
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        
        if (self.appRef.authData != nil) {
            authData = self.appRef.authData
            userHomeURL = self.usersURL.childByAppendingPath(self.appRef.authData.uid)
            userPostsRef = userHomeURL!.childByAppendingPath("posts")
        }

        // invoked after login
        fireRef.observeAuthEventWithBlock({ authData in
            if authData != nil {
                
                self.authData = authData
                self.userHomeURL = self.usersURL.childByAppendingPath(authData.uid)
                self.userPostsRef = self.userHomeURL!.childByAppendingPath("posts")
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
    
    func sendData(post: Dictionary<String, String>, toUserID: String) {
        let postURL = url + "/users/" + toUserID + "/posts"
        
        println("Sending: " + postURL)
        
        let postRef = Firebase(url: postURL)
        postRef.setValue(post)
    }
}

let EKClient = FBClient()


let kThumbnailKB = 50 * 1024
let kImageKB = 300 * 1024

func compressForUpload(original: UIImage, maxFileSize: Int) -> NSData {
    
    let maxCompression: CGFloat = 0.1
    var compression: CGFloat = 0.9
    
    var imageData: NSData = UIImageJPEGRepresentation(original, compression);
    
    while (imageData.length > maxFileSize && compression > maxCompression) {
        compression -= 0.1
        imageData = UIImageJPEGRepresentation(original, compression)
    }
    
    return imageData
}