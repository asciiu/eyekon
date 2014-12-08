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
let kThumbnailKB = 100 * 1024
let kImageKB = 500 * 1024

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
    var context: NSManagedObjectContext?
    let coreContext: CoreContext = CoreContext()

    var titleTextField: UITextField?
    
    // index of selected cube/UIView
    var currentIndexPath: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    var selectedIndexPath: NSIndexPath?
    var selectedCell: UICollectionViewCell?
    
    // main tool to add new content
//    var mainTool: AwesomeMenu?
//    var mainToolPosition: CGPoint = CGPointMake(0, 0)
//    
    var post: Dictionary<String, String>?
    var keyboardFrame: CGRect = CGRectZero
    
    var coverImage: UIImage?
    var storyInfo: StoryInfo?
    var downloadInfo: Bool = false
    var collectionViewFrame: CGRect = CGRectZero
    
    let imagePicker: UIImagePickerController = UIImagePickerController()
    
//    func awesomeMenu(menu: AwesomeMenu!, didSelectIndex idx: Int) {
//        
//        if (idx == 0) {
//            self.addText(self)
//        } else if (idx == 1) {
//            self.addPhotoFromLibrary(self)
//        } else if (idx == 2) {
//            self.addPhotoFromCamera(self)
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        
        // create an editable text field on the navigation bar
        self.titleTextField = UITextField(frame: CGRectMake(0, 0, 200, 22))
        self.titleTextField!.returnKeyType = UIReturnKeyType.Done
        self.titleTextField!.delegate = self
        self.titleTextField!.text = kStoryHashtag
        self.titleTextField!.font = UIFont.boldSystemFontOfSize(19)
        self.titleTextField!.textColor = UIColor.whiteColor()
        self.titleTextField!.textAlignment = NSTextAlignment.Center
        self.navigationItem.titleView = self.titleTextField!
        
//        let addImage = UIImage(named: "add.png")
//        let txtImage = UIImage(named: "txtTool.png")
//        let libImage = UIImage(named: "libTool.png")
//        let camImage = UIImage(named: "camTool.png")
//        
//        let txtBtn = AwesomeMenuItem(image: txtImage, highlightedImage: txtImage, contentImage: txtImage, highlightedContentImage: nil)
//        let camBtn = AwesomeMenuItem(image: camImage, highlightedImage: camImage, contentImage: camImage, highlightedContentImage: nil)
//        let libBtn = AwesomeMenuItem(image: libImage, highlightedImage: libImage, contentImage: libImage, highlightedContentImage: nil)
//        let addBtn = AwesomeMenuItem(image: addImage, highlightedImage: addImage, contentImage: addImage, highlightedContentImage: addImage)
        
//        self.mainTool = AwesomeMenu(frame: self.view.frame, startItem: addBtn, optionMenus: [txtBtn, libBtn, camBtn])
//        self.mainTool!.delegate = self
//        self.mainTool!.startPoint = CGPointMake(self.view.frame.size.width/2,
//                                            self.view.frame.size.height - addImage!.size.height/2)
//        
//        self.mainTool!.menuWholeAngle = CGFloat(-M_PI/3)
//        self.view.addSubview(self.mainTool!)
        
        self.collectionViewFrame = self.collectionView.frame
        
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if (self.storyInfo == nil) {
            // create a new story
            self.cubes.removeAllObjects()
            self.editable = true
            
            let newStoryRef = EKClient.stories.childByAutoId()
            let story: Story = NSEntityDescription.insertNewObjectForEntityForName("Story", inManagedObjectContext: self.context!) as Story
            story.uid = EKClient.authData!.uid
            story.title = kStoryHashtag
            story.summary = "Summary"
            story.storyID = newStoryRef.name
            
            let content = NSEntityDescription.insertNewObjectForEntityForName("StoryContent", inManagedObjectContext: self.context!) as StoryContent
            let bucket = "eyekon/" + EKClient.authData!.uid + "/" + newStoryRef.name

            story.content = content
            content.story = story
            self.storyContent = content
            
            self.storyInfo = StoryInfo(storyID: newStoryRef.name, authorID: EKClient.authData!.uid,
                hashtag: kStoryHashtag, summary: "Summary", thumbnail: UIImage(named: "placeholder.png")!,
                cubeCount: 0, s3Bucket: bucket)
            
            self.cubes.addObject(UIImage(named: "placeholder.png")!)
           
        } else if (self.downloadInfo) {
            let storyInfo = self.storyInfo!
            for (var j = 0; j < self.storyInfo!.cubeCount; ++j) {
                let image = UIImage(named: "placeholder.png")
                //let activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
                //activityIndicator.startAnimating()
                self.cubes.addObject(image!)
            }
            
            for (var i = 0; i < self.storyInfo!.cubeCount; ++i) {
                
                let key = String(i)
                
                let downloadingFilePath = NSTemporaryDirectory().stringByAppendingPathComponent(key)
                let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath)
                
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
                        println("download error \(task.error)")
                    }
                    
                    if (task.result != nil) {

                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        
                            //let downloadOutput: AWSS3TransferManagerDownloadOutput = task.result as AWSS3TransferManagerDownloadOutput
                            var data = NSData(contentsOfFile: downloadingFilePath)!
                            data = BZipCompression.decompressedDataWithData(data, error: &error)
                            
                            let image = UIImage(data: data)!
                            let index = downloadingFilePath.lastPathComponent.toInt()!
                            let indexPath = NSIndexPath(forRow: index, inSection: 0)
                           
                            self.cubes[index] = image
                            
                            println("download success \(index)")

                            if (self.cubes.count == self.storyInfo!.cubeCount) {
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
        
        self.deleteBtn.enabled = false
        
        //self.toolbar.frame.origin.y = self.view.frame.size.height

        //self.mainTool!.startPoint = CGPointMake(self.view.frame.size.width/2, 300)
        
        // defaults as the end of the data source minus one to account for title resource
        self.currentIndexPath = NSIndexPath(forItem: self.cubes.count-1, inSection: 1)
        
        self.titleTextField!.userInteractionEnabled = self.editable
        //self.showToolbar()

        if (self.editable) {
            // show toolbar
            self.toolbar.frame.origin.y = self.view.frame.size.height - self.toolbar.frame.size.height
        } else {
            // hide toolbar offscreen
            self.toolbar.frame.origin.y = self.view.frame.size.height
        }
       
        self.titleTextField!.text = self.storyInfo!.hashtag
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Custom stuff
    
    func computeRects(images: [UIImage]) -> [CGRect] {
        let frameWidth = self.collectionView.frame.width
        let imageCount = images.count
        let totalWidth = frameWidth - (self.cellSpacing * (CGFloat(images.count)-1))
        
        var r: CGFloat = 0
        for(var i = 0; i < imageCount; ++i) {
            let image = images[i]
            r += image.size.width / image.size.height
        }
        
        let height: CGFloat = totalWidth / r
        var rects: [CGRect] = [CGRect]()
        var x: CGFloat = 0
        
        for(var j = 0; j < imageCount; ++j) {
            let image = images[j]
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            let width = height * imageWidth / imageHeight
            let rect = CGRectMake(x, 0, width, height)
            
            x += width + self.cellSpacing

            rects.append(rect)
        }
        
        return rects
    }
    
//    func addImageSection(forImages: [UIImage]) {
//        let rects = self.computeRects(forImages)
//        var imageViews: NSMutableArray = NSMutableArray()
//        
//        for (var i = 0; i < rects.count; ++i) {
//            let rect = rects[i]
//            let image = forImages[i]
//            
//            let imageView = UIImageView(frame: rect)
//            imageView.image = image
//            imageViews.addObject(imageView)
//        }
//        
//        self.cubes.addObject(imageViews)
//        let sections = NSIndexSet(index: self.cubes.count - 1)
//        self.collectionView.insertSections(sections)
//    }
    
//    func addImages(images: [UIImage]) {
//        var imageGroups: [[UIImage]] = [[]]
//        var imageGroup: [UIImage] = []
//
//        for (var i = 0; i < images.count; ++i) {
//            imageGroup.append(images[i])
//            
//            if (imageGroup.count == 3) {
//                imageGroups.append(imageGroup)
//                imageGroup = []
//            } else if (i == images.count - 1) {
//                imageGroups.append(imageGroup)
//            }
//        }
//        
//        let frameWidth = self.collectionView.frame.size.width
//        for (var i = 0; i < imageGroups.count; ++i) {
//            let group = imageGroups[i]
//            let frameContentWidth = (frameWidth - (self.sideInset * 2) - (CGFloat(group.count-1) * self.cellSpacing)) / CGFloat(group.count)
//            //let rects = self.computeRects(group)
//            
//            for (var r = 0; r < group.count; ++r) {
//                let frame = CGRectMake(0, 0, frameContentWidth, frameContentWidth)
//                let imageView = UIImageView(frame: frame)
//                imageView.image = group[r]
//                imageView.contentMode = UIViewContentMode.ScaleAspectFill
//                self.cubes.insertObject(imageView, atIndex: self.currentIndexPath.row)
//
//                self.collectionView.insertItemsAtIndexPaths([self.currentIndexPath])
//                self.currentIndexPath = NSIndexPath(forRow: self.currentIndexPath.row+1, inSection: self.currentIndexPath.section)
//            }
//        }
//    }
    
    func compressForUpload(original: UIImage, maxFileSize: Int) -> NSData {
        
        let maxCompression: CGFloat = 0.1
        var compression: CGFloat = 0.9
        
        var imageData: NSData = UIImageJPEGRepresentation(original, compression);
        
        while (imageData.length > maxFileSize && compression > maxCompression) {
            compression -= 0.1
            imageData = UIImageJPEGRepresentation(original, compression)
        }
        
        // Calculate new size given scale factor.
//        let originalSize: CGSize = original.size
//        let newSize: CGSize = CGSizeMake(originalSize.width * scale, originalSize.height * scale)
//        
//        // Scale the original image to match the new size.
//        UIGraphicsBeginImageContext(newSize)
//        original.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
//        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
        
        return imageData
    }
    
    func addImages(images: [UIImage]) {
        
        for (var i = 0; i < images.count; ++i) {
            var image = images[i]
            
            var data = UIImageJPEGRepresentation(image, 1.0)
            if (data.length > kImageKB) {
                data = self.compressForUpload(image, maxFileSize: kImageKB)
                image = UIImage(data: data)!
            }
            
            //let scaledImage = self.compressForUpload(images[i], scale: 0.20)

            //self.cubes.insertObject(image, atIndex: self.cubes.count)
            
            self.cubes.insertObject(image, atIndex: self.currentIndexPath.item+1)
            
            //let indexPath = NSIndexPath(forItem: self.cubes.count-1, inSection: 1)
            self.collectionView.insertItemsAtIndexPaths([self.currentIndexPath])
            self.currentIndexPath = NSIndexPath(forItem: self.currentIndexPath.item+1, inSection: self.currentIndexPath.section)
        }
    }
    
    // edit selected text
    func setStoryContent(content: StoryContent) {
        let story = content.story
        let coverImage = UIImage(data: story.titleImage!)!

        self.storyContent = content
        self.coverImage = coverImage
        
        if( content.data != nil) {
            // unarchive the story content as a ordered array of UIViews
            self.cubes = NSKeyedUnarchiver.unarchiveObjectWithData(content.data!) as NSMutableArray
        }
        
        let thumbnailData = self.compressForUpload(coverImage, maxFileSize: 100*1024)
        let thumbnail = UIImage(data: thumbnailData)!
        let bucket = "eyekon/" + EKClient.authData!.uid + "/" + story.uid
        self.storyInfo = StoryInfo(storyID: story.storyID, authorID: story.uid,
            hashtag: story.title, summary: story.summary, thumbnail: thumbnail,
            cubeCount: self.cubes.count, s3Bucket: bucket)
    }
    
    func setStoryInfo(storyInfo: StoryInfo) {
        self.storyInfo = storyInfo
        self.downloadInfo = true
        
//        for (var i = 0; i < 1; ++i) {
//            
//            let key = String(i)
//
//            //dispatch_async(dispatch_get_main_queue(), {
//                let downloadingFilePath = NSTemporaryDirectory().stringByAppendingPathComponent(key)
//                let downloadingFileURL = NSURL(fileURLWithPath: downloadingFilePath)
//                
//                let fileManager: NSFileManager = NSFileManager.defaultManager()
//                var error: NSError?
//                if (fileManager.fileExistsAtPath(downloadingFilePath)) {
//                    if (!fileManager.removeItemAtPath(downloadingFilePath, error: &error) ) {
//                            println("Could not remove temporary file \(error)")
//                    }
//                }
//                
//                // Construct the download request.
//                let downloadRequest: AWSS3TransferManagerDownloadRequest = AWSS3TransferManagerDownloadRequest()
//                
//                downloadRequest.bucket = storyInfo.s3Bucket
//                downloadRequest.key = key
//                downloadRequest.downloadingFileURL = downloadingFileURL
//                
//                let transferManager: AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
//                
//                transferManager.download(downloadRequest).continueWithSuccessBlock({
//                    (task: BFTask!) -> AnyObject! in
//                        if (task.error != nil) {
//                            println("download error \(task.error)")
//                        }
//                        
//                        if (task.result != nil) {
//                            let downloadOutput: AWSS3TransferManagerDownloadOutput = task.result as AWSS3TransferManagerDownloadOutput
//                            var data = NSData(contentsOfFile: downloadingFilePath)!
//                            data = BZipCompression.decompressedDataWithData(data, error: &error)
//                            
//                            let image = UIImage(data: data)!
//                            let index = downloadingFilePath.lastPathComponent.toInt()!
//                            let indexPath = NSIndexPath(forItem: index, inSection: 0)
//                            self.cubes.insertObject(image, atIndex: index)
//                            
//                            //self.collectionView.insertItemsAtIndexPaths([indexPath])
//                            
//                            println("download success \(index)")
//                        }
//                        return nil
//                })
//            //})
//        }
    }
    
    func showToolbar() {
        UIView.animateWithDuration(0.25,
            animations: {
                //self.mainTool!.alpha = 1.0
                //self.mainTool!.startPoint = self.mainToolPosition

                self.toolbar.frame.origin.y = self.view.frame.size.height - self.toolbar.frame.size.height
                
            }, completion: { (value: Bool) in
                //self.mainTool!.userInteractionEnabled = true
                let tableSize = self.collectionView.frame.size
                let tableOrigin = self.collectionView.frame.origin
                let toolbarSize = self.toolbar.frame.size
                let viewSize = self.view.frame.size
                self.collectionView.frame = CGRectMake(tableOrigin.x, tableOrigin.y, tableSize.width, viewSize.height - toolbarSize.height)
        })
    }
    
    // MARK: - Actions
    
    @IBAction func changeCoverPhoto(sender: AnyObject) {
        self.presentViewController(self.imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func deleteSelected(sender: AnyObject) {
        if (self.selectedIndexPath == nil) {
            return
        }
        
        // need to remove view from the selected cell otherwise reusable cells will still
        // contain this view
        //let view: UIView = self.cubes.objectAtIndex(self.selectedIndexPath!.row) as UIView
        //view.removeFromSuperview()
        let contentView = self.collectionView.cellForItemAtIndexPath(self.selectedIndexPath!)!.contentView
        for view in contentView.subviews {
            view.removeFromSuperview()
        }
        
        self.cubes.removeObjectAtIndex(self.selectedIndexPath!.item)
        self.collectionView.deleteItemsAtIndexPaths([self.selectedIndexPath!])
        
        // move current index path to previous index item
        if (self.currentIndexPath.row > 0) {
            self.currentIndexPath.row.advancedBy(-1)
        }

        self.selectedCell = nil
        self.selectedIndexPath = nil
        self.deleteBtn.enabled = false
    }
    
    @IBAction func returnToPrevious(sender: AnyObject) {
        // pop myself off the stack of view controllers and show the previous 
        self.navigationController?.popViewControllerAnimated(true)
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
        for view in self.cubes {
            if (view is UIImageView) {
                (view as UIImageView).highlighted = false
            }
        }
        
        let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(self.cubes)
        self.storyContent!.data = data
        self.storyContent!.story.title = self.titleTextField!.text
        
        var error: NSError?
        if( !self.storyContent!.managedObjectContext!.save(&error)) {
            println("could not save FrameSet: \(error?.localizedDescription)")
        }
    }
    
    @IBAction func editStory(sender: AnyObject) {
        self.editable = true
        self.collectionView.userInteractionEnabled = true
        self.titleTextField!.userInteractionEnabled = true
        
        for resource in self.cubes {
            
            if (resource is UITextView) {
                (resource as UITextView).userInteractionEnabled = true
            }
            //let view = self.cubes.objectAtIndex(i) as UIView
            
            // this ensures that text cubes are draggable when touched
            //view.userInteractionEnabled = false
            
        }
        self.showToolbar()
    }
    
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
    
    @IBAction func shareStory(sender: AnyObject) {
    
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let storyID = self.storyContent!.story.storyID
            let newStoryRef = EKClient.stories.childByAppendingPath(storyID)
            //let data = self.storyContent!.story.titleImage
            //let thumbnailData = self.compressForUpload(self.storyInfo!.titleImage, maxFileSize: 100*124)
            let thumbnailData = UIImageJPEGRepresentation(self.storyInfo!.thumbnail, 1.0)
            let bucket = "eyekon/" + EKClient.authData!.uid + "/" + storyID
            
//            if (data == nil) {
//                return
//            }
            var error: NSError?
            let thumbnailDataCompressed = BZipCompression.compressedDataWithData(thumbnailData, blockSize: BZipDefaultBlockSize, workFactor: BZipDefaultWorkFactor, error: &error)
            
            if (error != nil) {
                println("StoryViewController could not compress thumbnail: \(error)")
                return
            }
            
            let userStories = EKClient.appRef.childByAppendingPath("user-stories").childByAppendingPath(EKClient.authData!.uid).childByAppendingPath(storyID)
            userStories.setValue(["hashtag": self.titleTextField!.text])

            let base64String = thumbnailDataCompressed.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
            //let chunks: [NSString] = divideString(base64String)
            newStoryRef.setValue(["authorID": EKClient.authData!.uid, "hashtag": self.titleTextField!.text,
                "summary": self.storyContent!.story.summary, "thumbnailStr": base64String,
                "cubeCount": self.cubes.count, "s3Bucket": bucket])
            
            for (var i = 0; i < self.cubes.count; ++i) {
                
                let numStr = String(i)
                let path = NSTemporaryDirectory().stringByAppendingPathComponent(numStr)
                let cube: AnyObject = self.cubes[i]
                
                // TODO: the cube may be straight text
                let image = cube as UIImage
                let cubeData: NSData = self.compressForUpload(image, maxFileSize: 600*1024)
                
                let compressedPayload = BZipCompression.compressedDataWithData(cubeData, blockSize: BZipDefaultBlockSize, workFactor: BZipDefaultWorkFactor, error: &error)
                
                compressedPayload.writeToFile(path, atomically: true)
                
                let url = NSURL(fileURLWithPath: path)
                
                let request = AWSS3TransferManagerUploadRequest()
                request.bucket = bucket
                request.key = numStr
                request.body = url
                
                let transferManager = AWSS3TransferManager.defaultS3TransferManager()
                transferManager.upload(request).continueWithBlock { (task: BFTask!) -> AnyObject! in
                    
                    if (task.error != nil) {
                        println("Error in transfer \(task.error)")
                    }
                    
                    return nil
                }
            }
        })
        
//        request.uploadProgress = {(bytesSent, totalBytesSent, totalBytesExpectedToSend) -> Void in
//            
//            dispatch_async(dispatch_get_main_queue(), {
//                //Update progress.
//                println("what?")
//            })
//        }
        
//        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
//        transferManager.upload(request).continueWithBlock { (task: BFTask!) -> AnyObject! in
//            
//            if (task.error != nil) {
//                println("Error in transfer \(task.error)")
//            } else {
//                println("Successful upload!")
//            }
//            
//            return nil
//        }
        
        //let base64Cubes = compressedData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed)
        //let cubedChunks: [NSString] = divideString(base64Cubes)

        //newStoryRef.childByAppendingPath("titleData").setValue(chunks)
        //newStoryRef.childByAppendingPath("cubeData").setValue(cubedChunks)
    }
    
//    @IBAction func publish(sender: AnyObject) {
//        
//        //let index = self.selectedIndex?.row ?? 0
//        
//        if (self.upperRightButton.title == "Save" && self.cubes.count > 0) {
//            
//            // unhighlight every UIImageView because it cases the app to crash when deserializing
//            for (var i = 0; i < self.cubes.count; ++i) {
//                let view: UIImageView? = self.cubes.objectAtIndex(i) as? UIImageView
//                view?.highlighted = false
//            }
//            
//            let newStoryRef = EKClient.stories.childByAutoId()
//            let storyID = newStoryRef.name
//            let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(self.cubes)
//            self.storyContent!.data = data
//            self.storyContent!.story.title = self.titleTextField!.text
//            self.storyContent!.story.storyID = storyID
//            
//            var error: NSError?
//            if( !self.storyContent!.managedObjectContext!.save(&error)) {
//                println("could not save FrameSet: \(error?.localizedDescription)")
//            }
//            
//            let msg = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed)
//            
//            let post: Dictionary<String, String> = ["packet": msg, "hashtag": self.titleTextField!.text]
//            self.post = post
//            
//            //newStoryRef.setValue(["content": msg, "author": EKClient.authData!.uid, "hashtag": self.titleTextField!.text])
//            
//            //let userStories = EKClient.appRef.childByAppendingPath("user-stories").childByAppendingPath(EKClient.authData!.uid).childByAppendingPath(storyID)
//            //userStories.setValue(["hashtag": self.titleTextField!.text])
//            
//            self.storyInfo = (storyID, self.titleTextField!.text)
//            //self.shareBtn.enabled = true
//            //EKClient.userHomeURL!.updateChildValues(["stories:": storyID])
//            
//            //EKClient.sendData(post, toUserID: EKClient.authData!.uid)
//            
//            //EKClient.userPosts.setValue(post)
//            //self.fireRef.setValue(["name":"eyekon", "post":ref])
//            
//            //self.performSegueWithIdentifier("FromStoryToCircle", sender: self)
//            
//        } else {
//            // edit
//            self.editable = true
//            self.collectionView.userInteractionEnabled = true
//            self.upperRightButton.title = "Save"
//            
//            self.titleTextField!.userInteractionEnabled = true
//            
//            for (var i = 0; i < self.cubes.count; ++i) {
//                let view = self.cubes.objectAtIndex(i) as UIView
//                
//                
//                // this ensures that text cubes are draggable when touched
//                view.userInteractionEnabled = false
//            
//            }
//            self.showToolbar()
//        }
//    }

    @IBAction func addText(sender: AnyObject) {
        let frameWidth = self.collectionView.frame.size.width - self.sideInset * 2
        let textView = UITextView(frame: CGRectMake(0, 0, frameWidth, 35))
        textView.font = UIFont.systemFontOfSize(16)
        textView.delegate = self
        textView.returnKeyType = UIReturnKeyType.Done
        textView.inputAccessoryView = nil
        textView.userInteractionEnabled = true
        textView.layer.borderColor = UIColor(red: 0.64, green: 0.76, blue: 0.96, alpha: 1).CGColor
        textView.layer.borderWidth = 1.0
        
        if (self.selectedCell != nil) {
            // remove the border around the existing selection
            self.selectedCell!.layer.borderWidth = 0.0
        }

        self.cubes.insertObject(textView, atIndex: self.currentIndexPath.row)
        self.collectionView.insertItemsAtIndexPaths([self.currentIndexPath])
        
        self.deleteBtn.enabled = true
        self.selectedIndexPath = self.currentIndexPath
        self.currentIndexPath = NSIndexPath(forRow: self.currentIndexPath.row+1, inSection: self.currentIndexPath.section)
        textView.becomeFirstResponder()
    }
    
    @IBAction func addPhotoFromCamera(sender: AnyObject) {
        self.performSegueWithIdentifier("FromStoryToCapture", sender: self)
    }
    
    @IBAction func addPhotoFromLibrary(sender: AnyObject) {
        let picker: CTAssetsPickerController = CTAssetsPickerController()
        picker.delegate = self
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        self.imagePicker.dismissViewControllerAnimated(true, completion: nil)
        let compressedData = self.compressForUpload(image, maxFileSize: kImageKB)
        let newImage = UIImage(data: compressedData)!
        
        let cell: StoryTitleCollectionViewCell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) as StoryTitleCollectionViewCell
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
        cell.imageView.image = newImage
        
        // TODO add this to the front of the cubes
        // will this work if the cover image is optional upon save?
        //self.cubes.insertObject(newImage, atIndex: 0)
        
        self.cubes[0] = newImage
        
        //self.coverImage = newImage
        self.storyContent!.story.titleImage = UIImageJPEGRepresentation(image, 1.0)

        let data: NSData = self.compressForUpload(image, maxFileSize: 100*1024)
        self.storyInfo!.thumbnail = UIImage(data: data)!
    }
    
    
    // MARK: - AwesomeMenuDelegate
    /*func AwesomeMenu(menu: AwesomeMenu!, didSelectIndex idx: Int) {
        println("hey")
    }*/
    
    // MARK: - UIImagePickerControllerDelegate
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
            destination.setPost(self.post!)
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
    
    func moveView(userInfo: Dictionary<NSObject, AnyObject>, up: Bool) {
        var keyboardEndFrame: CGRect = CGRectZero
        (userInfo[UIKeyboardFrameEndUserInfoKey]! as NSValue).getValue(&keyboardEndFrame)
        
        if (up) {
            self.collectionView.frame = CGRectMake(self.collectionViewFrame.origin.x, self.collectionViewFrame.origin.y, self.collectionViewFrame.size.width, self.collectionViewFrame.size.height - keyboardEndFrame.size.height)
        } else {
            self.collectionView.frame = self.collectionViewFrame
        }
       
        //let keyboardFrame: CGRect = self.view.convertRect(keyboardEndFrame, toView: nil)
        //self.keyboardFrame = keyboardFrame
        //let inset = self.collectionView.contentInset
        //let height = up ? keyboardEndFrame.size.height: 0
        //let frame = self.collectionView.bounds
        //self.collectionView.contentInset = UIEdgeInsets(top: inset.top, left: inset.left, bottom: height, right: inset.right)
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if (textField.tag == 1) {
            self.storyContent?.story.summary = textField.text
        }
        
        textField.resignFirstResponder()
        return false
    }

    // MARK: UITextViewDelegate
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            textView.userInteractionEnabled = false
            textView.resignFirstResponder()
            //self.displayEditTools(self.currentIndexPath)
        } else {
            let frameWidth = textView.frame.size.width
            let cellHeight = textView.frame.size.height
            
            textView.sizeToFit()
            textView.frame.size.width = frameWidth
            
            if (textView.frame.size.height != cellHeight) {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
        }
        return true
    }
    
    func resized(indexPath: NSIndexPath) {
        //self.tableView.beginUpdates()
        //self.tableView.endUpdates()
    }
 
    // MARK: - LXReorderableCollectionViewFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 3.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 3.0
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, willMoveToIndexPath toIndexPath: NSIndexPath!) {
        
        let resource: AnyObject = self.cubes.objectAtIndex(fromIndexPath.item)
        self.cubes.removeObject(resource)
        self.cubes.insertObject(resource, atIndex: toIndexPath.item)
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // if title section
        if (indexPath.section == 0) {
            let cell: StoryTitleCollectionViewCell = self.collectionView.dequeueReusableCellWithReuseIdentifier("TitleCell", forIndexPath: indexPath) as StoryTitleCollectionViewCell
            
            cell.textField.text = self.storyInfo!.summary
            cell.textField.tag = 1
            cell.textField.delegate = self
            
            // TODO there should always be a cover image
            // the share option should be disabled until a cover image is chosen
            // the temp solution right now is to check if cover image is nil
            //if (self.coverImage != nil) {
                cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
                cell.imageView.image = (self.cubes[0] as UIImage)
            //}
            
            return cell
        } else {
            let cell: ResizeableCollectionCell = self.collectionView.dequeueReusableCellWithReuseIdentifier("StoryCell", forIndexPath: indexPath) as ResizeableCollectionCell
            
            let resource: AnyObject = self.cubes.objectAtIndex(indexPath.item+1)
//            view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleBottomMargin
            
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
        } else if (section == 1){
            return self.cubes.count-1
        } else {
            return 0
        }
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if (!self.editable || self.selectedIndexPath === indexPath) {
            return
        }
        
        if (self.selectedCell != nil) {
            // remove the border around the existing selection
            self.selectedCell!.layer.borderWidth = 0.0
        }
        
        let cell: UICollectionViewCell? = self.collectionView.cellForItemAtIndexPath(indexPath)
        let resource: AnyObject = self.cubes.objectAtIndex(indexPath.row)
        
        // add a blue border around the new selection
        if (resource is UIImage) {
            cell!.layer.borderColor = UIColor(red: 0.64, green: 0.76, blue: 0.96, alpha: 1).CGColor
            cell!.layer.borderWidth = 3.0
            //(view as MIView).enableResize()
        } else if (resource is UITextView) {
            cell!.layer.borderColor = UIColor(red: 0.64, green: 0.76, blue: 0.96, alpha: 1).CGColor
            cell!.layer.borderWidth = 1.0
        }
        
        self.selectedCell = cell
        self.deleteBtn.enabled = true
        self.currentIndexPath = indexPath
        self.selectedIndexPath = indexPath
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, doubleTapIndexPath indexPath: NSIndexPath!) {
        if (!self.editable) {
            return
        }
        
        self.selectedIndexPath = indexPath
        
        let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        if (view is UITextView) {
            let textView: UITextView = self.cubes.objectAtIndex(self.selectedIndexPath!.row) as UITextView
            
            textView.inputAccessoryView = nil
            textView.userInteractionEnabled = true
            textView.reloadInputViews()
            
            textView.becomeFirstResponder()
        }
    }
    
    func imageFrameSize(image: UIImage) -> CGSize {
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let viewWidth = self.collectionView.frame.size.width - self.sideInset * 2
        let viewHeight = imageHeight * viewWidth / imageWidth
        return CGSizeMake(viewWidth, viewHeight)
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if (indexPath.section == 1) {
            let resource: AnyObject = self.cubes.objectAtIndex(indexPath.item+1)
            
            if (resource is UIImage) {
                let image = resource as UIImage
                return self.imageFrameSize(image)
            } else {
                return CGSizeMake(self.collectionView.frame.size.width - self.sideInset*2, 50)
            }
        } else {
            let size = self.collectionView.frame.size
            return CGSizeMake(size.width, size.height/2)
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        
        if (section == 1) {
            return UIEdgeInsets(top: self.sideInset, left: self.sideInset, bottom: 0, right: self.sideInset)
        }
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
