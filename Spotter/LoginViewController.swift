//
//  LoginViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/8/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    
    var alertController: UIAlertController?
    var server: EKServer = EKServer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.alertController = UIAlertController(title:"Login Error!",
            message: "Please enter a valid email/password.",
            preferredStyle:UIAlertControllerStyle.Alert)
        
        let okAction: UIAlertAction = UIAlertAction(title: "ok", style: UIAlertActionStyle.Cancel, handler: nil)
        self.alertController!.addAction(okAction)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.navigationBar.topItem!.title = "Login"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func authenticateUser(sender: AnyObject) {
        
        let email = self.emailField.text
        let password = self.passwordField.text
        
        if (email == "" || password == "") {
            self.alertController?.message = "Please enter a valid email/password."
            self.presentViewController(self.alertController!, animated: true, completion: {})
            return
        }
        
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
                
                self.alertController?.message = "Invalid email/password"
                self.presentViewController(self.alertController!, animated: true, completion: {})
                
            } else {
                //self.performSegueWithIdentifier("FromLoginToTab", sender: self)
                self.showApplication()
            }
        }
    }
    
    func showApplication() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewControllerWithIdentifier("tab") as UIViewController
       
        //self.navigationController?.modalPresentationCapturesStatusBarAppearance = true
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField === self.emailField) {
            self.passwordField.becomeFirstResponder()
        } else if (textField === self.passwordField) {
            self.authenticateUser(self)
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
