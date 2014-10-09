//
//  AnnotateViewController.swift
//  Spotter
//
//  Created by LV426 on 9/2/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

protocol CapturePreviewControllerDelegate {
    func deleteImage(atIndex: Int)
}

class CapturePreviewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate {

    @IBOutlet var scrollView: UIScrollView!

    var imageViews: [UIImageView] = [UIImageView]()
    var images: [UIImage] = [UIImage]()
    var pageIndex: Int = 0
    var delegate: CapturePreviewControllerDelegate?
    
    var alertController: UIAlertController = UIAlertController(title:"Caution!",
        message: "Are you sure you want to delete this image?",
        preferredStyle:UIAlertControllerStyle.Alert)
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let toolbarRect = CGRectMake(0, 0, self.view.frame.width, 44)
        
        // setup the swipe gestures so the user can swipe left and right
        self.view.userInteractionEnabled = true
        
        //self.scrollView.minimumZoomScale = 1.0
        //self.scrollView.maximumZoomScale = 2.0
        //self.scrollView.delegate = self
        self.scrollView.pagingEnabled = true
        
        // alert actions
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: {(alert :UIAlertAction!) in
    
            self.deleteSelected()
        })
        
        self.alertController.addAction(cancelAction)
        self.alertController.addAction(deleteAction)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let origin = self.scrollView.frame.origin
        let frameWidth = self.scrollView.frame.size.width

        // create image views for each image
        for (var i = 0; i < self.images.count; ++i) {
            let image = images[i]
            
            // each image should be of frameWidth with variable height
            // preserving image aspect ratio
            let originalWidth = image.size.width
            let originalHeight = image.size.height
            let frameHeight = frameWidth * originalHeight / originalWidth
            let x = frameWidth * CGFloat(i)
            let frame = CGRectMake(x, origin.y, frameWidth, frameHeight)

            let imageView = UIImageView(frame: frame)
            imageView.image = image
            self.scrollView.addSubview(imageView)
            self.imageViews.append(imageView)
        }
        
        // set the content width of the scroll view
        let contentWidth = frameWidth * CGFloat(images.count)
        self.scrollView.contentSize.width = contentWidth
        
        // set the page index to the selected page index
        self.scrollView.contentOffset = CGPointMake(frameWidth * CGFloat(self.pageIndex), 0)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // remove all subviews from the scroll view
        for view in self.imageViews {
            view.removeFromSuperview()
        }
        self.imageViews.removeAll(keepCapacity: false)
        self.images.removeAll(keepCapacity: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Custom Stuff
    func setImages(images: [UIImage]) {
        self.images = images
    }
    
    func setPageIndex(index: Int) {
        self.pageIndex = index
    }
    
    
    func deleteSelected() {
        let contentOffset = self.scrollView.contentOffset
        let pageIndex: Int = Int(contentOffset.x / self.scrollView.frame.size.width)
        
        let width = self.scrollView.frame.size.width
        let imageView = self.imageViews[pageIndex]
        imageView.removeFromSuperview()
        
        UIView.animateWithDuration(0.15, animations: {
            for (var i = pageIndex+1; i < self.imageViews.count; ++i) {
                let imageView = self.imageViews[i]
                imageView.frame.origin.x -= width
            }
        })
        
        self.scrollView.contentSize.width -= width
        self.imageViews.removeAtIndex(pageIndex)
        self.images.removeAtIndex(pageIndex)
        self.delegate?.deleteImage(pageIndex)
        
        if(self.images.count == 0) {
            self.navigationController!.popViewControllerAnimated(true)
            //self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func deleteImage(sender: AnyObject) {
        self.presentViewController(self.alertController, animated: true, completion: nil)
    }
    
    // MARK: - ScrollViewDelegate
    
//    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
//        return self.imageView
//    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    //override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    //}
}
