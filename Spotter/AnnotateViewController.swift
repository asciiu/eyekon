//
//  AnnotateViewController.swift
//  Spotter
//
//  Created by LV426 on 9/2/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class AnnotateViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var imageView: UIImageView!
    //@IBOutlet var previousBtn: UIButton!
    //@IBOutlet var nextBtn: UIButton!
    @IBOutlet var textView: UITextView!

    var frameNum: Int = 0
    var keyboardToolBar: UIToolbar?
    var keyboardToolBarTextView: UITextView?
    var dataFrames: [Frame]?
    var secondaryImageView: UIImageView?
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let toolbarRect = CGRectMake(0, 0, self.view.frame.width, 44)
        
        // setup a textview on the keyboardToolBar
        self.keyboardToolBar = UIToolbar(frame: toolbarRect)
        self.keyboardToolBarTextView = UITextView(frame: toolbarRect)
        self.keyboardToolBarTextView!.returnKeyType = UIReturnKeyType.Done
        self.keyboardToolBarTextView!.delegate = self

        self.keyboardToolBar!.addSubview(self.keyboardToolBarTextView!)
        self.textView.inputAccessoryView = self.keyboardToolBar
        
        // setup the swipe gestures so the user can swipe left and right
        self.view.userInteractionEnabled = true

        let swipeLeft: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipe:")
        let swipeRight: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipe:")

         // Setting the swipe direction.
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right

        // Adding the swipe gesture on image view
        self.view.addGestureRecognizer(swipeLeft)
        self.view.addGestureRecognizer(swipeRight)
        
        self.view.clipsToBounds = true
        
        // this image view is used to animate the swipe
        let viewFrame = self.imageView.frame
        let secondFrame = CGRectMake(viewFrame.width, viewFrame.origin.y, viewFrame.width, viewFrame.height)
        
        let secondaryImageView = UIImageView(frame: secondFrame)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        self.frameNum = SharedDataFrame.dataFrame!.frameNumber
        self.dataFrames = SharedDataFrameSet.sortedDataFrames()
        self.displayImageAtIndex(self.frameNum)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Custom Stuff
    func displayImage(image: UIImage) {
        let origin = self.imageView.frame.origin
        let frameWidth = self.imageView.frame.width
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        self.imageView.image = image
        
        if (SharedDataFrame.dataFrame!.annotation != nil && SharedDataFrame.dataFrame!.annotation != "") {
            self.textView.hidden = false
            self.textView.text = SharedDataFrame.dataFrame!.annotation
        } else {
            self.resetAnnotationView()
        }
    }
    
    func displayImageAtIndex(index: Int) {
        
        if (index >= self.dataFrames!.count) {
            return
        } else if ( index < 0) {
            return
        }
        
        let dataFrame: Frame = self.dataFrames![index]
        SharedDataFrame.dataFrame = dataFrame

        let image = UIImage(data: dataFrame.imageData)
        self.displayImage(image)
        
        self.frameNum = index

        // hide next button if last image
//        if(self.frameNum == self.dataFrames!.count-1) {
//            self.nextBtn.hidden = true
//        } else {
//            self.nextBtn.hidden = false
//        }
//        
//        // hide prev button if first image
//        if(self.frameNum == 0) {
//            self.previousBtn.hidden = true
//        } else {
//            self.previousBtn.hidden = false
//        }
    }
    
    func handleSwipe(swipe: UISwipeGestureRecognizer) {

        if swipe.direction == UISwipeGestureRecognizerDirection.Left {
            
            self.displayImageAtIndex(self.frameNum+1)
            
//            if self.segmentIndex! < self.segments!.count - 1 {
//
//                let imageView1 = self.segmentViews[self.segmentIndex!++]
//                let imageView2 = self.segmentViews[self.segmentIndex!]
//
//                UIView.animateWithDuration(0.25,
//                    animations: {
//
//                        imageView1.frame = CGRectMake(-imageView1.frame.width, imageView1.frame.origin.y, imageView1.frame.width, imageView1.frame.height)
//                        imageView2.frame = CGRectMake(0, imageView2.frame.origin.y, imageView2.frame.width, imageView2.frame.height)
//
//                    }, completion: { (value: Bool) in
//
//                })
//            }
        }

        if swipe.direction == UISwipeGestureRecognizerDirection.Right {

            self.displayImageAtIndex(self.frameNum-1)
//            if self.segmentIndex! > 0 {
//
//                let imageView1 = self.segmentViews[self.segmentIndex!--]
//                let imageView2 = self.segmentViews[self.segmentIndex!]
//
//                UIView.animateWithDuration(0.25,
//                    animations: {
//
//                        imageView1.frame = CGRectMake(imageView1.frame.width, imageView1.frame.origin.y, imageView1.frame.width, imageView1.frame.height)
//                        imageView2.frame = CGRectMake(0, imageView2.frame.origin.y, imageView2.frame.width, imageView2.frame.height)
//
//                    }, completion: { (value: Bool) in
//                        
//                })
//            }
        }
    }
    
    func resetAnnotationView() {
        self.textView.hidden = true
    }
    
    // MARK: - Actions
    
//    @IBAction func close(sender: AnyObject) {
//        self.dismissViewControllerAnimated(true, completion: nil)
//        //self.delegate?.controllerDidFinish(self)
//    }
    
    @IBAction func deleteImage(sender: AnyObject) {
    
        self.dataFrames!.removeAtIndex(self.frameNum)
        SharedDataFrameSet.removeDataFrame(self.frameNum)
        
        if(frameNum <= self.dataFrames!.count-1 && self.dataFrames!.count > 0) {
            self.displayImageAtIndex(self.frameNum)
        } else if(frameNum > self.dataFrames!.count-1 && self.dataFrames!.count > 0) {
            self.displayImageAtIndex(self.frameNum-1)
        }
        
        // no more frames to show close the view
        if(self.dataFrames!.count == 0) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func preview(sender: AnyObject) {
        
        if(self.keyboardToolBarTextView!.isFirstResponder()) {
            self.keyboardToolBarTextView!.resignFirstResponder()
            self.textView.resignFirstResponder()
        }
        
        self.performSegueWithIdentifier("FromAnnotationToPreview", sender: self)
    }
//    @IBAction func nextImage(sender: AnyObject) {
//        self.displayImageAtIndex(self.frameNum+1)
//    }
//    
//    @IBAction func previousImage(sender: AnyObject) {
//        self.displayImageAtIndex(self.frameNum-1)
//    }
    
    @IBAction func textTool(sender: AnyObject) {
        self.textView.becomeFirstResponder()
    }
    
    // MARK: - Notifications
    func keyboardWillShow(notification: NSNotification) {
        let text = SharedDataFrame.dataFrame!.annotation
        
        self.keyboardToolBarTextView?.text = text
        self.keyboardToolBarTextView?.becomeFirstResponder()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let imageFrame = self.imageView.frame
        SharedDataFrame.dataFrame?.annotation = self.keyboardToolBarTextView!.text
        
        if (self.textView.hidden && self.keyboardToolBarTextView!.text != "") {
            self.textView.hidden = false
        } else if (self.keyboardToolBarTextView!.text == "") {
            self.textView.hidden = true
        }
        
        self.textView.text = self.keyboardToolBarTextView!.text
    }
    
    // MARK: TextViewDelegate
    func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
        
        // triggered when done button is touched
        if(text == "\n") {
            self.keyboardToolBarTextView!.resignFirstResponder()
            self.textView.resignFirstResponder()
        }
        
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
