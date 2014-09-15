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


class CaptureViewController: UIViewController, RACollectionViewDelegateReorderableTripletLayout, RACollectionViewReorderableTripletLayoutDataSource {
    
    @IBOutlet var collectionView: UICollectionView!
    //@IBOutlet var descriptionField: UITextField!
    @IBOutlet var cancelBtn: UIBarButtonItem!
    @IBOutlet var saveBtn: UIBarButtonItem!
    @IBOutlet var cameraView: UIView!
    
    var captureManager: CaptureSessionManager?
    //var imagePickerController: UIImagePickerController?
    var capturedImages: [UIImage] = [UIImage]()
    
    var annotateViewController: AnnotateViewController?
    var context: NSManagedObjectContext?
    
    var frameSet: FrameSet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // display alert if camera is not available
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let myAlertView: UIAlertView = UIAlertView(title: "Error", message: "Device has not camera", delegate: nil, cancelButtonTitle: "OK")
            myAlertView.show()
        }
        
        // register the custom collection view cell
        let cellNib: UINib = UINib(nibName: "ImageCollectionViewCell", bundle: nil)
        self.collectionView.registerNib(cellNib, forCellWithReuseIdentifier:"ImageCollectionViewCell")
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.setupPhotosArray()
        
        // needed so we can save via managed context
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate        
        self.context = appDelegate.managedObjectContext
        
        // setup the camera 
        self.captureManager = CaptureSessionManager()
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
        
        self.captureManager!.captureSession!.startRunning()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveImageToRoll", name: kImageCapturedSuccessfully, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.frameSet != nil {
            self.capturedImages.removeAll(keepCapacity: false)
            
            //self.descriptionField.text = self.frameSet!.synopsis
            
            let frameNumDescriptor: NSSortDescriptor = NSSortDescriptor(key: "frameNumber", ascending: true)
            
            let frames = frameSet!.frames
            
            let sortedFrames = frames.sortedArrayUsingDescriptors(NSArray(object:frameNumDescriptor))
            
            for (var i = 0; i < sortedFrames.count; ++i) {
                let frame: Frame = sortedFrames[i] as Frame
                
                let photo: UIImage = UIImage(data: frame.imageData)
                self.capturedImages.append(photo)
            }
        }
        self.collectionView.reloadData()
    }
//    override func viewDidAppear(animated: Bool) {
//        
//        if self.frameSet != nil {
//            self.capturedImages.removeAll(keepCapacity: false)
//            
//            self.descriptionField.text = self.frameSet!.synopsis
//            
//            let frameNumDescriptor: NSSortDescriptor = NSSortDescriptor(key: "frameNumber", ascending: true)
//            
//            let frames = frameSet!.frames
//            
//            let sortedFrames = frames.sortedArrayUsingDescriptors(NSArray(object:frameNumDescriptor))
//            
//            for frame in sortedFrames {
//                let frameData = frame as Frame
//                
//                let photo: UIImage = UIImage(data: frameData.imageData)
//                self.capturedImages.append(photo)
//            }
//        }
//        self.collectionView.reloadData()
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupPhotosArray()
    {
        self.capturedImages.removeAll(keepCapacity: false)
        
        for(var i = 1; i <= 4; ++i) {
            let photoName: String = "\(i).jpg"
            let photo: UIImage = UIImage(named: photoName)
            self.capturedImages.append(photo)
        }
    }
    
    func setFrames(frameSet: FrameSet) {
        self.capturedImages.removeAll(keepCapacity: false)
        
        //self.descriptionField.text = frameSet.synopsis
        
        let frameNumDescriptor: NSSortDescriptor = NSSortDescriptor(key: "frameNumber", ascending: true)
        
        let frames = frameSet.frames
        
        let sortedFrames = frames.sortedArrayUsingDescriptors(NSArray(object:frameNumDescriptor))
        
        for frame in sortedFrames {
            let frameData = frame as Frame
            
            let photo: UIImage = UIImage(data: frameData.imageData)
            self.capturedImages.append(photo)
        }
    }
    
    // invoked when the camera capture has completed
    func saveImageToRoll() {
        let image = self.captureManager?.stillImage
        self.capturedImages.append(image!)
        self.collectionView.reloadData()
        
        let index: NSIndexPath = NSIndexPath(forRow: self.capturedImages.count-1, inSection: 0)
        

        self.collectionView.scrollToItemAtIndexPath(index, atScrollPosition: UICollectionViewScrollPosition.Right, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction func takePhoto(sender: AnyObject) {
        self.captureManager?.captureStillImage()
    }
    
//    @IBAction func save(sender: AnyObject) {
//        
////        if(self.descriptionField.text == "") {
////            let alert: UIAlertView = UIAlertView(title: "Missing information!", message: "Please enter a description", delegate: nil, cancelButtonTitle: "OK")
////          
////            alert.show()
////        } else {
//            var error: NSError?
//
//            if self.frameSet == nil {
//                self.frameSet = NSEntityDescription.insertNewObjectForEntityForName("FrameSet", inManagedObjectContext: self.context!) as? FrameSet
//            }
//            
//            let frameSet = self.frameSet!
//            
//            frameSet.frameCount = self.capturedImages.count
//            frameSet.synopsis = self.descriptionField.text
//            
//            let frames: NSMutableSet = NSMutableSet()
//            
//            // a frameSet has frames
//            for var i = 0; i < self.capturedImages.count; ++i {
//                
//                let image = self.capturedImages[i]
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
//            
//            if( !frameSet.managedObjectContext.save(&error)) {
//                println("could not save FrameSet: \(error?.localizedDescription)")
//            }
//            
//            
//            self.performSegueWithIdentifier("unwindToList", sender: self)
//        
//    }
    
//    func textFieldShouldReturn(textField: UITextField!) -> Bool {
//        
//        if(textField == self.descriptionField) {
//            textField.resignFirstResponder()
//            // set the description here
//            
//        }
//        return false
//    }

    // moved
//    func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
//        
//        if(text == "\n") {
//            textView.resignFirstResponder()
//        }
//        
//        return true
//    }
    
    // MARK: - UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let identifier: NSString = "ImageCollectionViewCell"

        var cell: ImageCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as ImageCollectionViewCell

        //cell.imageView.removeFromSuperview()
        cell.imageView.frame = cell.bounds
        cell.numberLabel.text = String(indexPath.row + 1)
        cell.imageView.image = self.capturedImages[indexPath.row]
        
        return cell;
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.capturedImages.count
    }
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int {
        return 1
    }
    
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
        
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, canMoveToIndexPath toIndexPath: NSIndexPath!) -> Bool {
        
        return true
    }
    
    func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
        let selectedImage: UIImage = self.capturedImages[indexPath.row]
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let annotateViewController: AnnotateViewController = storyboard.instantiateViewControllerWithIdentifier("AnnotateViewController") as AnnotateViewController
        
        self.annotateViewController = annotateViewController
        self.presentViewController(annotateViewController, animated: true, completion: nil)
        
        self.annotateViewController!.imageView.image = self.capturedImages[indexPath.item]
        self.annotateViewController!.frameNum = indexPath.item
    }
    
    func collectionView(collectionView: UICollectionView!, shouldHighlightItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
   
//    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!) {
//        
//        let newImage: UIImage = info[UIImagePickerControllerOriginalImage] as UIImage
//        
//        self.capturedImages.append(newImage)
//        self.previewView.image = newImage
//        
//        //self.imageView.image = newImage
//        
//        //let chosenImage: UIImage = info[UIImagePickerControllerEditedImage] as UIImage
//        //self.imageView.image = chosenImage
//        
//        /*
//        let mediaType: NSString = info[UIImagePickerControllerMediaType] as NSString;
//        
//        if (mediaType == kUTTypeImage) {
//            // Media is an image
//        } else if (mediaType == kUTTypeMovie) {
//            // Media is a video
//        }*/
//        
//        //picker.dismissViewControllerAnimated(true, completion: nil)
//    }
    
//    func imagePickerControllerDidCancel(picker: UIImagePickerController!) {
//        picker.dismissViewControllerAnimated(true, completion: nil)
//    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        let destinationController: PreviewViewController? = segue.destinationViewController as? PreviewViewController
        
        if destinationController != nil {
            destinationController!.segments = self.capturedImages
            //destinationController!.imageView.image = self.capturedImages[0]
        }
        
        // if the save button was not pressed return
        //if(sender !== self.saveBtn) {
        //    return
        //}
    }
    
    @IBAction func unwindToCapture(unwindSegue: UIStoryboardSegue) {
        
    }
//    func navigationController(navigationController: UINavigationController!, willShowViewController viewController: UIViewController!, animated: Bool) {
//        
//        UIApplication.sharedApplication().statusBarHidden = true
//    }
}

