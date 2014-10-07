//
//  PreviewViewController.swift
//  Spotter
//
//  Created by LV426 on 9/11/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class CubeTool: UIView {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clearColor()
        
        self.layer.borderWidth = 5.0
        //self.layer.cornerRadius = frame.width/2
        self.layer.borderColor = UIColor(red: 0.3, green: 0.6, blue: 0.7, alpha: 1.0).CGColor

        
//        let selectionAnimation: CABasicAnimation = CABasicAnimation(keyPath: "borderColor")
//        selectionAnimation.toValue = UIColor.yellowColor().CGColor
//        selectionAnimation.repeatCount = 8
//        self.layer.addAnimation(selectionAnimation, forKey: "selectionAnimation")
    }
}

let kStoryHashtag = "#untitled"

class StoryViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, HPGrowingTextViewDelegate, LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout {

    //@IBOutlet var upperLeftButton: UIBarButtonItem!
    @IBOutlet var upperRightButton: UIBarButtonItem!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var toolbar: UIToolbar!
    
    var dataFrames: [Frame]?
    var cubes: NSMutableArray = NSMutableArray()
    var editable: Bool = false
    var cubeTool: CubeTool = CubeTool(frame: CGRectZero)
    
    var storyContent: StoryContent?
    var context: NSManagedObjectContext?
    
    var titleTextField: UITextField?
    var keyboardToolBar: UIToolbar?
    var keyboardToolBarTextView: HPGrowingTextView?
    
    var textView: UITextView?
    //var selectedIndex: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    var selectedIndex: NSIndexPath?
    var editingText = false
    
    let calloutView: SMCalloutView = SMCalloutView.platformCalloutView()
    let editBtn: UIButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
    let deleteBtn: UIButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.clipsToBounds = false
        self.collectionView.delegate = self
        
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        
        self.titleTextField = UITextField(frame: CGRectMake(0, 0, 200, 22))
        self.titleTextField!.returnKeyType = UIReturnKeyType.Done
        self.titleTextField!.delegate = self
        self.titleTextField!.text = kStoryHashtag
        self.titleTextField!.font = UIFont.boldSystemFontOfSize(19)
        self.titleTextField!.textColor = UIColor.whiteColor()
        //self.titleTextField!.textAlignment = NSTextAlignment.Center
        self.navigationItem.titleView = self.titleTextField!
        
        let toolbarRect = CGRectMake(0, 0, self.view.frame.width, 44)

        
        // setup a textview on the keyboardToolBar
        self.keyboardToolBar = UIToolbar(frame: toolbarRect)
        self.keyboardToolBarTextView = HPGrowingTextView(frame: toolbarRect)
        self.keyboardToolBarTextView!.returnKeyType = UIReturnKeyType.Done
        self.keyboardToolBarTextView!.font = UIFont.systemFontOfSize(16)
        self.keyboardToolBarTextView!.maxNumberOfLines = 7
        self.keyboardToolBarTextView!.contentInset = UIEdgeInsetsMake(0, 5, 0, 5)
        self.keyboardToolBarTextView!.delegate = self
        self.keyboardToolBar!.addSubview(self.keyboardToolBarTextView!)
        
        // setup offscreen text view
        self.textView = UITextView(frame: CGRectMake(0, self.collectionView.frame.size.height, self.collectionView.frame.size.width, 50))
        
        self.textView!.returnKeyType = UIReturnKeyType.Done
        self.textView!.inputAccessoryView = self.keyboardToolBar
        self.textView!.userInteractionEnabled = false
        self.textView!.font = UIFont.systemFontOfSize(16)
        self.textView!.inputAccessoryView = self.keyboardToolBar
        self.view.addSubview(self.textView!)
        
        
        //self.calloutView.frame = CGRectMake(0, 0, 100, 200)
        //self.calloutView.title = "Tools Here!"
        //let trashButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
        self.deleteBtn.setImage(UIImage(named: "trash.png"), forState: UIControlState.Normal)
        self.deleteBtn.addTarget(self, action: "deleteSelected", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.editBtn.setImage(UIImage(named: "pencil.png"), forState: UIControlState.Normal)
        self.editBtn.addTarget(self, action: "editSelected", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.calloutView.leftAccessoryView = self.editBtn
        self.calloutView.rightAccessoryView = self.deleteBtn
        
        //self.calloutView.view.backgroundColor = UIColor(red: 0.2, green:0.6, blue: 0.4, alpha: 0.95)
        
        //self.view.addSubview(self.cubeTool)
        //self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 3, bottom: 3, right: 3)
        
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
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        if(self.storyContent == nil) {
            // create a new story
            self.cubes.removeAllObjects()
            self.editable = true
            self.collectionView.userInteractionEnabled = true
            
            let story: Story = NSEntityDescription.insertNewObjectForEntityForName("Story", inManagedObjectContext: self.context!) as Story
            story.title = kStoryHashtag
            story.summary = "Summary"
            
            let content = NSEntityDescription.insertNewObjectForEntityForName("StoryContent", inManagedObjectContext: self.context!) as StoryContent
            
            story.content = content
            content.story = story
            
            self.storyContent = content

        } else {
            //self.toolbar.hidden = true
            //let frame = self.toolbar.frame
            self.toolbar.frame.origin.y = self.view.frame.size.height
        }
        
        self.titleTextField!.userInteractionEnabled = self.editable
        if (self.editable) {
            self.showToolbar()
        }
       
        self.titleTextField!.text = self.storyContent!.story.title
        self.cubeTool.hidden = true
        self.collectionView.reloadData()
       
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addImageView(image: UIImage) {
        if (self.selectedIndex == nil) {
            self.selectedIndex = NSIndexPath(forRow: 0, inSection: 0)
        }
        
        if (self.cubes.count > 0){
            let view: UIImageView? = self.cubes.objectAtIndex(self.selectedIndex!.row) as? UIImageView
            view?.highlighted = false
        }
        
        let frameWidth = self.collectionView.frame.width
        
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let height = frameWidth * originalHeight / originalWidth
        
        let imageView = UIImageView(frame: CGRectMake(0, 0, frameWidth, height))
        imageView.image = image
        
        self.cubes.insertObject(imageView, atIndex: self.selectedIndex!.row)
        self.collectionView.insertItemsAtIndexPaths([self.selectedIndex!])
        self.displayEditTools(self.selectedIndex!)
    }
    
    func deleteSelected() {
        let index = self.selectedIndex!.row
        self.calloutView.dismissCalloutAnimated(true)
        self.cubes.removeObjectAtIndex(index)
        self.collectionView.deleteItemsAtIndexPaths([self.selectedIndex!])
    }
    
    func editSelected() {
        
        self.editingText = true
        let index = self.selectedIndex!.row
        self.calloutView.dismissCalloutAnimated(false)
        let textView: UITextView = self.cubes.objectAtIndex(index) as UITextView
        
        //self.keyboardToolBar!.frame = CGRectMake(0, 0, self.view.frame.width, 35)
        //self.keyboardToolBarTextView!.frame = CGRectMake(0, 0, self.view.frame.width, 35)
        //self.keyboardToolBarTextView!.text = textView.text
        //self.textView!.text = ""
        
        //self.textView!.becomeFirstResponder()
        //self.keyboardToolBarTextView!.becomeFirstResponder()
        //self.keyboardToolBarTextView!.text = textView.text
        
        textView.becomeFirstResponder()

        
//        let diff: CGFloat = CGFloat(height) - growingTextView.frame.size.height
//        
//        var r: CGRect = self.keyboardToolBar!.frame
//        r.size.height = self.keyboardToolBarTextVi
//        r.origin.y -= diff
//        self.keyboardToolBar!.frame = r
        
    }
    
    func setStoryContent(content: StoryContent) {
        
        self.storyContent = content
        
        if( content.data != nil) {
            self.cubes = NSKeyedUnarchiver.unarchiveObjectWithData(content.data!) as NSMutableArray
        }
    }
    
    func showToolbar() {
        UIView.animateWithDuration(0.25,
            animations: {
                self.toolbar.frame.origin.y = self.view.frame.size.height - self.toolbar.frame.size.height
                
            }, completion: { (value: Bool) in
        })
    }
    
    // MARK: - Actions
    
    @IBAction func returnToPrevious(sender: AnyObject) {
        // pop myself off the stack of view controllers and show the previous 
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func publish(sender: AnyObject) {
        
        let index = self.selectedIndex?.row ?? 0
        
        if (self.upperRightButton.title == "Save" && self.cubes.count > 0) {
            let view: UIImageView? = self.cubes.objectAtIndex(index) as? UIImageView
            view?.highlighted = false
            
            //self.performSegueWithIdentifier("FromPreviewToPublish", sender: self)
            let data: NSData = NSKeyedArchiver.archivedDataWithRootObject(self.cubes)
            self.storyContent!.data = data
            self.storyContent!.story.title = self.titleTextField!.text
            self.storyContent!.story.summary = "Empty"
            
            var error: NSError?
            if( !self.storyContent!.managedObjectContext.save(&error)) {
                println("could not save FrameSet: \(error?.localizedDescription)")
            }
        } else {
            // edit
            //self.performSegueWithIdentifier("FromPreviewToCapture", sender: self)
            self.editable = true
            self.collectionView.userInteractionEnabled = true
            self.upperRightButton.title = "Save"
            
            self.titleTextField!.userInteractionEnabled = true
            
            for (var i = 0; i < self.cubes.count; ++i) {
                let view: UIView = self.cubes.objectAtIndex(i) as UIView
                view.userInteractionEnabled = false
            }
            
            self.showToolbar()
        }
    }

    @IBAction func addText(sender: AnyObject) {
        
        self.editingText = false
        self.keyboardToolBar!.frame = CGRectMake(0, 0, self.view.frame.width, 35)
        self.keyboardToolBarTextView!.frame = CGRectMake(0, 0, self.view.frame.width, 35)
        self.keyboardToolBarTextView!.text = ""
        self.textView!.text = ""
        
        self.textView!.becomeFirstResponder()
        //self.textView!.frame.size.height = 50
        self.keyboardToolBarTextView!.text = ""
        self.keyboardToolBarTextView!.becomeFirstResponder()
        self.calloutView.dismissCalloutAnimated(false)
    }
    
    @IBAction func addPhotoFromCamera(sender: AnyObject) {
        self.performSegueWithIdentifier("FromStoryToCapture", sender: self)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if (segue.identifier == "FromStoryToCapture") {
            let destination: CaptureViewController = segue.destinationViewController as CaptureViewController
            destination.storyController = self
        }
    }
    
    @IBAction func unwindToPreview(unwindSegue: UIStoryboardSegue) {
    }
    
    // MARK: - Notifications
    func keyboardWillShow(notification: NSNotification) {
        //let text = SharedDataFrame.dataFrame!.annotation
        let text = self.textView!.text
        
        self.keyboardToolBarTextView?.text = text
        self.keyboardToolBarTextView?.becomeFirstResponder()
    }
    
//    func keyboardWillHide(notification: NSNotification) {
//        //let imageFrame = self.imageView.frame
//        //SharedDataFrame.dataFrame?.annotation = self.keyboardToolBarTextView!.text
//        
////        if (self.textView.hidden && self.keyboardToolBarTextView!.text != "") {
////            self.textView.hidden = false
////        } else if (self.keyboardToolBarTextView!.text == "") {
////            self.textView.hidden = true
////        }
//        
//        self.textView!.text = self.keyboardToolBarTextView!.text
//        self.textView!.sizeToFit()
//        let frameWidth = self.collectionView.frame.size.width
//        let textCube = UITextView(frame: CGRectMake(0, 0, frameWidth, self.textView!.frame.size.height))
//        textCube.font = UIFont.systemFontOfSize(16)
//        textCube.text = self.keyboardToolBarTextView!.text
//        textCube.userInteractionEnabled = false
//        
//       
//        self.cubes.insertObject(textCube, atIndex: self.selectedIndex.row)
//        self.collectionView.insertItemsAtIndexPaths([self.selectedIndex])
//        
//        //self.collectionView.reloadItemsAtIndexPaths([index])
//        
////        self.textView!.text = self.keyboardToolBarTextView!.text
////        self.textView!.sizeToFit()
////        self.textView!.frame.size.width = self.collectionView.frame.size.width
//        
//        //self.cubes.addObject(self.textView!)
//        
////        let index: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
////        self.collectionView.reloadItemsAtIndexPaths([index])
//        
//        //self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.width, self.imageView.frame.height+self.textView.frame.height)
//    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        self.calloutView.dismissCalloutAnimated(false)
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    // MARK: UITextViewDelegate
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if(text == "\n") {
            textView.resignFirstResponder()
            self.displayEditTools(self.selectedIndex!)
        } else {
            let frameWidth = self.collectionView.frame.size.width
            let cellHeight = textView.frame.size.height
            
            textView.sizeToFit()
            textView.frame.size.width = frameWidth
            
            if (textView.frame.size.height != cellHeight) {
                self.collectionView.collectionViewLayout.invalidateLayout()
                //self.collectionView.reloadItemsAtIndexPaths([self.selectedIndex!])
                //textView.becomeFirstResponder()
            }

        }
        return true
    }
    
    
    // MARK: HPGrowingTextViewDelegate
    func growingTextView(growingTextView: HPGrowingTextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
        
        // triggered when done button is touched
        if(text == "\n") {
            let index = self.selectedIndex?.row ?? 0
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            
            if (self.cubes.count > 0){
                let view: UIImageView? = self.cubes.objectAtIndex(index) as? UIImageView
                view?.highlighted = false
            }
    
            self.keyboardToolBarTextView!.resignFirstResponder()
            self.textView!.resignFirstResponder()
            
            self.textView!.text = self.keyboardToolBarTextView!.text
            self.textView!.sizeToFit()
            let frameWidth = self.collectionView.frame.size.width
            
            self.selectedIndex = indexPath
            
            // if not editing existing text
            if (!self.editingText) {
                // create a new text view
                let textCube = UITextView(frame: CGRectMake(0, 0, frameWidth, self.textView!.frame.size.height))
                textCube.font = UIFont.systemFontOfSize(16)
                textCube.text = self.keyboardToolBarTextView!.text
                textCube.sizeToFit()
                textCube.frame.size.width = frameWidth
                textCube.userInteractionEnabled = false
                textCube.delegate = self
                textCube.returnKeyType = UIReturnKeyType.Done
                
                self.cubes.insertObject(textCube, atIndex: index)
                self.calloutView.dismissCalloutAnimated(false)
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            } else {
                let textCube = self.cubes.objectAtIndex(index) as UITextView
                textCube.text = self.keyboardToolBarTextView!.text
                textCube.sizeToFit()
                self.collectionView.reloadItemsAtIndexPaths([self.selectedIndex!])
            }
            self.displayEditTools(self.selectedIndex!)
        }
        
        return true
    }
    
    func growingTextView(growingTextView: HPGrowingTextView!, willChangeHeight height: Float) {
        let diff: CGFloat = CGFloat(height) - growingTextView.frame.size.height
        
        var r: CGRect = self.keyboardToolBar!.frame
        r.size.height += diff
        r.origin.y -= diff
        self.keyboardToolBar!.frame = r
        
    }
    
    // MARK: - LXReorderableCollectionViewDelegateFlowLayout

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, didEndDraggingItemAtIndexPath indexPath: NSIndexPath!) {
        
        if (self.selectedIndex != nil) {
            self.collectionView.selectItemAtIndexPath(self.selectedIndex!, animated: true, scrollPosition: UICollectionViewScrollPosition.None)
            self.displayEditTools(self.selectedIndex!)
        }
    }
    
    // MARK: - LXReorderableCollectionViewDataSource
    func collectionView(collectionView: UICollectionView!, canMoveItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return self.editable
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell: UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("EmptyCell", forIndexPath: indexPath) as UICollectionViewCell
        
        let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        
        if (view is UITextView) {
            let textView = view as UITextView
            textView.delegate = self
        }
        
        //let frame = self.dataFrames![indexPath.row]
        //let image = UIImage(data: frame.imageData)
        //let imageView = UIImageView(image: image)

        cell.addSubview(view)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, didMoveToIndexPath toIndexPath: NSIndexPath!) {
        
        self.selectedIndex = toIndexPath
        //self.displayEditTools(toIndexPath)
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, willMoveToIndexPath toIndexPath: NSIndexPath!) {
        let view: UIView = self.cubes.objectAtIndex(fromIndexPath.row) as UIView
        self.cubes.removeObject(view)
        self.cubes.insertObject(view, atIndex: toIndexPath.row)
        self.calloutView.dismissCalloutAnimated(true)
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cubes.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func displayEditTools(indexPath: NSIndexPath) {
        let attributes = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath)
        
        let btn: UIButton = self.calloutView.leftAccessoryView as UIButton
        let view: UIView = self.cubes[indexPath.row] as UIView
        
        if (view is UIImageView) {
            btn.enabled = false
        } else {
            btn.enabled = true
        }
        
        var direction = self.calloutView.currentArrowDirection
        if (self.collectionView.contentOffset.y < 0 && attributes!.frame.origin.y == 0) {
            self.calloutView.permittedArrowDirection = SMCalloutArrowDirection.Up
        } else if (self.collectionView.contentOffset.y > (attributes!.frame.origin.y - self.calloutView.frame.size.height)) {
            self.calloutView.permittedArrowDirection = SMCalloutArrowDirection.Up
        } else {
            self.calloutView.permittedArrowDirection = SMCalloutArrowDirection.Down
        }
        
        //self.calloutView.presentCalloutFromRect(attributes!.frame, inLayer: self.collectionView.layer, constrainedToLayer: self.view.layer, animated: true)
        self.calloutView.presentCalloutFromRect(attributes!.frame, inView: self.collectionView, constrainedToView: self.view, animated: true)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if(self.selectedIndex == nil) {
            return
        }
        
        displayEditTools(self.selectedIndex!)
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        //println("hey")

        if(self.selectedIndex == nil) {
            return
        }
        
        displayEditTools(self.selectedIndex!)

    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        let size = view.frame.size
    
        return size
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if (!self.editable) {
            return
        }
        
        // remove highlighted flag because it causes
        // -[NSKeyedUnarchiver decodeBoolForKey:]: value for key (UIHighlighted) is not a boolean
        let imageView: UIImageView? = self.cubes[indexPath.row] as? UIImageView
        imageView?.highlighted = false
        
        //let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        //view.layer.borderWidth = 3.0
        //view.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.90).CGColor
        //view.layer.borderColor = UIColor(red: 0.2, green:0.6, blue: 0.4, alpha: 0.95).CGColor

        self.selectedIndex = indexPath
        self.displayEditTools(indexPath)
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        //let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        //view.layer.borderWidth = 0.0
    
        //self.calloutView.dismissCalloutAnimated(true)
        
        //self.selectedIndex = nil
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, didBeginDraggingItemAtIndexPath indexPath: NSIndexPath) {
//        
//        self.selectedView = self.cubes.objectAtIndex(indexPath.row) as? UIView
//        self.cubes.removeObject(self.selectedView!)
//    }
//    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, didEndDraggingItemAtIndexPath indexPath: NSIndexPath) {
//        
//        //self.selectedView = nil
//        self.isDraggingView = false
//    }
}
