//
//  ViewController.swift
//  Spotter
//
//  Created by LV426 on 8/21/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class CaptureViewController: UIViewController , UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var descriptionField: UITextField!
    
    // camera overlay view
    @IBOutlet var overlayView: UIView!
    @IBOutlet var previewView: UIImageView!
    @IBOutlet var textView: UITextView!
    
    
    var imagePickerController: UIImagePickerController?
    var capturedImages: [UIImage] = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // display alert if camera is not available
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let myAlertView: UIAlertView = UIAlertView(title: "Error", message: "Device has not camera", delegate: nil, cancelButtonTitle: "OK")
            myAlertView.show()
            
        }
        
        let cellNib: UINib = UINib(nibName: "ImageCollectionViewCell", bundle: nil)
        self.collectionView.registerNib(cellNib, forCellWithReuseIdentifier:"ImageCollectionViewCell")
    }
    
    // TODO remove
    @IBAction func resignOnTap(sender: AnyObject) {
        println("hello")
        self.textView.resignFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func takePhoto(sender: AnyObject){
        self.imagePickerController?.takePicture()
    }
    @IBAction func done(sender: AnyObject) {
        self.imagePickerController?.dismissViewControllerAnimated(true, completion: nil)
        self.collectionView.reloadData()
    }
    
    @IBAction func saveReel(sender: AnyObject) {
    }
    
    @IBAction func showImagePickerForCamera(sender: AnyObject) {
        self.showImagePickerForSourceType(UIImagePickerControllerSourceType.Camera)
    }
    
    @IBAction func showImagePickerForPhotoPicker(sender: AnyObject) {
        self.showImagePickerForSourceType(UIImagePickerControllerSourceType.PhotoLibrary)
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        
        if(textField == self.descriptionField) {
            textField.resignFirstResponder()
            // set the description here
            
        }
        return false
    }

    // moved
//    func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
//        
//        if(text == "\n") {
//            textView.resignFirstResponder()
//        }
//        
//        return true
//    }
    
    // collection view data source
    func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
        
        let identifier: NSString = "ImageCollectionViewCell"

        var cell: ImageCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath) as ImageCollectionViewCell
        
//        if(cell == nil) {
//            cell = NSBundle.mainBundle().loadNibNamed(identifier, owner:self, options:nil)[0] as? ImageCollectionViewCell
//        }

        cell.numberLabel.text = String(indexPath.row + 1)
        cell.imageView.image = self.capturedImages[indexPath.row]

        
        //let thumbImage: UIImageView = cell.viewWithTag(100) as UIImageView
        //thumbImage.image = self.capturedImages[indexPath.row]
        
        return cell;
    }
    
    func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        return self.capturedImages.count
    }
    
    func collectionView(collectionView: UICollectionView!, didSelectItemAtIndexPath indexPath: NSIndexPath!) {
        let selectedImage: UIImage = self.capturedImages[indexPath.row]
        
        // todo pop up larger view of image
    }
    
    func collectionView(collectionView: UICollectionView!, shouldHighlightItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!) {
        
        let newImage: UIImage = info[UIImagePickerControllerOriginalImage] as UIImage
        
        self.capturedImages.append(newImage)
        self.previewView.image = newImage
        //self.imageView.image = newImage
        
        //println(self.capturedImages.count)
        
        //let chosenImage: UIImage = info[UIImagePickerControllerEditedImage] as UIImage
        //self.imageView.image = chosenImage
        
        /*
        let mediaType: NSString = info[UIImagePickerControllerMediaType] as NSString;
        
        if (mediaType == kUTTypeImage) {
            // Media is an image
        } else if (mediaType == kUTTypeMovie) {
            // Media is a video
        }*/
        
        //picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController!) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showImagePickerForSourceType(sourceType: UIImagePickerControllerSourceType) {
        
        /*if (self.imageView.isAnimating()) {
            self.imageView.stopAnimating()
        }*/
    
        /*
        if (self.capturedImages.count > 0)
        {
        [self.capturedImages removeAllObjects];
        }*/
    
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
    
        if (sourceType == UIImagePickerControllerSourceType.Camera) {
            // hide default controls
            imagePickerController.showsCameraControls = false
            imagePickerController.navigationBarHidden = true
            imagePickerController.toolbarHidden = true
            
            let screenSize: CGSize = UIScreen.mainScreen().bounds.size
            
            // iOS is going to calculate a size which constrains the 4:3 aspect ratio
            // to the screen size. We're basically mimicking that here to determine
            // what size the system will likely display the image at on screen.
            // NOTE: screenSize.width may seem odd in this calculation - but, remember,
            // the devices only take 4:3 images when they are oriented *sideways*.
            let cameraAspectRatio: CGFloat = 4.0 / 3.0;
            let imageWidth: CGFloat = screenSize.width * cameraAspectRatio
            let scale: CGFloat = (screenSize.height / imageWidth) * 10.0 / 10.0
            
            imagePickerController.cameraViewTransform = CGAffineTransformMakeScale(scale, scale)
            
            /*
            Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
            */
            NSBundle.mainBundle().loadNibNamed("CameraOverlayView", owner: self, options: nil)
            self.overlayView.frame = imagePickerController.cameraOverlayView.frame
            imagePickerController.cameraOverlayView = self.overlayView
        }
    
        self.imagePickerController = imagePickerController
        self.presentViewController(self.imagePickerController!, animated: true, completion: nil)
    }
    
//    func navigationController(navigationController: UINavigationController!, willShowViewController viewController: UIViewController!, animated: Bool) {
//        
//        UIApplication.sharedApplication().statusBarHidden = true
//    }
}

