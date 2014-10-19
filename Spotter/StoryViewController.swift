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

class StoryViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, HPGrowingTextViewDelegate, LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout, UINavigationControllerDelegate, CTAssetsPickerControllerDelegate {

    @IBOutlet var upperRightButton: UIBarButtonItem!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var toolbar: UIToolbar!

    let cellSpacing: CGFloat = 5.0

    // ordered collection of UIViews
    var cubes: NSMutableArray = NSMutableArray()
    var cubeControls: NSMutableArray = NSMutableArray()
    
    // flag used to determine if parent view is editable
    var editable: Bool = false
    
    //var cubeTool: CubeTool = CubeTool(frame: CGRectZero)
    
    var storyContent: StoryContent?
    var context: NSManagedObjectContext?

    var titleTextField: UITextField?
    
    // dummy text view used during text cube insertion
    var textView: UITextView?
    var keyboardToolBar: UIToolbar?
    var keyboardToolBarTextView: HPGrowingTextView?
    
    // editing existing text cube
    var editingText = false
    // index of selected cube/UIView
    var selectedIndex: NSIndexPath?

    // callout used for editing tools
    let calloutView: SMCalloutView = SMCalloutView.platformCalloutView()
    let editBtn: UIButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
    let deleteBtn: UIButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
    
    var resizeIndices: [Int] = [Int]()
    var i1 = 0
    var i2 = 0
    
//    func handleTap(gesture: UITapGestureRecognizer) {
//        let touchPoint: CGPoint = gesture.locationInView(self.collectionView.backgroundView!)
//        println("tap: \(touchPoint.x) \(touchPoint.y)")
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.clipsToBounds = false
        self.collectionView.delegate = self
        //self.collectionView.backgroundView = UIView()
        //self.collectionView.backgroundView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "handleTap:"))
        
        
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
        
        // toolbar for text view accessory view
        let toolbarRect = CGRectMake(0, 0, self.view.frame.width, 40)
        
        // setup a textview on the keyboardToolBar
        self.keyboardToolBar = UIToolbar(frame: toolbarRect)
        self.keyboardToolBarTextView = HPGrowingTextView(frame: toolbarRect)
        self.keyboardToolBarTextView!.returnKeyType = UIReturnKeyType.Done
        self.keyboardToolBarTextView!.font = UIFont.systemFontOfSize(16)
        self.keyboardToolBarTextView!.maxNumberOfLines = 7
        //self.keyboardToolBarTextView!.contentInset = UIEdgeInsetsMake(0, 5, 0, 5)
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
        
        // delete button for callout view
        self.deleteBtn.setImage(UIImage(named: "trash.png"), forState: UIControlState.Normal)
        self.deleteBtn.addTarget(self, action: "deleteSelected", forControlEvents: UIControlEvents.TouchUpInside)
        
        // edit button for callout view
        self.editBtn.setImage(UIImage(named: "pencil.png"), forState: UIControlState.Normal)
        self.editBtn.addTarget(self, action: "editSelected", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.calloutView.leftAccessoryView = self.editBtn
        self.calloutView.rightAccessoryView = self.deleteBtn
    }
    
    override func viewWillAppear(animated: Bool) {
        
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
        //self.cubeTool.hidden = true
        self.collectionView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
        
        let height: CGFloat = CGFloat(floorf(Float(totalWidth / r)))
        var rects: [CGRect] = [CGRect]()
        
        for(var j = 0; j < imageCount; ++j) {
            let image = images[j]
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            let width = height * imageWidth / imageHeight
            let rect = CGRectMake(0, 0, width, height)
            rects.append(rect)
        }
        
        return rects
    }

    func addImageSection(forImages: [UIImage]) {
        let rects = self.computeRects(forImages)
        var imageViews: NSMutableArray = NSMutableArray()
        
        for (var i = 0; i < rects.count; ++i) {
            let rect = rects[i]
            let image = forImages[i]
            
            let imageView = UIImageView(frame: rect)
            imageView.image = image
            imageViews.addObject(imageView)
        }
        
        self.cubes.addObject(imageViews)
        let sections = NSIndexSet(index: self.cubes.count - 1)
        self.collectionView.insertSections(sections)
    }
    
    func addImages(images: [UIImage]) {
        var rows: [[UIImage]] = [[UIImage]]()
        var rowImages: [UIImage] = [UIImage]()
        
        var imgs: [UIImage] = [UIImage]()
        
        for (var i = 0; i < images.count; ++i) {
            imgs.append(images[i])
            if (imgs.count == 3) {
                self.addImageSection(imgs)
                imgs.removeAll(keepCapacity: false)
            } else if (i == images.count - 1) {
                self.addImageSection(imgs)
            }
        }
        
//        let miFrame = CGRectMake(0, 0, self.collectionView.frame.size.width, 50)
//        
//        var miViews: [MIView] = [MIView]()
//        var miView = MIView(frame: miFrame)
//        miView.cellSpacing = self.cellSpacing
//        
//        for (var i = 0; i < images.count; ++i) {
//            let imageView = UIImageView(image: images[i])
//            
//            miView.addImageView(imageView)
//            
//            // each MIView should be limited to 3 image views
//            if (miView.subviewCount() == 3) {
//                miViews.append(miView)
//                miView = MIView(frame: miFrame)
//                miView.cellSpacing = self.cellSpacing
//            } else if (i == images.count - 1) {
//                miViews.append(miView)
//            }
//        }
//        
//        if (self.selectedIndex == nil) {
//            self.selectedIndex = NSIndexPath(forRow: 0, inSection: 0)
//        }
//        
//        for (var j = miViews.count-1; j >= 0; --j) {
//            self.cubes.insertObject(miViews[j], atIndex: self.selectedIndex!.row)
//            self.collectionView.insertItemsAtIndexPaths([self.selectedIndex!])
//            self.displayEditTools(self.selectedIndex!)
//        }
    }
    
//    func addImageView(image: UIImage, withRect: CGRect) {
//        if (self.selectedIndex == nil) {
//            self.selectedIndex = NSIndexPath(forRow: 0, inSection: 0)
//        }
//        
//        if (self.cubes.count > 0){
//            let view: UIImageView? = self.cubes.objectAtIndex(self.selectedIndex!.row) as? UIImageView
//            view?.highlighted = false
//        }
//        
//        let imageView = UIImageView(frame: withRect)
//        imageView.image = image
//        
//        self.cubes.insertObject(imageView, atIndex: self.selectedIndex!.row)
//        self.collectionView.insertItemsAtIndexPaths([self.selectedIndex!])
//        self.displayEditTools(self.selectedIndex!)
//    }
    
    func deleteSelected() {
        self.calloutView.dismissCalloutAnimated(true)
        
        let set = NSIndexSet(index: self.selectedIndex!.section)
        let section = self.cubes.objectAtIndex(self.selectedIndex!.section) as NSMutableArray
        let view = section.objectAtIndex(self.selectedIndex!.row) as UIView
        section.removeObjectAtIndex(self.selectedIndex!.row)
        
        //self.cubes.removeObjectAtIndex(index)
        self.collectionView.deleteItemsAtIndexPaths([self.selectedIndex!])
        
        if (section.count > 0) {
            if (view is UIImageView) {
                self.resizeSection(section)
                self.collectionView.reloadSections(set)
            }
        } else {
            // remove the section because it is empty
            self.cubes.removeObjectAtIndex(self.selectedIndex!.section)
            self.collectionView.deleteSections(set)
        }
        
        self.selectedIndex = nil
    }
    
    func displayEditTools(indexPath: NSIndexPath) {
        let attributes = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath)
        //let center = attributes!.center
        //let rect = CGRectMake(center.x - 1.5, center.y - 1.5, 3, 3)
        let btn: UIButton = self.calloutView.leftAccessoryView as UIButton
        let section = self.cubes.objectAtIndex(indexPath.section) as NSMutableArray
        let view: UIView = section.objectAtIndex(indexPath.row) as UIView
        
        if (view is UIImageView) {
            btn.enabled = false
        } else {
            btn.enabled = true
        }
        
        //var direction = self.calloutView.currentArrowDirection
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
    
    // edit selected text
    func editSelected() {
        
        self.editingText = true
        let section = self.selectedIndex!.section
        self.calloutView.dismissCalloutAnimated(false)
        
        let cube = self.cubes.objectAtIndex(section) as NSMutableArray
        let textView: UITextView = cube.objectAtIndex(0) as UITextView
        
        textView.becomeFirstResponder()
    }
    
    func resizeSection(section: NSMutableArray) {
        var images: [UIImage] = [UIImage]()
        
        // gather all images so we can compute the rectangles
        for(var i = 0; i < section.count; ++i) {
            let imageView = section.objectAtIndex(i) as UIImageView
            images.append(imageView.image!)
        }
        
        var rects = self.computeRects(images)
        
        // resize the frames
        for(var j = 0; j < images.count; ++j) {
            let imageView = section.objectAtIndex(j) as UIImageView
            imageView.frame = rects[j]
        }
    }
    
    func resizeImageViews(imageViews: [UIImageView]) {
        var images: [UIImage] = [UIImage]()
        for(var i = 0; i < imageViews.count; ++i) {
            images.append(imageViews[i].image!)
        }
        var rects = self.computeRects(images)
        
        for(var j = 0; j < imageViews.count; ++j) {
            imageViews[j].frame = rects[j]
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
                let section = self.cubes.objectAtIndex(i) as NSMutableArray
                
                for (var j = 0; j < section.count; ++j) {
                    let view: UIView = section.objectAtIndex(j) as UIView
                    view.userInteractionEnabled = false
                }
            }
            
            self.showToolbar()
            //self.collectionView.reloadData()
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
    
    @IBAction func addPhotoFromLibrary(sender: AnyObject) {
        let picker: CTAssetsPickerController = CTAssetsPickerController()
        picker.delegate = self
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func assetsPickerController(picker: CTAssetsPickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        
        let images: [UIImage] = assets.map({ (var asset) -> UIImage in
            let a = asset as ALAsset
            
            return UIImage(CGImage: a.defaultRepresentation().fullResolutionImage().takeRetainedValue())
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
            destination.loadTestImages()
        }
    }
    
    @IBAction func unwindToStory(unwindSegue: UIStoryboardSegue) {
    }
    
    // MARK: - Notifications
    func keyboardWillShow(notification: NSNotification) {
        //let text = SharedDataFrame.dataFrame!.annotation
        let text = self.textView!.text
        
        self.keyboardToolBarTextView?.text = text
        self.keyboardToolBarTextView?.becomeFirstResponder()
    }
    
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
            let section = self.selectedIndex?.section ?? 0
            let indexPath = NSIndexPath(forRow: 0, inSection: section)
            
            if (self.selectedIndex != nil) {
                
                // removed highlighted since it causes the system to crash when deserialized
                let cube = self.cubes.objectAtIndex(self.selectedIndex!.section) as NSMutableArray
                let view: UIImageView? = cube.objectAtIndex(self.selectedIndex!.row) as? UIImageView
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
                
                // wrap text around NSMutableArray
                let cube = NSMutableArray()
                cube.addObject(textCube)
                
                self.cubes.insertObject(cube, atIndex: section)
                self.calloutView.dismissCalloutAnimated(false)
                //self.collectionView.insertItemsAtIndexPaths([indexPath])
                self.collectionView.insertSections(NSIndexSet(index: section))
            } else {
                let cube = self.cubes.objectAtIndex(section) as NSMutableArray
                let textCube = cube.objectAtIndex(0) as UITextView
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

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, willBeginDraggingItemAtIndexPath indexPath: NSIndexPath!) {
        
        self.calloutView.dismissCalloutAnimated(true)
        //self.selectedIndex = indexPath
    }
    
//    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, didEndDraggingItemAtIndexPath indexPath: NSIndexPath!) {
//        // drag ends on touch up
//    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, indexPathForItemAtPoint point: CGPoint) -> NSIndexPath? {
        
        var newIndex: NSIndexPath? = self.collectionView.indexPathForItemAtPoint(point)
        
//        if (newIndex == nil) {
//            let attr = self.collectionView.layoutAttributesForItemAtIndexPath(self.selectedIndex!)
//            let y = attr!.frame.origin.y
//            let h = attr!.frame.size.height
//            
//            let cube = self.cubes.objectAtIndex(self.selectedIndex!.section) as NSMutableArray
//            let view = cube.objectAtIndex(self.selectedIndex!.row) as UIView
//            //cube.removeObject(view)
//            
//            //newIndex = NSIndexPath(forRow: 0, inSection: 0)
//            
//            if (point.y < y) {
//                let nCube = NSMutableArray()
//                nCube.addObject(view)
//                    
//                let section = self.selectedIndex!.section
//                
//                self.cubes.insertObject(nCube, atIndex: section)
//                self.collectionView.insertSections(NSIndexSet(index: section))
//                self.resizeSection(nCube)
//                
//                //newIndex = NSIndexPath(forRow: 0, inSection: section)
//                
//                // use the selectedIndex path that is set here in the will move and can move methods
//                self.selectedIndex = NSIndexPath(forRow: self.selectedIndex!.row, inSection: section+1)
//                
//            } else if (point.y > y + h) {
//                let cube = NSMutableArray()
//                let section = self.selectedIndex!.section + 1
//
//                self.cubes.insertObject(cube, atIndex: section)
//                self.collectionView.insertSections(NSIndexSet(index: section))
//                
//                //newIndex = NSIndexPath(forRow: 0, inSection: section)
//            }
//            
//        } else {
//            println("section: \(newIndex?.section) index: \(newIndex?.row)")
//        }
        
        return newIndex
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,  insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 0, bottom: self.cellSpacing, right: 0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.cellSpacing
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.cellSpacing
    }
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
//        
//        return CGSizeMake(self.collectionView.frame.size.width, self.cellSpacing)
//    }
    
    // MARK: - LXReorderableCollectionViewDataSource
    func collectionView(collectionView: UICollectionView!, canMoveItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return self.editable
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, canMoveToIndexPath toIndexPath: NSIndexPath!) -> Bool {
        
        let fromSection = self.cubes.objectAtIndex(fromIndexPath.section) as NSMutableArray
        let toSection = self.cubes.objectAtIndex(toIndexPath.section) as NSMutableArray
        
        // if moving to different sections
        if (fromIndexPath.section != toIndexPath.section) {
            let toView = toSection.objectAtIndex(0) as UIView
            let fromView = fromSection.objectAtIndex(0) as UIView
            
            // if section is an UIImageView section with 3 or more items
            if ( toView is UIImageView && toSection.count >= 3 ) {
                return false
            }
            
            if ( toView is UIImageView && fromView is UITextView) {
                return false
            }
            
            if ( fromView is UIImageView && toView is UITextView) {
                return false
            }
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell: UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("EmptyCell", forIndexPath: indexPath) as UICollectionViewCell

        let section: NSMutableArray = self.cubes.objectAtIndex(indexPath.section) as NSMutableArray
        let view: UIView = section.objectAtIndex(indexPath.row) as UIView
        
        if (view is UITextView) {
            let textView = view as UITextView
            textView.delegate = self
        }
    
        cell.addSubview(view)
        
        return cell
    }
    
//    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, didMoveToIndexPath toIndexPath: NSIndexPath!) {
//        //self.selectedIndex = toIndexPath
//    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, willMoveToIndexPath toIndexPath: NSIndexPath!) {
        
        let section1 = self.cubes.objectAtIndex(fromIndexPath.section) as NSMutableArray
        let section2 = self.cubes.objectAtIndex(toIndexPath.section) as NSMutableArray
        
        var view = section1.objectAtIndex(fromIndexPath.row) as UIView
        section1.removeObject(view)
        section2.insertObject(view, atIndex: toIndexPath.row)
        
        //self.calloutView.dismissCalloutAnimated(true)
        
        // same section no resize
        if (fromIndexPath.section == toIndexPath.section) {
            return
        }
        
        if (section2.count == 1) {
            self.collectionView.reloadSections(NSIndexSet(index: toIndexPath.section))
        }
        
        if (view is UITextView) {
            return
        }
        
        if (section1.count > 0) {
            self.resizeSection(section1)
        }
        
        self.resizeSection(section2)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return self.cubes.count
        
        return self.cubes.objectAtIndex(section).count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.cubes.count
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
        
        let section: NSMutableArray = self.cubes.objectAtIndex(indexPath.section) as NSMutableArray
        let view: UIView = section.objectAtIndex(indexPath.row) as UIView
    
        return view.frame.size
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if (!self.editable) {
            return
        }
        
        // remove highlighted flag because it causes
        // -[NSKeyedUnarchiver decodeBoolForKey:]: value for key (UIHighlighted) is not a boolean
        let section = self.cubes.objectAtIndex(indexPath.section) as NSMutableArray
        let imageView: UIImageView? = section.objectAtIndex(indexPath.row) as? UIImageView
        imageView?.highlighted = false
        
        //let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        //view.layer.borderWidth = 3.0
        //view.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.90).CGColor
        //view.layer.borderColor = UIColor(red: 0.2, green:0.6, blue: 0.4, alpha: 0.95).CGColor

        self.selectedIndex = indexPath
        self.displayEditTools(indexPath)
    }
    
//    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        
//        //let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
//        //view.layer.borderWidth = 0.0
//    
//        //self.calloutView.dismissCalloutAnimated(true)
//        //self.selectedIndex = nil
//    }
    
//    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
//        return true
//    }
}
