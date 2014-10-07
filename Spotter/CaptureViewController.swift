//
//  ViewController.swift
//  Spotter
//
//  Created by LV426 on 8/21/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class CameraFocusSquare: UIView {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clearColor()
        
        self.layer.borderWidth = 1.0
        //self.layer.cornerRadius = frame.width/2
        self.layer.borderColor = UIColor.whiteColor().CGColor
        
        let selectionAnimation: CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
        selectionAnimation.toValue = UIColor.yellowColor().CGColor
        selectionAnimation.repeatCount = 8
        self.layer.addAnimation(selectionAnimation, forKey: "selectionAnimation")
    }
}

class CaptureViewController: UIViewController, RACollectionViewDelegateReorderableTripletLayout, RACollectionViewReorderableTripletLayoutDataSource, CaptureSessionManagerDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var cancelBtn: UIBarButtonItem!
    @IBOutlet var previewBtn: UIBarButtonItem!
    @IBOutlet var cameraView: UIView!
    
    var captureManager: CaptureSessionManager?
    var capturedImages: [UIImage] = [UIImage]()
    
    var camFocus: CameraFocusSquare?
    let backgroundQueue: dispatch_queue_t = dispatch_queue_create("ImageProcessor", nil)
    
    var storyController: StoryViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // display alert if camera is not available
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let myAlertView: UIAlertView = UIAlertView(title: "Error", message: "Device has not camera", delegate: nil, cancelButtonTitle: "OK")
            myAlertView.show()
        }
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        // setup the camera
        self.captureManager = CaptureSessionManager()
        self.captureManager!.delegate = self
        self.captureManager!.addVideoInput()
        self.captureManager!.addVideoPreviewLayer()
        self.captureManager!.addStillImageOutput()
        
        let cameraLayer = self.cameraView.layer
        cameraLayer.masksToBounds = true
        
        // position the custom camera onto the cameraView layer
        let rect = self.cameraView.layer.bounds
        self.captureManager!.previewLayer!.bounds = rect
        self.captureManager!.previewLayer!.position = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
        self.cameraView.layer.addSublayer(self.captureManager!.previewLayer!)
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.captureManager!.captureSession!.startRunning()
        self.capturedImages.removeAll(keepCapacity: false)
        self.title = ""

        // test stuff to be removed
        for(var i = 1; i <= 4; ++i) {
            
            let photoName: String = "\(i).jpg"
            let photo: UIImage = UIImage(named: photoName)
            self.capturedImages.append(photo)
        }
        
        self.collectionView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureManager!.captureSession!.stopRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func takePhoto(sender: AnyObject) {
        self.captureManager!.captureStillImage()
    }
    
    @IBAction func done(sender: AnyObject) {
        for (var i = self.capturedImages.count-1; i >= 0; --i) {
            let image = self.capturedImages[i]
            self.storyController!.addImageView(image)
        }
        
        // go back to the view that we came from
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - CaptureSessionManagerDelegate
    
    // invoked when the camera capture has completed
    func processCapture(capturedImage: UIImage) {
        
        // handle image processing in background so we do not block the main thread
        dispatch_async(self.backgroundQueue, {
            // fix rotation of image
            let image = scaleAndRotateImage(capturedImage)
            
            self.capturedImages.append(image)
            
            
            // update the view on the main thread
            dispatch_async(dispatch_get_main_queue(), {
                let index: NSIndexPath = NSIndexPath(forItem: self.capturedImages.count-1, inSection: 0)
                self.collectionView.insertItemsAtIndexPaths([index])
                self.collectionView.scrollToItemAtIndexPath(index, atScrollPosition: UICollectionViewScrollPosition.Right, animated: true)
            })
        })
    }
    
    // MARK: - UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let identifier: NSString = "ImageCollectionViewCell"

        var cell: ImageCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as ImageCollectionViewCell

        let image = self.capturedImages[indexPath.row]

        //cell.imageView.frame = cell.bounds
        cell.numberLabel.text = String(indexPath.item + 1)
        cell.imageView.image = self.capturedImages[indexPath.item]
        
        return cell;
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.capturedImages.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int {
        return 1
    }
    
    // MARK: - RACollectionViewDelegateReorderableTripletLayout
    
    func sectionSpacingForCollectionView(collectionView: UICollectionView!) -> CGFloat {
        return 5.0
    }

    func minimumInteritemSpacingForCollectionView(collectionView: UICollectionView!) -> CGFloat {
        return 5.0
    }
    
    func minimumLineSpacingForCollectionView(collectionView: UICollectionView!) -> CGFloat {
        return 5.0
    }
    
    func insetsForCollectionView(collectionView: UICollectionView!) -> UIEdgeInsets {
        return UIEdgeInsetsMake(5.0, 0, 5.0, 0)
        //return UIEdgeInsetsMake(0, 5.0, 0, 5.0)
    }
    
    func collectionView(collectionView: UICollectionView!, sizeForLargeItemsInSection section: Int) -> CGSize {
        //if (section == 0) {
        //    return CGSizeMake(320, 200)
        //}
        return CGSizeZero
    }
    
    func autoScrollTrigerEdgeInsets(collectionView: UICollectionView!) -> UIEdgeInsets {
        //return UIEdgeInsetsMake(50.0, 0, 50.0, 0)
        return UIEdgeInsetsMake(0, 25.0, 0, 25.0)
    }
    
    func autoScrollTrigerPadding(collectionView: UICollectionView!) -> UIEdgeInsets {
        //return UIEdgeInsetsMake(64.0, 0, 0, 0)
        return UIEdgeInsetsMake(0, 64.0, 0, 0.0)

    }
    
    func reorderingItemAlpha(collectionview: UICollectionView!) -> CGFloat {
        return 0.3
    }
    
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, didEndDraggingItemAtIndexPath indexPath: NSIndexPath) {
        
        self.collectionView.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, didMoveToIndexPath toIndexPath: NSIndexPath!) {
        
        let image: UIImage = self.capturedImages[fromIndexPath.item]
        
        self.capturedImages.removeAtIndex(fromIndexPath.item)
        self.capturedImages.insert(image, atIndex: toIndexPath.item)
        
//        let frames = NSMutableArray(array: SharedDataFrameSet.sortedDataFrames())
//        let frame: Frame = frames[fromIndexPath.item] as Frame
//        frames.removeObject(frame)
//        frames.insertObject(frame, atIndex: toIndexPath.item)
//        
//        for(var i = 0; i < frames.count; ++i) {
//            let frm = frames[i] as Frame
//            frm.frameNumber = i
//        }
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, canMoveToIndexPath toIndexPath: NSIndexPath!) -> Bool {
        
        return true
    }
    
    func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
        let selectedImage: UIImage = self.capturedImages[indexPath.row]
        
        // set the shared dataFrame with the one we selected from the collection view
        //SharedDataFrame.dataFrame = SharedDataFrameSet.findFrameNumber(indexPath.row)
                
//        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let annotateViewController: AnnotateViewController = storyboard.instantiateViewControllerWithIdentifier("AnnotateViewController") as AnnotateViewController
//        
//        self.presentViewController(annotateViewController, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView!, shouldHighlightItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    
    }
    
    @IBAction func unwindToCapture(unwindSegue: UIStoryboardSegue) {
        
    }
    
    // MARK: - Touch Events
    
    // touch to focus camera
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch: UITouch = touches.anyObject() as UITouch
        let touchPoint: CGPoint = touch.locationInView(touch.view)
        
        //self.focus(touchPoint)
        self.camFocus?.removeFromSuperview()
        
        if (self.cameraView === touch.view) {
            // draw a box around the focus point
            let focusRect = CGRectMake(touchPoint.x - 40, touchPoint.y - 40, 80, 80)
            self.camFocus = CameraFocusSquare(frame: focusRect)
            self.camFocus!.backgroundColor = UIColor.clearColor()
            self.view.addSubview(self.camFocus!)
            self.camFocus!.setNeedsDisplay()
            
            let screenRect = UIScreen.mainScreen().bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            let focus_x = touchPoint.x/screenWidth
            let focus_y = touchPoint.y/screenHeight
            let focusPt = CGPointMake(focus_x, focus_y)
            
            // set focus point for capture manager
            self.captureManager?.focusOnPoint(focusPt)
            
            UIView.animateWithDuration(1.5, animations: {
                self.camFocus!.alpha = 0
                }, completion: {(value: Bool) in
                    
            })
        }
    }
}

