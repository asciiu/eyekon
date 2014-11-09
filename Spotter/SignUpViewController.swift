//
//  SignUpViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/8/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    var alertController: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.alertController = UIAlertController(title:"Error!",
            message: "Please enter a valid email/password.",
            preferredStyle:UIAlertControllerStyle.Alert)
        
        let okAction: UIAlertAction = UIAlertAction(title: "ok", style: UIAlertActionStyle.Cancel, handler: nil)
        self.alertController!.addAction(okAction)

    }

    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.topItem!.title = "Sign Up"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func createUser(sender: AnyObject) {
        let username = self.emailField.text
        let password = self.passwordField.text
        
        if (username == "" || password == "") {
            self.alertController!.message = "Please enter a valid email/password."
            self.presentViewController(self.alertController!, animated: true, completion: {})
            return
        }
        
        fireRef.createUser(username, password: password) { error -> Void in
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
                        println("invalid password")
                        // Hand invalid password
                        break
                    default:
                        println(errorCode)
                        break
                    }
                }
                
                self.presentViewController(self.alertController!, animated: true, completion: {})

            } else {
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewControllerWithIdentifier("tab") as UIViewController
                
                self.navigationController?.pushViewController(controller, animated: true)
                self.navigationController?.modalPresentationCapturesStatusBarAppearance = true
            }
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField === self.emailField) {
            self.passwordField.becomeFirstResponder()
        } else if (textField === self.passwordField) {
            self.createUser(self)
        }
        
        return true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
