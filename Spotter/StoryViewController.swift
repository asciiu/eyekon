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

class StoryViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, HPGrowingTextViewDelegate, LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout,CTAssetsPickerControllerDelegate, AwesomeMenuDelegate, SPUserResizableViewDelegate {

    @IBOutlet var upperRightButton: UIBarButtonItem!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var toolbar: UIToolbar!

    var cellSpacing: CGFloat = 3.0

    // ordered collection of UIViews
    var cubes: NSMutableArray = NSMutableArray()
    var cubeControls: NSMutableArray = NSMutableArray()
    
    // flag used to determine if parent view is editable
    var editable: Bool = false
        
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
    var currentIndexPath: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    var selectedIndexPath: NSIndexPath?

    // callout used for editing tools
    let calloutView: SMCalloutView = SMCalloutView.platformCalloutView()
    let editBtn: UIButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
    let deleteBtn: UIButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
    
    // main tool to add new content
    var mainTool: AwesomeMenu?
    var mainToolPosition: CGPoint = CGPointMake(0, 0)
    
    let resizeTool = SPUserResizableView(frame: CGRectMake(-10, -10, 5, 5))
    
//    func handleTap(gesture: UITapGestureRecognizer) {
//        let touchPoint: CGPoint = gesture.locationInView(self.collectionView.backgroundView!)
//        println("tap: \(touchPoint.x) \(touchPoint.y)")
//    }
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

        self.collectionView.clipsToBounds = false
        self.collectionView.delegate = self
//        self.collectionView.backgroundView = UIView()
//        self.collectionView.backgroundView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "handleTap:"))
        
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
        
        let addImage = UIImage(named: "add.png")
        let txtImage = UIImage(named: "txtTool.png")
        let libImage = UIImage(named: "libTool.png")
        let camImage = UIImage(named: "camTool.png")
        
        let txtBtn = AwesomeMenuItem(image: txtImage, highlightedImage: txtImage, contentImage: txtImage, highlightedContentImage: nil)
        let camBtn = AwesomeMenuItem(image: camImage, highlightedImage: camImage, contentImage: camImage, highlightedContentImage: nil)
        let libBtn = AwesomeMenuItem(image: libImage, highlightedImage: libImage, contentImage: libImage, highlightedContentImage: nil)
        let addBtn = AwesomeMenuItem(image: addImage, highlightedImage: addImage, contentImage: addImage, highlightedContentImage: addImage)
        
        self.mainTool = AwesomeMenu(frame: self.view.frame, startItem: addBtn, optionMenus: [txtBtn, libBtn, camBtn])
        //self.mainTool = AwesomeMenu(frame: self.view.frame, menus: [txtBtn, libBtn, camBtn])
        //self.mainTool!.image = addImage
        self.mainTool!.delegate = self

        //self.mainTool = AwesomeMenu(frame: self.view.frame, startItem: addBtn, optionMenus:[txtBtn, libBtn, camBtn])
        self.mainTool!.startPoint = CGPointMake(self.view.frame.size.width - addImage!.size.width,
                                                self.view.frame.size.height - addImage!.size.height)
        
        //self.mainTool!.startPoint = CGPointMake(200, 300)
        self.mainTool!.menuWholeAngle = CGFloat(-M_PI/2)
        self.view.addSubview(self.mainTool!)
        self.resizeTool.delegate = self        
        self.collectionView.addSubview(self.resizeTool)
        //self.resizeTool.showEditingHandles()
    }
    
    func userResizableViewDidResize(size: CGSize) {
        
        if (self.selectedIndexPath == nil) {
            return;
        }
        
        let view = self.cubes.objectAtIndex(self.selectedIndexPath!.row) as UIView
        if (view is UIImageView) {
            self.collectionView.reloadItemsAtIndexPaths([self.selectedIndexPath!])
        }
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
            self.showToolbar()
            //self.masterTool.center = self.view.center

        } else {
            // hide toolbar
            //self.toolbar.frame.origin.y = self.view.frame.size.height
            //self.mainTool!.userInteractionEnabled = false

            //self.mainTool!.startPoint = CGPointMake(self.view.frame.size.width,
            //    self.view.frame.size.height)
        }
        
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
        
        for (var i = 0; i < images.count; ++i) {
            imageGroup.append(images[i])
            
            if (imageGroup.count == 3) {
                imageGroups.append(imageGroup)
                imageGroup = [UIImage]()
            } else if (i == images.count - 1) {
                imageGroups.append(imageGroup)
            }
        }
        
        for (var i = 0; i < imageGroups.count; ++i) {
            let group = imageGroups[i]
            let rects = self.computeRects(group)
            
            for (var r = 0; r < group.count; ++r) {
                let imageView = UIImageView(frame: rects[r])
                imageView.image = group[r]
                self.cubes.insertObject(imageView, atIndex: self.currentIndexPath.row)
    
                self.collectionView.insertItemsAtIndexPaths([self.currentIndexPath])
                self.currentIndexPath = NSIndexPath(forRow: self.currentIndexPath.row+1, inSection: self.currentIndexPath.section)
            }
        }
    }
    
    func deleteSelected() {
        self.calloutView.dismissCalloutAnimated(true)
        
        self.cubes.removeObjectAtIndex(self.currentIndexPath.row)
        self.collectionView.deleteItemsAtIndexPaths([self.currentIndexPath])
        
        // move current index path to previous index item
        if (self.currentIndexPath.row > 0) {
            self.currentIndexPath.row.advancedBy(-1)
        }
        
        self.selectedIndexPath = nil
    }
    
    func displayEditTools(indexPath: NSIndexPath) {
        let attributes = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath)
        let btn: UIButton = self.calloutView.leftAccessoryView as UIButton
        let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        
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
        self.calloutView.dismissCalloutAnimated(false)
        let textView: UITextView = self.cubes.objectAtIndex(self.selectedIndexPath!.row) as UITextView
        
        textView.becomeFirstResponder()
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

                //self.toolbar.frame.origin.y = self.view.frame.size.height - self.toolbar.frame.size.height
                
            }, completion: { (value: Bool) in
                self.mainTool!.userInteractionEnabled = true
        })
    }
    
    // MARK: - Actions
    
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
            
//            let fireRef: Firebase = Firebase(url: "https://eyekon.firebaseio.com")
//            fireRef.setValue("what next?")
            
            
        } else {
            // edit
            self.editable = true
            self.collectionView.userInteractionEnabled = true
            self.upperRightButton.title = "Save"
            
            self.titleTextField!.userInteractionEnabled = true
            
            for (var i = 0; i < self.cubes.count; ++i) {
                let view = self.cubes.objectAtIndex(i) as UIView
                
                // this ensures that text cubes are draggable when touched
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
            self.displayEditTools(self.currentIndexPath)
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
            //let index = self.selectedIndex?.row ?? 0
            //let indexPath = NSIndexPath(forRow: index, inSection: 0)
    
            self.keyboardToolBarTextView!.resignFirstResponder()
            self.textView!.resignFirstResponder()
            
            self.textView!.text = self.keyboardToolBarTextView!.text
            self.textView!.sizeToFit()
            let frameWidth = self.collectionView.frame.size.width
            
            //self.selectedIndex = indexPath
            
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
                
                self.cubes.insertObject(textCube, atIndex: self.currentIndexPath.row)
                self.collectionView.insertItemsAtIndexPaths([self.currentIndexPath])
                self.currentIndexPath = NSIndexPath(forRow: self.currentIndexPath.row+1, inSection: self.currentIndexPath.section)
                
                self.calloutView.dismissCalloutAnimated(false)
            } else {
                //let cube = self.cubes.objectAtIndex(index) as NSMutableArray
                let textCube = self.cubes.objectAtIndex(self.selectedIndexPath!.row) as UITextView
                textCube.text = self.keyboardToolBarTextView!.text
                textCube.sizeToFit()
                //self.collectionView.reloadItemsAtIndexPaths([self.selectedIndexPath!])
            }
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
    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
//        return UIEdgeInsets(top: 0, left: 0, bottom: self.cellSpacing, right: 0)
//    }
    
//    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, didEndDraggingItemAtIndexPath indexPath: NSIndexPath!) {
//        // drag ends on touch up
//    }
    
//    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, indexPathForItemAtPoint point: CGPoint) -> NSIndexPath? {
//        
//        var newIndex: NSIndexPath? = self.collectionView.indexPathForItemAtPoint(point)
    
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
        
//        return newIndex
//    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.cellSpacing
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return self.cellSpacing
    }
    
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, resizeItemFromIndexPath: NSIndexPath, toPoint: CGPoint) -> NSIndexPath! {
        
        var newIndexPath = self.collectionView.indexPathForItemAtPoint(toPoint)
        
        // if y is beyond the content bounds
        if (toPoint.y > self.collectionView.contentSize.height) {
            let view = self.cubes.objectAtIndex(resizeItemFromIndexPath.row) as UIView
        
            if (view is UIImageView) {
                let imageView = view as UIImageView
                let image = imageView.image!
                let rect = self.computeRects([image])[0]
                imageView.frame = rect
                self.collectionView.reloadItemsAtIndexPaths([resizeItemFromIndexPath])
            }
            
            // indexPath is the last item
            newIndexPath = NSIndexPath(forRow: self.cubes.count-1, inSection: 0)
        }
        
        return newIndexPath
    }
    
 
    
    // MARK: - LXReorderableCollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView!, canMoveItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return self.editable
    }
    
    func itemAtIndexPath(indexPath: NSIndexPath!, didResize newSize: CGSize) {
        let view = self.cubes.objectAtIndex(indexPath.row) as UIView
        view.frame = CGRectMake(0, 0, newSize.width, newSize.height);
        self.collectionView.reloadItemsAtIndexPaths([indexPath])
    }
    
    func itemSizeAtIndexPath(indexPath: NSIndexPath!) -> CGRect {
        let view = self.cubes.objectAtIndex(indexPath.row) as UIView
        var rect = view.frame
        
        if (view is UIImageView) {
            let image = (view as UIImageView).image
            
            if( image != nil) {
                rect.size.width = image!.size.width
                rect.size.height = image!.size.height                
            }
        }
        
        return rect
    }
    
//    func collectionView(collectionView: UICollectionView!, updateItemAtIndexPath indexPath: NSIndexPath!) {
//        let view = self.cubes.objectAtIndex(indexPath.row) as UIView
//        
//        if (view is UIImageView) {
//            let imageView = view as UIImageView
//            let image = imageView.image!
//            let rect = self.computeRects([image])[0]
//            imageView.frame = rect
//            self.collectionView.reloadItemsAtIndexPaths([indexPath])
//        }
//    }
    
//    func collectionView(collectionView: UICollectionView!, relocateItemAtIndexPath fromIndexPath: NSIndexPath!, toPoint pt: CGPoint) {
//        if (pt.y > self.collectionView.contentSize.height) {
//            
//            let section = self.cubes.objectAtIndex(fromIndexPath.section) as NSMutableArray
//            let view = section.objectAtIndex(fromIndexPath.row) as UIView
//            
//            section.removeObject(view)
//            //self.collectionView.deleteItemsAtIndexPaths([fromIndexPath])
//            //self.resizeSection(section)
//            
//            //let contentY = self.collectionView.contentSize.height
//            //self.collectionView.contentOffset.y = contentY
//            
//            let newSection = NSMutableArray()
//            newSection.addObject(view)
//            self.resizeSection(newSection)
//            self.cubes.addObject(newSection)
//            //self.collectionView.reloadSections(NSIndexSet(index: self.cubes.count-1))
//            self.collectionView.insertSections(NSIndexSet(index: self.cubes.count-1))
//        }
//    }
    
//    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, canMoveToIndexPath toIndexPath: NSIndexPath!) -> Bool {
//        return true
//    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell: UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("EmptyCell", forIndexPath: indexPath) as UICollectionViewCell

        let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        view.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        
        if (view is UITextView) {
            let textView = view as UITextView
            textView.delegate = self
        }
    
        cell.contentView.autoresizesSubviews = false
        cell.contentView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        cell.contentView.addSubview(view)
        
        return cell
    }
    
//    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, didMoveToIndexPath toIndexPath: NSIndexPath!) {
//        //self.selectedIndex = toIndexPath
//    }
    
//    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, canMoveToIndexPath toIndexPath: NSIndexPath!) -> Bool {
//        
//        if (toIndexPath.section == fromIndexPath.section) {
//            return true
//        }
//        
//        let destinationSection = self.cubes.objectAtIndex(toIndexPath.section) as NSMutableArray
//        if (destinationSection.count == 3) {
//            return false
//        }
//        
//        return true
//    }
    

    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, willMoveToIndexPath toIndexPath: NSIndexPath!) {
        
        var view = self.cubes.objectAtIndex(fromIndexPath.row) as UIView
        self.cubes.removeObject(view)
        self.cubes.insertObject(view, atIndex: toIndexPath.row)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cubes.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // MARK: - UIScrollViewDelegate
    
//    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if(self.selectedIndexPath == nil) {
//            return
//        }
//        
//        displayEditTools(self.selectedIndexPath!)
//    }
//    
//    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
//        if(self.selectedIndexPath == nil) {
//            return
//        }
//        
//        displayEditTools(self.selectedIndexPath!)
//    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        return view.frame.size
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if (!self.editable) {
            return
        }
        
        //let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        //view.layer.borderWidth = 3.0
        //view.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.90).CGColor
        //view.layer.borderColor = UIColor(red: 0.2, green:0.6, blue: 0.4, alpha: 0.95).CGColor

        self.currentIndexPath = indexPath
        self.selectedIndexPath = indexPath
        self.displayEditTools(indexPath)
        
//        let view = self.cubes.objectAtIndex(indexPath.row) as UIView
//        if (view is UIImageView) {
//            let attr = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath)
//            self.resizeTool.contentView = view
//            self.resizeTool.contentFrame = attr!.frame
//            self.resizeTool.showEditingHandles()
//            //self.resizeTool.frame = attr!.frame
//            //self.resizeTool.showEditingHandles()
//            //self.resizeTool.contentView = view
//        }
    }
}
