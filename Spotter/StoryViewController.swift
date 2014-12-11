//
//  PreviewViewController.swift
//  Spotter
//
//  Created by LV426 on 9/11/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

let kStoryHashtag = "#untitled"
let kSummary = "Summary"


class StoryViewController: UIViewController, LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, CTAssetsPickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var deleteBtn: UIButton!
    
    let cellSpacing: CGFloat = 3.0
    let sideInset: CGFloat = 6.0

    // ordered collection of resources
    var cubes: NSMutableArray = NSMutableArray()
    // story is editable
    var editable: Bool = false
        
    var storyContent: StoryContent?
    var storyInfo: StoryInfo?
    var downloadInfo: Bool = false

    let coreContext: CoreContext = CoreContext()

    var titleTextField: UITextField?
    var addingText: Bool = false
    var addingImage: Bool = false
    var keyboardIsVisible: Bool = false
    
    // index of selected cube/UIView
    var currentIndexPath: NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
    var selectedIndexPath: NSIndexPath?
    var selectedCell: UICollectionViewCell?
    var titleCell: StoryTitleCollectionViewCell?
    
    // stuff used to position the view when the keyboard slides into view
    var collectionViewFrame: CGRect = CGRectZero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create an editable text field on the navigation bar
        self.titleTextField = UITextField(frame: CGRectMake(0, 0, 200, 22))
        self.titleTextField!.returnKeyType = UIReturnKeyType.Done
        self.titleTextField!.delegate = self
        self.titleTextField!.text = kStoryHashtag
        self.titleTextField!.font = UIFont.boldSystemFontOfSize(19)
        self.titleTextField!.textColor = UIColor.whiteColor()
        self.titleTextField!.textAlignment = NSTextAlignment.Center
        self.navigationItem.titleView = self.titleTextField!
        
        self.collectionViewFrame = self.collectionView.frame
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // if there is no story create a new one
        if (self.storyInfo == nil) {
            // create a new story
            self.cubes.removeAllObjects()
            self.editable = true
            
            // create a new child id for this story
            let uid = EKClient.authData!.uid
            let newStoryRef = EKClient.stories.childByAutoId()
            // this is the reference to the S3 bucket where the story data will live
            let bucket = "eyekon/\(uid)/\(newStoryRef.key)"
            let coverImage = UIImage(named: "placeholder.png")!

            // create new story and story content models
            let story: Story = NSEntityDescription.insertNewObjectForEntityForName("Story",
                inManagedObjectContext: self.coreContext.context) as Story
            let content = NSEntityDescription.insertNewObjectForEntityForName("StoryContent",
                inManagedObjectContext: self.coreContext.context) as StoryContent

            story.uid = uid
            story.title = kStoryHashtag
            story.summary = kSummary
            story.storyID = newStoryRef.key
            story.content = content
            content.story = story
            
            self.storyContent = content
            self.storyInfo = StoryInfo(storyID: newStoryRef.key, authorID: EKClient.authData!.uid,
                hashtag: kStoryHashtag, summary: "Summary", thumbnail: coverImage,
                cubeCount: 0, s3Bucket: bucket)
            
            // default image for title image
            self.cubes.addObject(coverImage)
           
        } else if (self.downloadInfo) {
            self.downloadStoryFromS3()
        }
        
        // add myself as an observer of the keyboard showing and hiding
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification, object: nil)

        // by default the deleteBtn should be disabled until a user 
        // selects a resource in edit mode
        self.deleteBtn.enabled = false
        
        // defaults as the end of the data source minus one to account for title resource
        self.currentIndexPath = NSIndexPath(forItem: self.cubes.count-1, inSection: 1)
        
        self.titleTextField!.userInteractionEnabled = self.editable
        self.titleTextField!.text = self.storyInfo!.hashtag

        if (self.editable) {
            // show toolbar
            self.showToolbar(false)
        } else {
            // hide toolbar offscreen
            self.toolbar.frame.origin.y = self.view.frame.size.height
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (!self.addingImage) {
            // if this controller is dissappearing because we are not adding an image remove the notification listeners
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    @IBAction func addPhotoFromCamera(sender: AnyObject) {
        self.addingImage = true
        self.performSegueWithIdentifier("FromStoryToCapture", sender: self)
    }
    
    @IBAction func addPhotoFromLibrary(sender: AnyObject) {
        self.addingImage = true

        let picker: CTAssetsPickerController = CTAssetsPickerController()
        picker.delegate = self
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    // TODO this needs work
    @IBAction func addText(sender: AnyObject) {
        self.addingText = true
        let size = self.textSize("text")
        
        let frameWidth = self.collectionView.frame.size.width - self.sideInset * 2
        let rect = CGRectMake(0, 0, frameWidth, size.height)
        //let textView = CSGrowingTextView(frame: CGRectMake(0, 0, frameWidth, size.height))
        //textView.maximumNumberOfLines = 50
        //textView.growDirection = CSGrowDirection.Down
        //textView.delegate = self
        
        let textView = UITextView(frame: rect)
        textView.scrollEnabled = false
        textView.font = UIFont.systemFontOfSize(20)
        textView.delegate = self
        textView.returnKeyType = UIReturnKeyType.Done
        textView.inputAccessoryView = nil
        textView.userInteractionEnabled = true
        textView.textAlignment = NSTextAlignment.Center
        
        
        self.deleteBtn.enabled = true
        self.selectedIndexPath = self.currentIndexPath
        self.cubes.insertObject(textView, atIndex: self.currentIndexPath.item + 1)
        self.collectionView.insertItemsAtIndexPaths([self.currentIndexPath])
        
        // if the cell beyond the view bounds this will return nil
        let cell = self.collectionView.cellForItemAtIndexPath(self.currentIndexPath)
    
        if (cell != nil) {
            textView.becomeFirstResponder()
            self.currentIndexPath = NSIndexPath(forItem: self.currentIndexPath.item+1, inSection: self.currentIndexPath.section)
            
        } else {
            
            UIView.animateWithDuration(0.3, animations: {
                self.collectionView.scrollToItemAtIndexPath(self.currentIndexPath,
                    atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: false)
                },
                completion: { (bool) in
                    textView.becomeFirstResponder()
                    self.currentIndexPath = NSIndexPath(forItem: self.currentIndexPath.item+1, inSection: self.currentIndexPath.section)
            })
        }
    }
    
    @IBAction func changeCoverPhoto(sender: AnyObject) {
        self.addingImage = true

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.delegate = self
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func deleteSelected(sender: AnyObject) {
        // there must be a selected item before the user can delete
        if (self.selectedIndexPath == nil || self.selectedCell == nil) {
            return
        }
        
        
        self.cubes.removeObjectAtIndex(self.selectedIndexPath!.item+1)
        self.collectionView.deleteItemsAtIndexPaths([self.selectedIndexPath!])
        
        // move current index path to previous index item
        if (self.currentIndexPath.item > 0) {
            self.currentIndexPath = NSIndexPath(forItem: self.currentIndexPath.item-1, inSection: self.currentIndexPath.section)
        }
        
        // remove border from the selected cell
        self.selectedCell!.layer.borderWidth = 0.0
        self.selectedCell = nil
        
        self.selectedIndexPath = nil
        self.deleteBtn.enabled = false
    }
    
    // deletes the entire story from user's profile
    // TODO what should happen if a story has been published to the cloud?
    @IBAction func deleteStory(sender: AnyObject) {
        let alertController = UIAlertController(title:"Warning!",
            message: "Are you sure you want to delete this? This will remove the entire entry from your collection.",
            preferredStyle:UIAlertControllerStyle.Alert)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default, handler: {(alert :UIAlertAction!) in
            self.storyContent!.managedObjectContext!.deleteObject(self.storyContent!.story)
            
            var error: NSError?
            if (!self.storyContent!.managedObjectContext!.save(&error)) {
                println("StoryViewController: could not delete entry from collection")
            }
            
            self.performSegueWithIdentifier("FromStoryToProfile", sender: self)
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func editStory(sender: AnyObject) {
        self.editable = true
        self.collectionView.userInteractionEnabled = true
        self.titleTextField!.userInteractionEnabled = true
        
        self.titleCell!.textField.userInteractionEnabled = true
        self.titleCell!.changeImageBtn.hidden = false
        
        for resource in self.cubes {
            if (resource is UITextView) {
                (resource as UITextView).userInteractionEnabled = false
            }
        }
        self.showToolbar(true)
    }
    
    @IBAction func expandTools(sender: AnyObject) {
        var rect = (sender as UIButton).frame
        rect.size.height *= 2
        
        let saveItem = KxMenuItem("Save", image: nil, target: self, action: "saveStory:")
        let editItem = KxMenuItem("Edit", image: nil, target: self, action: "editStory:")
        let deleteItem = KxMenuItem("Delete", image: nil, target: self, action: "deleteStory:")
        let publishItem = KxMenuItem("Share", image: nil, target: self, action: "shareStory:")
        
        KxMenu.showMenuInView(self.navigationController!.view, fromRect: rect, menuItems: [saveItem, editItem, deleteItem, publishItem])
    }
    
    @IBAction func saveStory(sender: AnyObject) {
        let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(self.cubes)
        self.storyContent!.data = data
        self.storyContent!.story.title = self.titleTextField!.text
        
        var error: NSError?
        if( !self.storyContent!.managedObjectContext!.save(&error)) {
            println("StoryViewController could not save story: \(error?.localizedDescription)")
        }
    }
    
    @IBAction func shareStory(sender: AnyObject) {
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let storyID = self.storyInfo!.storyID
            let thumbnailData = UIImageJPEGRepresentation(self.storyInfo!.thumbnail, 1.0)
            let bucket = self.storyInfo!.s3Bucket
            let uid = self.storyInfo!.authorID
            var dataTypes: [String] = []
            
            var error: NSError?
            let thumbnailDataCompressed = BZipCompression.compressedDataWithData(thumbnailData,
                blockSize: BZipDefaultBlockSize, workFactor: BZipDefaultWorkFactor, error: &error)
            
            if (error != nil) {
                println("StoryViewController could not compress thumbnail: \(error)")
                return
            }
            
            // send all cube data to AWS S3 bucket
            for (var i = 0; i < self.cubes.count; ++i) {
                
                let numStr = String(i)
                let path = NSTemporaryDirectory().stringByAppendingPathComponent(numStr)
                let cube: AnyObject = self.cubes[i]
                
                dataTypes.append(_stdlib_getTypeName(cube))
                
                // TODO: the cube may be a UITextView also
                var cubeData: NSData = NSData()
                if (cube is UIImage) {
                    let image = cube as UIImage
                    cubeData = self.compressForUpload(image, maxFileSize: 600*1024)
                } else if (cube is UITextView) {
                    cubeData = NSKeyedArchiver.archivedDataWithRootObject(cube as UITextView)
                }
                
                let compressedPayload = BZipCompression.compressedDataWithData(cubeData,
                    blockSize: BZipDefaultBlockSize, workFactor: BZipDefaultWorkFactor, error: &error)
                compressedPayload.writeToFile(path, atomically: true)
                
                let url = NSURL(fileURLWithPath: path)
                
                let request = AWSS3TransferManagerUploadRequest()
                request.bucket = bucket
                request.key = numStr
                request.body = url
                
                let transferManager = AWSS3TransferManager.defaultS3TransferManager()
                transferManager.upload(request).continueWithBlock { (task: BFTask!) -> AnyObject! in
                    
                    if (task.error != nil) {
                        println("StoryViewController error in upload: \(task.error)")
                    }
                    
                    return nil
                }
            }
            
            // add a node under the user-stories
            // note: not sure how this is to be used yet
            let userStories = EKClient.appRef.childByAppendingPath("user-stories")
                .childByAppendingPath(uid)
                .childByAppendingPath(storyID)
            userStories.setValue(["hashtag": self.titleTextField!.text])
            
            // convert thumbnail compressed data to base 64 string since nsdata is not accepted by firebase
            // send the story info to firebase
            let newStoryRef = EKClient.stories.childByAppendingPath(storyID)
            let base64String = thumbnailDataCompressed.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
            newStoryRef.setValue(["authorID": uid, "hashtag": self.titleTextField!.text,
                "summary": self.storyContent!.story.summary, "thumbnailStr": base64String,
                "cubeCount": self.cubes.count, "s3Bucket": bucket, "dataTypes": dataTypes])
        })
    }
 
    
    // MARK: - Random Stuff
    
    // add images to this story
    func addImages(images: [UIImage]) {
        
        for (var i = 0; i < images.count; ++i) {
            var image = images[i]
            
            // compress the image if the data size is greater than our 
            // max image KB size
            var data = UIImageJPEGRepresentation(image, 1.0)
            if (data.length > kImageKB) {
                data = self.compressForUpload(image, maxFileSize: kImageKB)
                image = UIImage(data: data)!
            }
            
            self.cubes.insertObject(image, atIndex: self.currentIndexPath.item+1)
            
            self.collectionView.insertItemsAtIndexPaths([self.currentIndexPath])
            self.collectionView.scrollToItemAtIndexPath(self.currentIndexPath, atScrollPosition: UICollectionViewScrollPosition.Top, animated: true)
            self.currentIndexPath = NSIndexPath(forItem: self.currentIndexPath.item+1, inSection: self.currentIndexPath.section)
        }
    }

    // compress an image down to a max file size
    // TODO needs to be more accurate
    func compressForUpload(original: UIImage, maxFileSize: Int) -> NSData {
        
        let maxCompression: CGFloat = 0.1
        var compression: CGFloat = 0.9
        
        var imageData: NSData = UIImageJPEGRepresentation(original, compression);
        
        while (imageData.length > maxFileSize && compression > maxCompression) {
            compression -= 0.1
            imageData = UIImageJPEGRepresentation(original, compression)
        }
        
        return imageData
    }
    
    func downloadStoryFromS3() {
        let storyInfo = self.storyInfo!
        if (storyInfo.authorID != EKClient.authData!.uid) {
            EKClient.usersURL.childByAppendingPath(storyInfo.authorID).observeSingleEventOfType(.Value,
                withBlock: { (data: FDataSnapshot!) -> Void in
                    if (data.value === NSNull()) {
                        return
                    }
                    
                    let first = data.value["first"] as NSString
                    let last  = data.value["last"] as NSString
                    let base64Image: NSString? = data.value["profileImage"] as? NSString
                    var image = UIImage(named: "contact-default.png")
                    
                    if (base64Image != nil) {
                        
                        let data = NSData(base64EncodedString: base64Image!, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                        image = UIImage(data: data!)
                    }
                    
                    let titleHeight = self.navigationItem.titleView!.frame.size.height
                    let titleWidth = self.navigationItem.titleView!.frame.size.width
                    let button = UIButton(frame: CGRectMake(0, 0, titleHeight * 1.5, titleHeight * 1.5))
                    button.layer.cornerRadius = titleHeight * 1.5 / 2
                    button.clipsToBounds = true
                    button.setImage(image, forState: UIControlState.Normal)
                    button.center = CGPointMake(titleWidth - titleHeight/2, titleHeight/2)
                    self.navigationItem.titleView?.clipsToBounds = false
                    self.navigationItem.titleView?.addSubview(button)
            })
        }
        
        // TODO you need status indicators
        for (var j = 0; j < self.storyInfo!.dataTypes.count; ++j) {
            let image = UIImage(named: "placeholder.png")
            self.cubes.addObject(image!)
        }
        
        for (var i = 0; i < self.storyInfo!.dataTypes.count; ++i) {
            
            let key = String(i)
            
            let downloadingFilePath = NSTemporaryDirectory().stringByAppendingPathComponent(key)
            let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath)
            let dataType = self.storyInfo!.dataTypes[i]
            
            let fileManager: NSFileManager = NSFileManager.defaultManager()
            var error: NSError?
            if (fileManager.fileExistsAtPath(downloadingFilePath)) {
                if (!fileManager.removeItemAtPath(downloadingFilePath, error: &error) ) {
                    println("Could not remove temporary file \(error)")
                }
            }
            
            // Construct the download request.
            let downloadRequest: AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
            
            downloadRequest.bucket = storyInfo.s3Bucket
            downloadRequest.key = key
            downloadRequest.downloadingFileURL = downloadingFileURL
            
            let transferManager: AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
            
            transferManager.download(downloadRequest).continueWithBlock({
                (task: BFTask!) -> AnyObject! in
                
                if (task.error != nil) {
                    println("StoryViewController download error: \(task.error)")
                }
                
                if (task.result != nil) {
                    
                    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        
                        let index = downloadingFilePath.lastPathComponent.toInt()!
                        let indexPath = NSIndexPath(forItem: index, inSection: 0)
                        
                        //let downloadOutput: AWSS3TransferManagerDownloadOutput = task.result as AWSS3TransferManagerDownloadOutput
                        var data = NSData(contentsOfFile: downloadingFilePath)!
                        data = BZipCompression.decompressedDataWithData(data, error: &error)
                 
                        if (dataType == "UIImage") {
                            let image = UIImage(data: data)!
                            self.cubes[index] = image
                        } else if (dataType == "UITextView") {
                            dispatch_async(dispatch_get_main_queue(), {
                                let textView = NSKeyedUnarchiver.unarchiveObjectWithData(data) as UITextView
                                self.cubes[index] = textView
                            })
                        }
                        
                        if (self.cubes.count == self.storyInfo!.dataTypes.count) {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.collectionView.reloadData()
                            })
                        }
                    })
                }
                return nil
            })
        }
    }
    
    func imageFrameSize(image: UIImage) -> CGSize {
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let viewWidth = self.collectionView.frame.size.width - self.sideInset * 2
        let viewHeight = imageHeight * viewWidth / imageWidth
        return CGSizeMake(viewWidth, viewHeight)
    }
    
    func moveView(userInfo: Dictionary<NSObject, AnyObject>, up: Bool) {
        var keyboardEndFrame: CGRect = CGRectZero
        (userInfo[UIKeyboardFrameEndUserInfoKey]! as NSValue).getValue(&keyboardEndFrame)
        
        if (up) {
            
            // if adding text in a cube resource
            if (self.addingText) {
                let attributes = self.collectionView.layoutAttributesForItemAtIndexPath(self.selectedIndexPath!)!
                let frame = self.collectionView.convertRect(attributes.frame, toView: self.view)
                let dy = keyboardEndFrame.origin.y - (frame.origin.y + frame.size.height)
                var contentOffset = self.collectionView.contentOffset
                contentOffset.y -= (dy - self.cellSpacing)
                self.collectionView.setContentOffset(contentOffset, animated: true)
            }
            
            // set the view frame so we can restore its size when the keyboard dissapears
            self.collectionViewFrame = self.collectionView.frame
            self.collectionView.frame = CGRectMake(self.collectionViewFrame.origin.x, self.collectionViewFrame.origin.y,
                self.collectionViewFrame.size.width, self.view.frame.size.height - keyboardEndFrame.size.height)
            self.keyboardIsVisible = true
        } else {
            self.collectionView.frame = self.collectionViewFrame
            self.keyboardIsVisible = false
        }
        
    }
    
    func setStoryContent(content: StoryContent) {
        let story = content.story
        let coverImage = UIImage(data: story.titleImage!)!

        self.storyContent = content
        
        if( content.data != nil) {
             //dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                // unarchive the story content as a ordered array of UIViews
                self.cubes = NSKeyedUnarchiver.unarchiveObjectWithData(content.data!) as NSMutableArray
            //})
        }
        
        // image data greater than thumbnail size?
        var thumbnail = coverImage
        if ( story.titleImage!.length > kThumbnailKB ) {
            let thumbnailData = self.compressForUpload(coverImage, maxFileSize: kThumbnailKB)
            thumbnail = UIImage(data: thumbnailData)!
        }
        
        let bucket = "eyekon/\(story.uid)/\(story.storyID)"
        self.storyInfo = StoryInfo(storyID: story.storyID, authorID: story.uid,
            hashtag: story.title, summary: story.summary, thumbnail: thumbnail,
            cubeCount: self.cubes.count, s3Bucket: bucket)
    }
    
    func setStoryInfo(storyInfo: StoryInfo) {
        self.storyInfo = storyInfo
        self.downloadInfo = true
    }
    
    func showToolbar(animated: Bool) {
        let cvSize = self.collectionView.frame.size
        let cvOrigin = self.collectionView.frame.origin
        let toolbarSize = self.toolbar.frame.size
        let viewSize = self.view.frame.size
        
        if (animated) {
            UIView.animateWithDuration(0.25,
                animations: {
                    self.toolbar.frame.origin.y = self.view.frame.size.height - self.toolbar.frame.size.height
                    
                }, completion: { (value: Bool) in
                    self.collectionView.frame = CGRectMake(cvOrigin.x, cvOrigin.y,
                        cvSize.width, viewSize.height - toolbarSize.height)
            })
        } else {
            self.toolbar.frame.origin.y = self.view.frame.size.height - self.toolbar.frame.size.height
            self.collectionView.frame = CGRectMake(cvOrigin.x, cvOrigin.y,
                cvSize.width, viewSize.height - toolbarSize.height)
        }
    }
    
    func textSize(text: String) -> CGSize {
        let frameWidth = self.collectionView.frame.width - self.sideInset * 2
        let str = NSString(string: text)
        let rect = str.boundingRectWithSize(CGSizeMake(frameWidth, CGFloat.max), options: NSStringDrawingOptions.UsesDeviceMetrics,
            attributes: [NSFontAttributeName : UIFont.systemFontOfSize(20)], context: nil)
        
        return CGSizeMake(frameWidth, rect.size.height + 15)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    // invoked after selecting photos from the library
    func assetsPickerController(picker: CTAssetsPickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        
        let images: [UIImage] = assets.map({ (var asset) -> UIImage in
            let a = asset as ALAsset
            
            let representation = a.defaultRepresentation()
            let cgImage = representation.fullResolutionImage().takeUnretainedValue()
            let orientation = UIImageOrientation(rawValue: representation.orientation().rawValue)!
            
            return UIImage(CGImage: cgImage, scale: 1.0, orientation: orientation)!
        })
        
        self.addImages(images)
        picker.dismissViewControllerAnimated(true, completion: nil)
        self.addingImage = false
    }
    
    // invoked after selecting a cover image
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        let compressedData = self.compressForUpload(image, maxFileSize: kImageKB)
        let newImage = UIImage(data: compressedData)!
        
        let cell: StoryTitleCollectionViewCell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as StoryTitleCollectionViewCell
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
        cell.imageView.image = newImage
        
        self.cubes[0] = newImage
        
        //self.coverImage = newImage
        self.storyContent!.story.titleImage = compressedData

        let thumbData: NSData = self.compressForUpload(image, maxFileSize: kThumbnailKB)
        self.storyInfo!.thumbnail = UIImage(data: thumbData)!
        self.addingImage = false
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if (segue.identifier == "FromStoryToCapture") {
            let destination: CaptureViewController = segue.destinationViewController as CaptureViewController
            destination.storyController = self
            //destination.loadTestImages()
        } else if (segue.identifier == "FromStoryToCircle") {
            let destination: AddContactViewController = segue.destinationViewController as AddContactViewController
            //destination.setPost(self.post!)
        } else if (segue.identifier == "FromStoryToShare") {
            //let destination: ShareViewController = segue.destinationViewController as ShareViewController
            //destination.storyInfo = self.storyInfo
        }
    }
    
    @IBAction func unwindToStory(unwindSegue: UIStoryboardSegue) {
    }
    
    // MARK: - Notifications
    func keyboardWillShow(notification: NSNotification) {
        self.moveView(notification.userInfo!, up:true)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.moveView(notification.userInfo!, up:false)
    }
    
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if (textField.tag == 1) {
            self.storyContent!.story.summary = textField.text
        }
        
        textField.resignFirstResponder()
        return false
    }

    // MARK: UITextViewDelegate
    func textViewDidChange(textView: UITextView) {
        // size to fit but maintain width
        let size = textView.frame.size
        textView.sizeToFit()
        textView.frame.size.width = size.width
        
        let dHeight = textView.frame.height - size.height
        
        if (dHeight != 0) {
            self.collectionView.contentOffset.y += dHeight
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
 
        if(text == "\n") {
            textView.userInteractionEnabled = false
            textView.resignFirstResponder()
            self.addingText = false
        }
        
        return true
    }
 
    // MARK: - UICollectionView Stuff
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.cellSpacing
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.cellSpacing
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // do not select if not editable, already selected, or indexPath is title section
        if (!self.editable || self.selectedIndexPath === indexPath || indexPath.section == 0) {
            return
        }
        
        if (self.selectedCell != nil) {
            // remove the border around the existing selection
            self.selectedCell!.layer.borderWidth = 0.0
        }
        
        let cell: UICollectionViewCell? = self.collectionView.cellForItemAtIndexPath(indexPath)
        let resource: AnyObject = self.cubes.objectAtIndex(indexPath.item + 1)
        
        // add a blue border around the new selection
        if (resource is UIImage) {
            cell!.layer.borderColor = UIColor(red: 0.64, green: 0.76, blue: 0.96, alpha: 1).CGColor
            cell!.layer.borderWidth = 3.0
        } else if (resource is UITextView) {
            cell!.layer.borderColor = UIColor(red: 0.64, green: 0.76, blue: 0.96, alpha: 1).CGColor
            cell!.layer.borderWidth = 1.0
        }
        
        self.deleteBtn.enabled = true
        self.selectedCell = cell
        self.currentIndexPath = indexPath
        self.selectedIndexPath = indexPath
    }
    
    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        if (indexPath.section == 0) {
            return
        }
        
        let resource: AnyObject = self.cubes.objectAtIndex(indexPath.item+1)
        if (resource is UITextView && self.addingText && self.selectedIndexPath == indexPath) {
            if (self.selectedCell != nil) {
                // remove the border around the existing selection
                self.selectedCell!.layer.borderWidth = 0.0
            }

            cell.layer.borderColor = UIColor(red: 0.64, green: 0.76, blue: 0.96, alpha: 1).CGColor
            cell.layer.borderWidth = 1.0
            self.selectedCell = cell
        }
    }
    
    func collectionView(collectionView: UICollectionView!, canMoveItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return self.editable
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, willMoveToIndexPath toIndexPath: NSIndexPath!) {
        
        let resource: AnyObject = self.cubes.objectAtIndex(fromIndexPath.item+1)
        self.cubes.removeObject(resource)
        self.cubes.insertObject(resource, atIndex: toIndexPath.item+1)
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // if title section
        if (indexPath.section == 0) {
            let cell: StoryTitleCollectionViewCell = self.collectionView
                .dequeueReusableCellWithReuseIdentifier("TitleCell", forIndexPath: indexPath) as StoryTitleCollectionViewCell
            
            cell.textField.text = self.storyInfo!.summary
            cell.textField.tag = 1
            cell.textField.delegate = self
            
            // assign title cell
            if (self.titleCell == nil) {
                self.titleCell = cell
            }
            
            // if not in edit mode the title cell should not be editable
            if (!self.editable) {
                self.titleCell!.textField.userInteractionEnabled = false
                self.titleCell!.changeImageBtn.hidden = true
            }
        
            // cell image will always come from the first cube
            cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
            cell.imageView.image = (self.cubes[0] as UIImage)
            
            return cell
        } else {
            let cell: ResizeableCollectionCell = self.collectionView
                .dequeueReusableCellWithReuseIdentifier("StoryCell", forIndexPath: indexPath) as ResizeableCollectionCell
            
            let resource: AnyObject = self.cubes.objectAtIndex(indexPath.item+1)
            
            if (resource is UITextView) {
                let textView = resource as UITextView
                textView.delegate = self
                cell.contentView.addSubview(textView)
            } else if (resource is UIImage) {
                let image = resource as UIImage
                let size = self.imageFrameSize(image)
                let imageView = UIImageView(frame: CGRectMake(0, 0, size.width, size.height))
                imageView.image = image
                
                cell.contentView.addSubview(imageView)
            } else if (resource is UIView) {
                cell.contentView.addSubview(resource as UIView)
            }
            
            cell.maxWidth = self.collectionView.frame.size.width - self.sideInset * 2
            cell.contentView.autoresizesSubviews = false
            cell.enableResize(false)
            
            return cell
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (section == 0) {
            return 1
        } else {
            return self.cubes.count-1
        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!,
        doubleTapIndexPath indexPath: NSIndexPath!) {
            
        if (!self.editable || indexPath.section == 0) {
            return
        }
        
        self.selectedIndexPath = indexPath
        
        let index = indexPath.item + 1
        let resource: AnyObject = self.cubes.objectAtIndex(index)
        
        if (resource is UITextView) {
            self.addingText = true
            let textView: UITextView = (resource as UITextView)
            
            textView.inputAccessoryView = nil
            textView.userInteractionEnabled = true
            textView.reloadInputViews()
            
            textView.becomeFirstResponder()
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if (indexPath.section == 1) {
            let resource: AnyObject = self.cubes.objectAtIndex(indexPath.item+1)
            
            if (resource is UIImage) {
                let image = resource as UIImage
                return self.imageFrameSize(image)
            } else {
                
                let textView = resource as UITextView
                let frameWidth = self.collectionView.frame.width - self.sideInset * 2
                textView.frame.size.width = frameWidth
                return CGSizeMake(frameWidth, textView.frame.size.height)
            }
        } else {
            let size = self.collectionView.frame.size
            let viewHeight = self.view.frame.height
            return CGSizeMake(size.width, viewHeight/2)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        
        if (section == 1) {
            return UIEdgeInsets(top: self.sideInset, left: self.sideInset, bottom: 0, right: self.sideInset)
        }
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
