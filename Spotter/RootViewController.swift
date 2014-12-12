//
//  RootViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/8/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

let EKLogoutNotification = "EKLogoutNotification"

class RootViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleLogout:", name: EKLogoutNotification, object: nil)
        
        let credentialsProvider = AWSCognitoCredentialsProvider.credentialsWithRegionType(AWSRegionType.USEast1,
            accountId: "792505883474",
            identityPoolId: "us-east-1:8d3c3041-f0ef-41a4-bae7-23d1daffe92d",
            unauthRoleArn: "arn:aws:iam::792505883474:role/Cognito_EyekonUnauth_DefaultRole",
            authRoleArn: "arn:aws:iam::792505883474:role/Cognito_EyekonAuth_DefaultRole")
        
        let configuration: AWSServiceConfiguration = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: credentialsProvider)
        
        let serviceManager = AWSServiceManager.defaultServiceManager()
        serviceManager.setDefaultServiceConfiguration(configuration)
    }
    
    override func viewWillAppear(animated: Bool) {
        
//        if (EKClient.authData != nil) {
//            self.performSegueWithIdentifier("FromRootToTab", sender: self)
//        } else {
            self.navigationController?.navigationBarHidden = true
       // }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func handleLogout(notification: NSNotification) {
        // pop any controllers off the stack that are still there from 
        // a login or signup
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func unwindToRoot(unwindSegue: UIStoryboardSegue) {
    }

}
