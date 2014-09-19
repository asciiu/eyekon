//
//  PublishViewController.swift
//  Spotter
//
//  Created by LV426 on 9/11/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class PublishViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    //var segments: [UIImage]?
    var frameSet: FrameSet?
    var context: NSManagedObjectContext?

    @IBOutlet var titleField: UITextField!
    @IBOutlet var descriptionField: UITextView!
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context = appDelegate.managedObjectContext
    }
    
    override func viewWillAppear(animated: Bool) {
        let frames: [Frame] = SharedDataFrameSet.sortedDataFrames()
        let image: UIImage = UIImage(data: frames[0].imageData)
        self.imageView.image = image
        
        //if(SharedDataFrameSet.dataFrameSet!.title != nil) {
        self.titleField.text = SharedDataFrameSet.dataFrameSet!.title
        //}
        
        self.descriptionField.text = SharedDataFrameSet.dataFrameSet!.detailedDescription
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Actions
    
    @IBAction func save(sender: AnyObject) {
        if(self.titleField.text == "") {
            let alert: UIAlertView = UIAlertView(title: "Missing information!", message: "Please enter a title", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        } else if (self.descriptionField.text == "") {
            let alert: UIAlertView = UIAlertView(title: "Missing information!", message: "Please enter a description", delegate: nil, cancelButtonTitle: "OK")
            
            alert.show()
        } else {
            var error: NSError?

//            if self.frameSet == nil {
//                self.frameSet = NSEntityDescription.insertNewObjectForEntityForName("FrameSet", inManagedObjectContext: self.context!) as? FrameSet
//            }

            let frameSet = SharedDataFrameSet.dataFrameSet!

            frameSet.frameCount = frameSet.frames.count
            frameSet.title = self.titleField.text
            frameSet.detailedDescription = self.descriptionField.text

//            let frames: NSMutableSet = NSMutableSet()

            // a frameSet has frames
//            for var i = 0; i < frameSet.frameCount; ++i {
//
//                let image = self.segments![i]
//                let frame: Frame = NSEntityDescription.insertNewObjectForEntityForName("Frame", inManagedObjectContext: self.context!) as Frame
//
//                frame.frameSet = frameSet
//
//                // convert image to NSData
//                frame.imageData = NSData.dataWithData(UIImagePNGRepresentation(image))
//                frame.frameNumber = i
//
//                // add frame to frameSet
//                frames.addObject(frame)
//            }
//            frameSet.frames = frames

            if( !frameSet.managedObjectContext.save(&error)) {
                println("could not save FrameSet: \(error?.localizedDescription)")
            }
            
            self.performSegueWithIdentifier("fromPublishToCollection", sender: self)
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.titleField {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: UITextViewDelegate
    func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {

        if(text == "\n") {
            textView.resignFirstResponder()
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
