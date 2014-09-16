//
//  AnnotateViewController.swift
//  Spotter
//
//  Created by LV426 on 9/2/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class AnnotateViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var previousBtn: UIButton!
    @IBOutlet var nextBtn: UIButton!
    @IBOutlet var textView: UITextView!

    var frameNum: Int = 0
    var images: [UIImage]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displayImageAtIndex(index: Int) {
        
        if(images?.count == 0) {
            return
        }
        
        let image: UIImage? = self.images?[index]
        
        if image == nil {
            println("Annotation images are empty!")
            return
        }
        
        let origin = self.imageView.frame.origin
        let frameWidth = self.imageView.frame.width
        let originalWidth = image!.size.width
        let originalHeight = image!.size.height
        
        let height = frameWidth * originalHeight / originalWidth
        self.imageView.frame = CGRectMake(origin.x, origin.y, frameWidth, height)
        self.imageView.image = image!
        self.frameNum = index
        
        // hide next button if last image
        if(self.frameNum == self.images!.count-1) {
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
        self.images!.removeAtIndex(self.frameNum)
        
        if(frameNum <= self.images!.count-1 && self.images!.count > 0) {
            self.displayImageAtIndex(self.frameNum)
        } else if(frameNum > self.images!.count-1 && self.images!.count > 0) {
            self.displayImageAtIndex(self.frameNum-1)
        }
        
        // no more frames to show close the view
        if(self.images!.count == 0) {
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
