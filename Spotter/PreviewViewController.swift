//
//  PreviewViewController.swift
//  Spotter
//
//  Created by LV426 on 9/11/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    //@IBOutlet var imageView: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var upperLeftButton: UIBarButtonItem!
    @IBOutlet var upperRightButton: UIBarButtonItem!
    
    //var segments: [UIImage]?
    //var segmentIndex: Int?
    //var segmentViews: [UIImageView] = [UIImageView]()
    var dataFrames: [Frame]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        self.view.userInteractionEnabled = true
//        
//        let swipeLeft: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipe:")
//        let swipeRight: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipe:")
//       
//         // Setting the swipe direction.
//        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
//        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
//        
//        // Adding the swipe gesture on image view
//        self.view.addGestureRecognizer(swipeLeft)
//        self.view.addGestureRecognizer(swipeRight)
//        
//        self.view.clipsToBounds = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.dataFrames = SharedDataFrameSet.sortedDataFrames()
        
        let controllers = self.navigationController!.viewControllers
        let previousController = controllers[controllers.count-2]
        
        if (previousController is CollectionViewController) {
            self.upperRightButton.title = "Edit"
            self.upperRightButton.enabled = false
        } else if(previousController is CaptureViewController || previousController is AnnotateViewController) {
            self.upperRightButton.title = "Publish"
            self.upperRightButton.enabled = true
        }
//        let firstFrame: Frame = SharedDataFrameSet.sortedDataFrames()[0]
//        let image: UIImage = UIImage(data: firstFrame.imageData)
//        
//        self.segmentIndex = 0
//        //self.imageView.image = self.segments![0]
//        
//        let origin = self.imageView.frame.origin
//        let frameWidth = self.imageView.frame.width
//        let originalWidth = image.size.width
//        let originalHeight = image.size.height
//        
//        let height = frameWidth * originalHeight / originalWidth
//        self.imageView.frame = CGRectMake(origin.x, origin.y, frameWidth, height)
//        self.imageView.image = image
//        
//        var imageFrame = self.imageView.frame
//        
//        if (firstFrame.annotation != nil) {
//            let textView: UITextView = UITextView()
//            textView.backgroundColor = UIColor.blackColor()
//            textView.textColor = UIColor.whiteColor()
//            textView.font.fontWithSize(10)
//            textView.frame.origin.y = imageFrame.origin.y + imageFrame.height
//            textView.text = SharedDataFrame.dataFrame!.annotation
//            textView.frame.size.height = textView.contentSize.height + 9
//            self.view.addSubview(textView)
//        }
        
        //self.imageView.frame = CGRectMake(origin.x, origin.y, originalWidth, originalHeight)
//        float oldWidth = sourceImage.size.width;
//        float scaleFactor = i_width / oldWidth;
//        
//        float newHeight = sourceImage.size.height * scaleFactor;
//        float newWidth = oldWidth * scaleFactor;
//        
//        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
//        [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
//        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//        return newImage;
        
//        self.segmentViews.removeAll(keepCapacity: false)
//        self.segmentViews.append(self.imageView)
//        
//        let viewFrame = self.imageView.frame
//        
//        for (var i = 1; i < self.segments!.count; ++i) {
//            let imageWidth = self.segments![i].size.width
//            let imageHeight = self.segments![i].size.height
//            let frameHeight = frameWidth * imageHeight / imageWidth
//            
//            let imageView: UIImageView = UIImageView(image: self.segments![i])
//            imageView.frame = CGRectMake(frameWidth, origin.y, frameWidth, frameHeight)
//            
//            self.view.addSubview(imageView)
//            self.segmentViews.append(imageView)
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func returnToPrevious(sender: AnyObject) {
        // pop myself off the stack of view controllers and show the previous 
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func publish(sender: AnyObject) {
        println("PreviewViewController: publish")
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    }
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SharedDataFrameSet.dataFrameSet!.frames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // try to get a reusable cell for our custom cell class
        var cell: SimpleTableViewCell = tableView.dequeueReusableCellWithIdentifier("SimpleTableViewCell") as SimpleTableViewCell
        
        let frame = self.dataFrames![indexPath.row]
        let image = UIImage(data: frame.imageData)
        
        cell.mainImage.image = image
    
        // show annotation if the info frame has one
        if(frame.annotation != nil && frame.annotation != "") {
            cell.annotationTextView.text = frame.annotation
            
            let textFrame = cell.annotationTextView.contentSize
            
            cell.annotationTextView.backgroundColor = UIColor.blackColor()
            cell.annotationTextView.textColor = UIColor.whiteColor()
            cell.annotationTextView.hidden = false
        } else {
            cell.annotationTextView.hidden = true
        }
        
        return cell
    }

    // MARK: UITableViewDelegate
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        
//        let frame = self.dataFrames![indexPath.row]
//        let image = UIImage(data: frame.imageData)
//        
//        let frameWidth = self.tableView.frame.width
//        let originalWidth = image.size.width
//        let originalHeight = image.size.height
//        let height = frameWidth * originalHeight / originalWidth
//        
//        //let cell: SimpleTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as SimpleTableViewCell
//        //cell.textField.text = frame.annotation
//        //let textHeight = cell.textField.contentSize.height + 7
//    
//        return height
//    }
}
