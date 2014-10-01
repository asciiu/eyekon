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
    var processingCapture: Bool = false
    
    var context: NSManagedObjectContext?
    var camFocus: CameraFocusSquare?
    let backgroundQueue: dispatch_queue_t = dispatch_queue_create("ImageProcessor", nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // display alert if camera is not available
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let myAlertView: UIAlertView = UIAlertView(title: "Error", message: "Device has not camera", delegate: nil, cancelButtonTitle: "OK")
            myAlertView.show()
        }
        
        // register the custom collection view cell
        //let cellNib: UINib = UINib(nibName: "ImageCollectionViewCell", bundle: nil)
        //self.collectionView.registerNib(cellNib, forCellWithReuseIdentifier:"ImageCollectionViewCell")
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        // needed so we can save via managed context
        //let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        //self.context = appDelegate.managedObjectContext
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        
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
        //self.navigationController?.navigationBar.backgroundColor = UIColor.blackColor()
        //self.navigationController?.navigationBar.alpha = 0.5
        

        // not creating a new set?
        if SharedDataFrameSet.dataFrameSet != nil {
            
            let sortedFrames = SharedDataFrameSet.sortedDataFrames()
            
            for (var i = 0; i < sortedFrames.count; ++i) {
                let frame: Frame = sortedFrames[i]
                
                let photo: UIImage = UIImage(data: frame.imageData)
                self.capturedImages.append(photo)
                frame.frameNumber = i
            }
        } else {
            
            let newFrameSet = NSEntityDescription.insertNewObjectForEntityForName("FrameSet", inManagedObjectContext: self.context!) as FrameSet
            
            let set = NSMutableSet()
            
            // need to remove this stuff
            for(var i = 1; i <= 4; ++i) {
                
                let photoName: String = "\(i).jpg"
                let photo: UIImage = UIImage(named: photoName)
                self.capturedImages.append(photo)
                
                let segment: Frame = NSEntityDescription.insertNewObjectForEntityForName("Frame", inManagedObjectContext: self.context!) as Frame
                
                segment.imageData = NSData.dataWithData(UIImagePNGRepresentation(photo))
                segment.frameNumber = i-1
                segment.frameSet = newFrameSet
                set.addObject(segment)
            }
            
            newFrameSet.title = "Untitled"
            newFrameSet.detailedDescription = "Empty description"
            newFrameSet.frames = set
            SharedDataFrameSet.dataFrameSet = newFrameSet
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
    
    // MARK: - CaptureSessionManagerDelegate
    
    // invoked when the camera capture has completed
    func processCapture(capturedImage: UIImage) {
        
        dispatch_async(self.backgroundQueue, {
            let image = scaleAndRotateImage(capturedImage)
            
            self.capturedImages.append(image)
            
            let index: NSIndexPath = NSIndexPath(forItem: self.capturedImages.count-1, inSection: 0)
            let context = SharedDataFrameSet.dataFrameSet!.managedObjectContext
            
            // create a new segment for the captured image
            let newSegment: Frame = NSEntityDescription.insertNewObjectForEntityForName("Frame", inManagedObjectContext: context) as Frame
            
            newSegment.imageData = NSData.dataWithData(UIImagePNGRepresentation(image))
            newSegment.frameNumber = index.row
            newSegment.frameSet = SharedDataFrameSet.dataFrameSet!
            SharedDataFrameSet.dataFrameSet!.frames.addObject(newSegment)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.collectionView.insertItemsAtIndexPaths([index])
                self.collectionView.scrollToItemAtIndexPath(index, atScrollPosition: UICollectionViewScrollPosition.Right, animated: true)
                self.processingCapture = false
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
        
        let frames = NSMutableArray(array: SharedDataFrameSet.sortedDataFrames())
        let frame: Frame = frames[fromIndexPath.item] as Frame
        frames.removeObject(frame)
        frames.insertObject(frame, atIndex: toIndexPath.item)
        
        for(var i = 0; i < frames.count; ++i) {
            let frm = frames[i] as Frame
            frm.frameNumber = i
        }
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, canMoveToIndexPath toIndexPath: NSIndexPath!) -> Bool {
        
        return true
    }
    
    func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
        let selectedImage: UIImage = self.capturedImages[indexPath.row]
        
        // set the shared dataFrame with the one we selected from the collection view
        SharedDataFrame.dataFrame = SharedDataFrameSet.findFrameNumber(indexPath.row)
                
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

