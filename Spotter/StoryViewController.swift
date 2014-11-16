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


class StoryViewController: UIViewController, UITableViewDataSource, MITableViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, CTAssetsPickerControllerDelegate, AwesomeMenuDelegate, SPUserResizableViewDelegate, MIDelegate {

    @IBOutlet var upperRightButton: UIBarButtonItem!
    //@IBOutlet var collectionView: UICollectionView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var deleteBtn: UIBarButtonItem!
    
    var cellSpacing: CGFloat = 3.0

    // ordered collection of UIViews
    var cubes: NSMutableArray = NSMutableArray()
    // flag used to determine if parent view is editable
    var editable: Bool = false
        
    var storyContent: StoryContent?
    var context: NSManagedObjectContext?

    var titleTextField: UITextField?
    
    // index of selected cube/UIView
    var currentIndexPath: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    var selectedIndexPath: NSIndexPath?
    
    // main tool to add new content
    var mainTool: AwesomeMenu?
    var mainToolPosition: CGPoint = CGPointMake(0, 0)
    
    var post: Dictionary<String, String>?
    var keyboardFrame: CGRect = CGRectZero
    
    func awesomeMenu(menu: AwesomeMenu!, didSelectIndex idx: Int) {
        
        if (idx == 0) {
            self.addText(self)
        } else if (idx == 1) {
            self.addPhotoFromLibrary(self)
        } else if (idx == 2) {
            self.addPhotoFromCamera(self)
        }
    }
    
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
        self.navigationItem.titleView = self.titleTextField!
        
        let addImage = UIImage(named: "add.png")
        let txtImage = UIImage(named: "txtTool.png")
        let libImage = UIImage(named: "libTool.png")
        let camImage = UIImage(named: "camTool.png")
        
        let txtBtn = AwesomeMenuItem(image: txtImage, highlightedImage: txtImage, contentImage: txtImage, highlightedContentImage: nil)
        let camBtn = AwesomeMenuItem(image: camImage, highlightedImage: camImage, contentImage: camImage, highlightedContentImage: nil)
        let libBtn = AwesomeMenuItem(image: libImage, highlightedImage: libImage, contentImage: libImage, highlightedContentImage: nil)
        let addBtn = AwesomeMenuItem(image: addImage, highlightedImage: addImage, contentImage: addImage, highlightedContentImage: addImage)
        
        self.mainTool = AwesomeMenu(frame: self.view.frame, startItem: addBtn, optionMenus: [txtBtn, libBtn, camBtn])
        self.mainTool!.delegate = self
        self.mainTool!.startPoint = CGPointMake(self.view.frame.size.width/2,
                                                self.view.frame.size.height - addImage!.size.height/2)
        
        self.mainTool!.menuWholeAngle = CGFloat(-M_PI/3)
        self.view.addSubview(self.mainTool!)
        (self.tableView as MITableView).miDelegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        if(self.storyContent == nil) {
            // create a new story
            self.cubes.removeAllObjects()
            self.editable = true
            self.tableView.userInteractionEnabled = true
            
            let story: Story = NSEntityDescription.insertNewObjectForEntityForName("Story", inManagedObjectContext: self.context!) as Story
            story.title = kStoryHashtag
            story.summary = "Summary"
            
            let content = NSEntityDescription.insertNewObjectForEntityForName("StoryContent", inManagedObjectContext: self.context!) as StoryContent
            
            story.content = content
            content.story = story
            
            self.storyContent = content
            self.showToolbar()
            //self.masterTool.center = self.view.center

        } else {
            // hide toolbar
            //self.toolbar.frame.origin.y = self.view.frame.size.height
            //self.mainTool!.userInteractionEnabled = false

            //self.mainTool!.startPoint = CGPointMake(self.view.frame.size.width,
            //    self.view.frame.size.height)
        }
        
        self.deleteBtn.enabled = false
        
        self.toolbar.frame.origin.y = self.view.frame.size.height

        //self.mainTool!.startPoint = CGPointMake(self.view.frame.size.width/2, 300)
        
        // defaults as the end of the data source
        self.currentIndexPath = NSIndexPath(forRow: self.cubes.count, inSection: 0)
        
        self.titleTextField!.userInteractionEnabled = self.editable
        if (self.editable) {
            self.showToolbar()
        } else {
            self.mainTool!.userInteractionEnabled = false
            self.mainTool!.alpha = 0.0
        }
       
        self.titleTextField!.text = self.storyContent!.story.title
        self.tableView.reloadData()
        
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
        let frameWidth = self.tableView.frame.width
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
    
    func addImages(images: [UIImage]) {
        var imageGroups: [[UIImage]] = [[UIImage]]()
        var imageGroup: [UIImage] = [UIImage]()
        var miView: MIView = MIView(frame: CGRectMake(0, 0, self.tableView.frame.width, 10))
        miView.cellSpacing = self.cellSpacing
        
        for (var i = 0; i < images.count; ++i) {
            let imageView = UIImageView(image: images[i])
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            imageView.clipsToBounds = true
            
            miView.addImageView(imageView)
            if(miView.subviewCount() == 3) {
                self.cubes.addObject(miView)
                miView = MIView(frame: CGRectMake(0, 0, self.tableView.frame.width, 10))
                miView.cellSpacing = self.cellSpacing

                self.tableView.insertRowsAtIndexPaths([self.currentIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                self.currentIndexPath = NSIndexPath(forRow: self.currentIndexPath.row+1, inSection: self.currentIndexPath.section)

            
            } else if (i == images.count - 1) {
                self.cubes.addObject(miView)
                
                self.tableView.insertRowsAtIndexPaths([self.currentIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                self.currentIndexPath = NSIndexPath(forRow: self.currentIndexPath.row+1, inSection: self.currentIndexPath.section)
            }
        }
    }
    
    // edit selected text
    func doubleTab(indexPath: NSIndexPath) {
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
    
    func setStoryContent(content: StoryContent) {
        self.storyContent = content
        
        if( content.data != nil) {
            // unarchive the story content as a ordered array of UIViews
            self.cubes = NSKeyedUnarchiver.unarchiveObjectWithData(content.data!) as NSMutableArray
        }
    }
    
    func showToolbar() {
        UIView.animateWithDuration(0.25,
            animations: {
                self.mainTool!.alpha = 1.0
                //self.mainTool!.startPoint = self.mainToolPosition

                self.toolbar.frame.origin.y = self.view.frame.size.height - self.toolbar.frame.size.height
                
            }, completion: { (value: Bool) in
                self.mainTool!.userInteractionEnabled = true
                let tableSize = self.tableView.frame.size
                let tableOrigin = self.tableView.frame.origin
                let toolbarSize = self.toolbar.frame.size
                let viewSize = self.view.frame.size
                self.tableView.frame = CGRectMake(tableOrigin.x, tableOrigin.y, tableSize.width, viewSize.height - toolbarSize.height)
        })
    }
    
    // MARK: - Actions
    
    @IBAction func deleteSelected(sender: AnyObject) {
        if (self.selectedIndexPath == nil) {
            return
        }
        let view: UIView = self.cubes.objectAtIndex(self.selectedIndexPath!.row) as UIView
        view.removeFromSuperview()
        
        self.cubes.removeObjectAtIndex(self.selectedIndexPath!.row)
        self.tableView.deleteRowsAtIndexPaths([self.selectedIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        
        // move current index path to previous index item
        if (self.currentIndexPath.row > 0) {
            self.currentIndexPath.row.advancedBy(-1)
        }
        
        self.selectedIndexPath = nil
        self.deleteBtn.enabled = false
        self.tableView.reloadData()
    }
    
    @IBAction func returnToPrevious(sender: AnyObject) {
        // pop myself off the stack of view controllers and show the previous 
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func publish(sender: AnyObject) {
        
        //let index = self.selectedIndex?.row ?? 0
        
        if (self.upperRightButton.title == "Save" && self.cubes.count > 0) {
            
            // unhighlight every UIImageView because it cases the app to crash when deserializing
            for (var i = 0; i < self.cubes.count; ++i) {
                let view: UIImageView? = self.cubes.objectAtIndex(i) as? UIImageView
                view?.highlighted = false
            }
            
            let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(self.cubes)
            self.storyContent!.data = data
            self.storyContent!.story.title = self.titleTextField!.text
            self.storyContent!.story.summary = "Empty"
            
            var error: NSError?
            if( !self.storyContent!.managedObjectContext!.save(&error)) {
                println("could not save FrameSet: \(error?.localizedDescription)")
            }
            
            let msg = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed)
            
            let post: Dictionary<String, String> = ["packet": msg, "hashtag": self.titleTextField!.text]
            self.post = post
            //EKClient.sendData(post, toUserID: EKClient.authData!.uid)
            
            //EKClient.userPosts.setValue(post)
            //self.fireRef.setValue(["name":"eyekon", "post":ref])
            
            self.performSegueWithIdentifier("FromStoryToCircle", sender: self)
            
        } else {
            // edit
            self.editable = true
            self.tableView.userInteractionEnabled = true
            self.upperRightButton.title = "Save"
            
            self.titleTextField!.userInteractionEnabled = true
            
            for (var i = 0; i < self.cubes.count; ++i) {
                let view = self.cubes.objectAtIndex(i) as UIView
                
                if (view is MIView) {
                    (view as MIView).enableResize()
                } else {
                    // this ensures that text cubes are draggable when touched
                    view.userInteractionEnabled = false
                }
            }
            self.showToolbar()
        }
    }

    @IBAction func addText(sender: AnyObject) {
//        self.editingText = false
//        self.keyboardToolBar!.frame = CGRectMake(0, 0, self.view.frame.width, 35)
//        self.keyboardToolBarTextView!.frame = CGRectMake(0, 0, self.view.frame.width, 35)
//        self.keyboardToolBarTextView!.text = ""
//        self.textView!.text = ""
//        
//        self.textView!.becomeFirstResponder()
//        self.keyboardToolBarTextView!.text = ""
//        self.keyboardToolBarTextView!.becomeFirstResponder()
        
        let frameWidth = self.tableView.frame.size.width
        let textView = UITextView(frame: CGRectMake(0, 0, frameWidth, 50))
        textView.font = UIFont.systemFontOfSize(16)
        textView.delegate = self
        textView.returnKeyType = UIReturnKeyType.Done
        textView.inputAccessoryView = nil
        textView.userInteractionEnabled = true
        textView.becomeFirstResponder()
        
        self.cubes.insertObject(textView, atIndex: self.currentIndexPath.row)
        self.tableView.insertRowsAtIndexPaths([self.currentIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        self.currentIndexPath = NSIndexPath(forRow: self.currentIndexPath.row+1, inSection: self.currentIndexPath.section)
    }
    
    @IBAction func addPhotoFromCamera(sender: AnyObject) {
        self.performSegueWithIdentifier("FromStoryToCapture", sender: self)
    }
    
    @IBAction func addPhotoFromLibrary(sender: AnyObject) {
        let picker: CTAssetsPickerController = CTAssetsPickerController()
        picker.delegate = self
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    // MARK: - AwesomeMenuDelegate
    /*func AwesomeMenu(menu: AwesomeMenu!, didSelectIndex idx: Int) {
        println("hey")
    }*/
    
    // MARK: - UIImagePickerControllerDelegate
    func assetsPickerController(picker: CTAssetsPickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        
        let images: [UIImage] = assets.map({ (var asset) -> UIImage in
            let a = asset as ALAsset
            
            return UIImage(CGImage: a.defaultRepresentation().fullResolutionImage().takeUnretainedValue())!
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
            let destination: CircleViewController = segue.destinationViewController as CircleViewController
            destination.setPost(self.post!)
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
        
        let keyboardFrame: CGRect = self.view.convertRect(keyboardEndFrame, toView: nil)
        self.keyboardFrame = keyboardFrame
        
        let y = keyboardFrame.size.height * (up ? -1: 1)
        
        UIView.animateWithDuration(0.3, animations: {
            self.tableView.frame = CGRectOffset(self.tableView.frame, 0, y)
        })
        
//    UIViewAnimationCurve animationCurve;
//    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]
//    getValue:&animationCurve];
//    
//    NSTimeInterval animationDuration;
//    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey]
//    getValue:&animationDuration];
//    
//    // Get the correct keyboard size to we slide the right amount.
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationBeginsFromCurrentState:YES];
//    [UIView setAnimationDuration:animationDuration];
//    [UIView setAnimationCurve:animationCurve];
//    
//    CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
//    int y = keyboardFrame.size.height * (up ? -1 : 1);
//    self.view.frame = CGRectOffset(self.view.frame, 0, y);
//    
//    [UIView commitAnimations];
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        //self.calloutView.dismissCalloutAnimated(false)
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    // MARK: UITextViewDelegate
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            //textView.userInteractionEnabled = false
            textView.resignFirstResponder()
            //self.displayEditTools(self.currentIndexPath)
        } else {
            let frameWidth = self.tableView.frame.size.width
            let cellHeight = textView.frame.size.height
            
            textView.sizeToFit()
            textView.frame.size.width = frameWidth
            
            //let rect = self.tableView.rectForRowAtIndexPath(self.selectedIndexPath!)
            //let tableViewFrame = self.view.convertRect(self.tableView.frame, toView: nil)
            //let textViewBottom = tableViewFrame.origin.y + tableViewFrame.size.height
//            let textViewFrame = self.view.convertRect(rect, toView: nil)
//            let bottomEdge = textViewFrame.origin.y + textViewFrame.size.height
//            println("textview: \(bottomEdge) \(self.keyboardFrame.origin.y)")
//            
//            if (bottomEdge > self.keyboardFrame.origin.y) {
//                self.tableView.frame = CGRectOffset(self.tableView.frame, 0, -keyboardFrame.size.height)
//            }
        }
        return true
    }
    
    func resized(indexPath: NSIndexPath) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
 
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("TableCell") as UITableViewCell
        let cube: AnyObject = self.cubes.objectAtIndex(indexPath.row)
        var height: CGFloat = 0
        let view = self.cubes.objectAtIndex(indexPath.row) as UIView
        
        if (view is MIView) {
            let mi = view as MIView
            mi.delegate = self
            mi.indexPath = indexPath
            
            if (self.editable) {
                mi.enableResize()
            }
        } else if (view is UITextView) {
            (view as UITextView).delegate = self
        }
        
        cell.contentView.addSubview(view)
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cubes.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let view = self.cubes.objectAtIndex(indexPath.row) as UIView
        return view.frame.size.height + self.cellSpacing
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if (!self.editable || self.selectedIndexPath === indexPath) {
            return
        }
        
        if (self.selectedIndexPath != nil) {
            // remove the border around the existing selection
            let previousView = self.cubes.objectAtIndex(self.selectedIndexPath!.row) as UIView
            previousView.layer.borderWidth = 0.0
        }
        
        // add a blue border around the new selection
        let view = self.cubes.objectAtIndex(indexPath.row) as UIView
        
        if (view is MIView) {
            view.layer.borderColor = UIColor(red: 0.64, green: 0.76, blue: 0.96, alpha: 1).CGColor
            view.layer.borderWidth = 3.0
        } else if (view is UITextView) {
            view.layer.borderColor = UIColor(red: 0.64, green: 0.76, blue: 0.96, alpha: 1).CGColor
            view.layer.borderWidth = 1.0
        }
        
        self.deleteBtn.enabled = true
        self.currentIndexPath = indexPath
        self.selectedIndexPath = indexPath
    }
}
