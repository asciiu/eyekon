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
    @IBOutlet var previousBtn: UIButton!
    @IBOutlet var nextBtn: UIButton!
    @IBOutlet var textView: UITextView!

    var frameNum: Int = 0
    var images: [UIImage]?
    var keyboardToolBar: UIToolbar?
    var keyboardToolBarTextView: UITextView?
    var dataFrames: [Frame]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup a textview on the keyboardToolBar
        self.keyboardToolBar = UIToolbar(frame: CGRectMake(0, 0, self.view.frame.width, 44))
        self.keyboardToolBarTextView = UITextView(frame: CGRectMake(0, 0, self.view.frame.width, 44))
        self.keyboardToolBarTextView?.returnKeyType = UIReturnKeyType.Done
        self.keyboardToolBarTextView?.delegate = self

        self.keyboardToolBar?.addSubview(self.keyboardToolBarTextView!)
        
        self.textView.inputAccessoryView = self.keyboardToolBar
        self.textView.backgroundColor = UIColor.blackColor()
        self.textView.textColor = UIColor.whiteColor()
        self.textView.font.fontWithSize(10)
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
    
    func resetAnnotationView() {
        self.textView.hidden = true
    }
    
    func displayImage(image: UIImage) {
        let origin = self.imageView.frame.origin
        let frameWidth = self.imageView.frame.width
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        let height = frameWidth * originalHeight / originalWidth
        let imageFrame = CGRectMake(origin.x, origin.y, frameWidth, height)
        self.imageView.frame = imageFrame
        self.imageView.image = image
        
        if (SharedDataFrame.dataFrame!.annotation != nil) {
            self.textView.hidden = false
            self.textView.frame.origin.y = imageFrame.origin.y + imageFrame.height
            self.textView.text = SharedDataFrame.dataFrame!.annotation
            self.textView.frame.size.height = self.textView.contentSize.height + 9
        } else {
            self.resetAnnotationView()
        }
    }
    
    func displayImageAtIndex(index: Int) {
        
        let dataFrame: Frame = self.dataFrames![index]
        SharedDataFrame.dataFrame = dataFrame

        let image = UIImage(data: dataFrame.imageData)
        self.displayImage(image)
        
        self.frameNum = index

        // hide next button if last image
        if(self.frameNum == self.dataFrames!.count-1) {
            self.nextBtn.hidden = true
        } else {
            self.nextBtn.hidden = false
        }
        
        // hide prev button if first image
        if(self.frameNum == 0) {
            self.previousBtn.hidden = true
        } else {
            self.previousBtn.hidden = false
        }
    }
    
    // MARK: - Actions
    
    @IBAction func close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        //self.delegate?.controllerDidFinish(self)
    }
    
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
    
    @IBAction func nextImage(sender: AnyObject) {
        self.displayImageAtIndex(self.frameNum+1)
    }
    
    @IBAction func previousImage(sender: AnyObject) {
        self.displayImageAtIndex(self.frameNum-1)
    }
    
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

        if self.textView.hidden {
            self.textView.frame = CGRectMake(0, imageFrame.origin.y + imageFrame.height, imageFrame.width, 30)
            
            self.textView.backgroundColor = UIColor.blackColor()
            self.textView.textColor = UIColor.whiteColor()
            self.textView.font.fontWithSize(10)
            
            self.textView.hidden = false
        }
        
        SharedDataFrame.dataFrame?.annotation = self.keyboardToolBarTextView!.text
        self.textView.text = self.keyboardToolBarTextView!.text
        self.textView.frame.size.height = self.textView.contentSize.height + 9
    }
    
    // MARK: TextViewDelegate
    func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
        
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
