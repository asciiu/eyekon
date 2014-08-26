//
//  ViewController.swift
//  Spotter
//
//  Created by LV426 on 8/21/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class CaptureViewController: UIViewController , UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    
    // camera overlay view
    @IBOutlet var overlayView: UIView!
    @IBOutlet var previewView: UIImageView!

    var imagePickerController: UIImagePickerController?
    var capturedImages: [UIImage] = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // display alert if camera is not available
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let myAlertView: UIAlertView = UIAlertView(title: "Error", message: "Device has not camera", delegate: nil, cancelButtonTitle: "OK")
            myAlertView.show()
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    @IBAction func takePhoto(sender: AnyObject) {
//        
//        let imgView: UIImageView = UIImageView()
//        imgView.bounds = CGRectMake(100,100, 128, 128)
//        imgView.backgroundColor = UIColor.whiteColor()
//        
//        let picker: UIImagePickerController = UIImagePickerController()
//        
//        picker.delegate = self;
//        picker.allowsEditing = true;
//        picker.sourceType = UIImagePickerControllerSourceType.Camera
//        picker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.Camera)
//        
//        //picker.showsCameraControls = false
//        //picker.navigationBarHidden = true
//        //picker.toolbarHidden = true
//        //picker.cameraOverlayView = imgView
//        //picker.wantsFullScreenLayout = true;
//        
//        self.presentViewController(picker, animated: true, completion: {})
//    }
//    
//    @IBAction func selectPhoto(sender: AnyObject) {
//        let picker: UIImagePickerController = UIImagePickerController()
//        
//        picker.delegate = self;
//        picker.allowsEditing = true;
//        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
//        
//        self.presentViewController(picker, animated: true, completion: nil)
//    }
    
    @IBAction func takePhoto(sender: AnyObject){
        self.imagePickerController?.takePicture()
    }
    @IBAction func done(sender: AnyObject) {
        self.imagePickerController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func showImagePickerForCamera(sender: AnyObject) {
        self.showImagePickerForSourceType(UIImagePickerControllerSourceType.Camera)
    }
    
    @IBAction func showImagePickerForPhotoPicker(sender: AnyObject) {
        self.showImagePickerForSourceType(UIImagePickerControllerSourceType.PhotoLibrary)
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!) {
        
        let newImage: UIImage = info[UIImagePickerControllerOriginalImage] as UIImage
        
        self.capturedImages.append(newImage)
        self.previewView.image = newImage
        println(self.capturedImages.count)
        
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
        
        if (self.imageView.isAnimating()) {
            self.imageView.stopAnimating()
        }
    
        /*
        if (self.capturedImages.count > 0)
        {
        [self.capturedImages removeAllObjects];
        }*/
    
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        imagePickerController.sourceType = sourceType;
        imagePickerController.delegate = self;
    
        if (sourceType == UIImagePickerControllerSourceType.Camera) {
            // hide default controls
            imagePickerController.showsCameraControls = false;
    
            /*
            Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
            */
            NSBundle.mainBundle().loadNibNamed("CameraOverlayView", owner: self, options: nil)
            self.overlayView.frame = imagePickerController.cameraOverlayView.frame;
            imagePickerController.cameraOverlayView = self.overlayView;
        }
    
        self.imagePickerController = imagePickerController;
        self.presentViewController(self.imagePickerController!, animated: true, completion: nil)
    }
}

