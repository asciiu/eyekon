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
        let controller = self.sourceViewController as UIViewController
        //controller.navigationController?.pushViewController(destinationViewController as UIViewController, animated: false)
        
        controller.view.window?.rootViewController?.presentViewController(destinationViewController as UIViewController, animated:false, completion:nil)
        
        //self.sourceViewController.presentViewController(destinationViewController as UIViewController, animated: false, completion: nil)
    }
}

class TabViewController: UITabBarController, UITabBarDelegate, CaptureViewControllerDelegate, StoryViewControllerDelegate {
    
    let highlightColor = UIColor(red:0.0, green:122.0/255.0, blue:1.0, alpha:1.0)
    let subMenuRadius:CGFloat = 25
    let menuRadius:CGFloat = 125
    var radialMenu: RadialMenu = RadialMenu(menus: [])
    var captureButton: UIButton = UIButton()
    var navController: UINavigationController?
    var storyController: StoryViewController?
    var pickerController: CTAssetsPickerController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.createCaptureButton()
       
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
   
    func createCaptureButton() {
        let toolbarFrame = self.tabBar.frame
        let width = toolbarFrame.size.height - 3
        let frame = CGRectMake(0, 0, width, width)
        
        let captureButton = UIButton(frame: frame)
        captureButton.setImage(UIImage(named: "add.png"), forState: UIControlState.Normal)
        
        captureButton.layer.cornerRadius = width / 2
        captureButton.alpha = 0.7
        captureButton.center = CGPointMake(self.tabBar.center.x, self.tabBar.frame.size.height/2)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "pressedButton:")
        longPress.minimumPressDuration = 0.15
        captureButton.addGestureRecognizer(longPress)
        self.captureButton = captureButton
        
        self.radialMenu = RadialMenu(menus: [createSubMenu("camera.png"),
            createSubMenu("movie.png"),
            createSubMenu("gallery.png")], radius: menuRadius)
        self.radialMenu.openDelayStep = 0.00
        self.radialMenu.closeDelayStep = 0.00
        self.radialMenu.minAngle = 220
        self.radialMenu.maxAngle = 320
        self.radialMenu.alpha = 0.75

        self.radialMenu.onOpening = {
            // FIXME: Add transitions
            //self.microphoneButtonImageView.alpha = 0.0
            //self.stopButton.alpha = 1.0
        }

        self.radialMenu.onClosing = {
            // FIXME: Add transitions
            //self.microphoneButtonImageView.alpha = 1.0
            //self.stopButton.alpha = 0.0
        }

        radialMenu.onHighlight = { subMenu in
            subMenu.backgroundColor = self.highlightColor
        }

        radialMenu.onUnhighlight = { subMenu in
            subMenu.backgroundColor = UIColor.redColor()
        }

        radialMenu.onClose = {
            for subMenu in self.radialMenu.subMenus {
                if (subMenu.backgroundColor != UIColor.redColor()) {
                    switch subMenu.tag {
                    case 0:
                        self.newCapture(0)
                        break
                    case 1:
                        println("movie")
                        break
                    case 2:
                        self.newCapture(2)
                        break
                    default:
                        println("unrecognized")
                    }
                }
                subMenu.backgroundColor = UIColor.redColor()
            }
        }
        
        radialMenu.userInteractionEnabled = false
        radialMenu.center = CGPointMake(self.tabBar.center.x, self.tabBar.frame.size.height/2)
        self.tabBar.addSubview(self.radialMenu)
        self.tabBar.addSubview(captureButton)
    }
    
    func createSubMenu(icon: String) -> RadialSubMenu {
        let img = UIImageView(image: UIImage(named: icon)!)
        let subMenu = RadialSubMenu(imageView: img)
        subMenu.frame = CGRect(x: 0.0, y: 0.0, width: self.subMenuRadius*2, height: self.subMenuRadius*2)
        subMenu.layer.cornerRadius = self.subMenuRadius
        subMenu.backgroundColor = UIColor.redColor()
        img.center = subMenu.center
        
        return subMenu
    }
    
    func pressedButton(gesture:UIGestureRecognizer) {
        switch(gesture.state) {
        case .Began:
            radialMenu.openAtPosition(self.captureButton.center)
            break
        case .Changed:
            radialMenu.moveAtPosition(gesture.locationInView(self.tabBar))
            break
        case .Ended:
            radialMenu.close()
            break
        default:
            break
        }
    }

    func doneWithLibrary(sender: AnyObject) {
        
        let assets: [AnyObject] = self.pickerController!.selectedAssets
        let images: [UIImage] = assets.map({ (var asset) -> UIImage in
            let a = asset as ALAsset
            
            let representation = a.defaultRepresentation()
            let cgImage = representation.fullResolutionImage().takeUnretainedValue()
            let orientation = UIImageOrientation(rawValue: representation.orientation().rawValue)!
            
            return UIImage(CGImage: cgImage, scale: 1.0, orientation: orientation)!
        })
        
        self.storyController!.createNewStory(images)
        self.navController!.popToViewController(self.storyController!, animated: true)
        self.pickerController = nil

        //self.addImages(images)
        //picker.dismissViewControllerAnimated(true, completion: nil)
        //self.addingImage = false
    }
    
    func storyViewControllerDidSave() {
        self.storyController!.dismissViewControllerAnimated(true, completion: nil)
        self.navController!.dismissViewControllerAnimated(true, completion: nil)
        self.storyController = nil
        self.navController = nil
        
        self.selectedIndex = 1
        self.selectedViewController!.viewWillAppear(true)
    }
    
    func captureViewControllerDidFinish(capturedImages: [UIImage]) {
        self.storyController!.createNewStory(capturedImages)
        self.navController!.popToViewController(self.storyController!, animated: true)
    }
    
    func newCapture(type: Int) {
        
        let navigationController = UINavigationController()
        navigationController.navigationBar.barStyle = UIBarStyle.Black
        navigationController.navigationBar.translucent = true
        navigationController.navigationBar.tintColor = UIColor.whiteColor()
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let storyViewController = storyBoard.instantiateViewControllerWithIdentifier("StoryViewController") as StoryViewController
        storyViewController.delegate = self
        navigationController.pushViewController(storyViewController, animated: false)
        
        storyViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
            target: self, action: "cancelCapture:")
        
        switch (type) {
        case 0:
            let captureViewController = storyBoard.instantiateViewControllerWithIdentifier("CaptureViewController") as CaptureViewController
            navigationController.pushViewController(captureViewController, animated: false)
            
            captureViewController.delegate = self
            captureViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
                target: self, action: "cancelCapture:")
            break
        case 1:
            break
        case 2:
            let pickerController: CTAssetsPickerController = CTAssetsPickerController()
            navigationController.pushViewController(pickerController, animated: false)
            pickerController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
                target: self, action: "cancelCapture:")
            pickerController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done,
                target: self, action: "doneWithLibrary:")
            self.pickerController = pickerController
        
            
            //picker.delegate = self
            //self.presentViewController(picker, animated: true, completion: nil)
            
            //storyViewController.addPhotoFromLibrary(self)
            break
        default:
            println("Unrecognized capture type")
        }
        
        self.presentViewController(navigationController, animated: true, completion: nil)
        self.navController = navigationController
        self.storyController = storyViewController
    }
    
    func cancelCapture(sender: AnyObject) {
        self.storyController!.dismissViewControllerAnimated(true, completion: nil)
        self.navController!.dismissViewControllerAnimated(true, completion: nil)
        self.storyController = nil
        self.navController = nil
    }
}
