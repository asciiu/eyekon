//
//  TabViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/8/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class PushNoAnimationSegue: UIStoryboardSegue {
    override func perform() {
        //self.sourceViewController.pushViewController(destinationViewController as UIViewController, animated: false)
        
        //let controller = self.sourceViewController as UIViewController
        //controller.navigationController?.pushViewController(destinationViewController as UIViewController, animated: false)
        
        self.sourceViewController.presentViewController(destinationViewController as UIViewController, animated: false, completion: nil)
    }
}

class TabViewController: UITabBarController, UITabBarDelegate {

    var captureController: UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let toolbarFrame = self.tabBar.frame
        let width = toolbarFrame.size.height - 3
        let captureButton = UIButton(frame: CGRectMake(0, 0, width, width))
        captureButton.backgroundColor = UIColor.whiteColor()
        captureButton.layer.cornerRadius = width / 2
        captureButton.alpha = 0.7
        captureButton.center = CGPointMake(self.tabBar.center.x, self.tabBar.frame.size.height/2)
        
        captureButton.addTarget(self, action: "newCapture:", forControlEvents: UIControlEvents.TouchUpInside)
        //self.view.addSubview(captureButton)
        
        self.tabBar.addSubview(captureButton)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.topItem!.title = "Eyekon"
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func newCapture(sender: AnyObject) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let storyViewController = storyBoard.instantiateViewControllerWithIdentifier("StoryViewController") as StoryViewController
        
        let navController = UINavigationController()
        navController.navigationBar.barStyle = UIBarStyle.Black
        navController.navigationBar.translucent = true
        navController.navigationBar.tintColor = UIColor.whiteColor()
        navController.pushViewController(storyViewController, animated: false)
        
        storyViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
            target: self, action: "cancelCapture:")

        self.presentViewController(navController, animated: true, completion: nil)
        self.captureController = navController
    }
    
    func cancelCapture(sender: AnyObject) {
        self.captureController?.dismissViewControllerAnimated(true, completion: nil)
        self.captureController = nil
    }
}
