//
//  SignUpViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/8/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class SignUpViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var firstNameField: UITextField!
    @IBOutlet var lastNameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    var alertController: UIAlertController?
    
    var context: NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.alertController = UIAlertController(title:"Error!",
            message: "Please enter a valid email/password.",
            preferredStyle:UIAlertControllerStyle.Alert)
        
        let okAction: UIAlertAction = UIAlertAction(title: "ok", style: UIAlertActionStyle.Cancel, handler: nil)
        self.alertController!.addAction(okAction)
        
        // create context to save core data
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
    }

    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.topItem!.title = "Sign Up"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func authenticateUser(email: String, password: String, first: String, last: String) {
        
        fireRef.authUser(email, password: password) {
            error, authData in
            
            if (error != nil) {
                // an error occurred while attempting login
                if let errorCode = FAuthenticationError(rawValue: error.code) {
                    switch (errorCode) {
                    case .UserDoesNotExist:
                        println("does not exist")
                        // Handle invalid user
                        break
                    case .InvalidEmail:
                        println("invalid email")
                        // Handle invalid email
                        break
                    case .InvalidPassword:
                        println("invalid password")
                        // Hand invalid password
                        break
                    default:
                        println(errorCode)
                        break
                    }
                }
                
                self.alertController?.message = "Unable to login"
                self.presentViewController(self.alertController!, animated: true, completion: {})
                
            } else {
                // add the user data to the system
                let newUser = [
                    "provider": authData.provider,
                    "email": email,
                    "first": first,
                    "last": last
                ]
                
                //self.saveUserData(authData.uid, first: first, last: last)
                
                //EKClient.usersURL.childByAppendingPath(authData.uid).setValue(newUser)
                //EKClient.authData = authData!
                //EKClient.username = first + " " + last
                
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewControllerWithIdentifier("TabView") as UIViewController
                
                self.navigationController?.pushViewController(controller, animated: true)
                self.navigationController?.modalPresentationCapturesStatusBarAppearance = true
            }
        }
    }
    
    @IBAction func createUser(sender: AnyObject) {
        let email = self.emailField.text
        let password = self.passwordField.text
        let first = self.firstNameField.text
        let last = self.lastNameField.text
        
        if (first == "") {
            self.alertController!.message = "Please enter your first name"
            self.presentViewController(self.alertController!, animated: true, completion: {})
            return

        }
        if (last == "") {
            self.alertController!.message = "Please enter your last name"
            self.presentViewController(self.alertController!, animated: true, completion: {})
            return
        }
        if (email == "" || password == "" || first == "" || last == "") {
            self.alertController!.message = "Please enter a valid email/password."
            self.presentViewController(self.alertController!, animated: true, completion: {})
            return
        }
        
        fireRef.createUser(email, password: password) { error -> Void in
            if (error != nil) {
                // an error occurred while attempting login
                if let errorCode = FAuthenticationError(rawValue: error.code) {
                    switch (errorCode) {
                    case .EmailTaken:
                        self.alertController?.message = "Email already registered!"
                        break
                    case .InvalidEmail:
                        self.alertController?.message = "Invalid email!"
                        break
                    case .InvalidPassword:
                        // Hand invalid password
                        break
                    default:
                        println(errorCode)
                        break
                    }
                }
                
                self.presentViewController(self.alertController!, animated: true, completion: {})

            } else {
                
                self.authenticateUser(email, password: password, first: first, last: last)
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField === self.firstNameField) {
            self.lastNameField.becomeFirstResponder()
        } else if (textField === self.lastNameField) {
            self.emailField.becomeFirstResponder()
        } else if (textField === self.emailField) {
            self.passwordField.becomeFirstResponder()
        } else if (textField === self.passwordField) {
            self.createUser(self)
        }
        
        return true
    }
    
    // Save the user data to local storage so we can retrieve from local storage later
//    func saveUserData(uid: String, first: String, last: String) {
//        let user: User = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.context!) as User
//        user.first = first
//        user.last = last
//        user.uid = uid
//        
//        var error: NSError?
//        if( !user.managedObjectContext!.save(&error)) {
//            println("SignUpViewController: count not save new user\(error?.localizedDescription)")
//        }
//    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
