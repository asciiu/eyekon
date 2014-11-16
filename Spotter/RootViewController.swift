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
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if (EKClient.authData != nil) {
            
            self.performSegueWithIdentifier("FromRootToTab", sender: self)
            
//            self.navigationController?.navigationBarHidden = false
//            let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            let controller = storyboard.instantiateViewControllerWithIdentifier("TabView") as UIViewController
//            
//            self.navigationController?.modalPresentationCapturesStatusBarAppearance = true
//            self.navigationController?.pushViewController(controller, animated: false)
        } else {
            self.navigationController?.navigationBarHidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func handleLogout(notification: NSNotification) {
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

}
