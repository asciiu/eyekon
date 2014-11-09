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


class StoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, HPGrowingTextViewDelegate,CTAssetsPickerControllerDelegate, AwesomeMenuDelegate, SPUserResizableViewDelegate, MIDelegate {

    @IBOutlet var upperRightButton: UIBarButtonItem!
    //@IBOutlet var collectionView: UICollectionView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var deleteBtn: UIBarButtonItem!
    @IBOutlet var editBtn: UIBarButtonItem!
    
    var cellSpacing: CGFloat = 3.0

    // ordered collection of UIViews
    var cubes: NSMutableArray = NSMutableArray()
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
    //let calloutView: SMCalloutView = SMCalloutView.platformCalloutView()
    //let editBtn: UIButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
    //let deleteBtn: UIButton = UIButton(frame: CGRectMake(0, 0, 30, 30))
    
    // main tool to add new content
    var mainTool: AwesomeMenu?
    var mainToolPosition: CGPoint = CGPointMake(0, 0)
    
    let fireRef: Firebase = Firebase(url: "https://eyekon.firebaseio.com")
    
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
        self.textView = UITextView(frame: CGRectMake(0, self.tableView.frame.size.height, self.tableView.frame.size.width, 50))
        self.textView!.returnKeyType = UIReturnKeyType.Done
        self.textView!.inputAccessoryView = self.keyboardToolBar
        self.textView!.userInteractionEnabled = false
        self.textView!.font = UIFont.systemFontOfSize(16)
        self.textView!.inputAccessoryView = self.keyboardToolBar
        self.view.addSubview(self.textView!)
        
        // delete button for callout view
        //self.deleteBtn.setImage(UIImage(named: "trash.png"), forState: UIControlState.Normal)
        //self.deleteBtn.addTarget(self, action: "deleteSelected", forControlEvents: UIControlEvents.TouchUpInside)
        
        // edit button for callout view
        //self.editBtn.setImage(UIImage(named: "pencil.png"), forState: UIControlState.Normal)
        //self.editBtn.addTarget(self, action: "editSelected", forControlEvents: UIControlEvents.TouchUpInside)
        
        //self.calloutView.leftAccessoryView = self.editBtn
        //self.calloutView.rightAccessoryView = self.deleteBtn
        
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
        self.mainTool!.startPoint = CGPointMake(self.view.frame.size.width/2,
                                                self.view.frame.size.height - addImage!.size.height/2)
        
        //self.mainTool!.startPoint = CGPointMake(200, 300)
        self.mainTool!.menuWholeAngle = CGFloat(-M_PI/3)
        //self.toolbar.addSubview(self.mainTool!)
        self.view.addSubview(self.mainTool!)
        //self.resizeTool.delegate = self
        //self.tableView.addSubview(self.resizeTool)
        
        //self.tableView.contentInset = UIEdgeInsetsMake( CGRectGetHeight(self.navigationController!.toolbar.frame), 0, 0, 0)
        
        //self.resizeTool.showEditingHandles()
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
        self.editBtn.enabled = false
        
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
        
            self.fireRef.observeEventType(FEventType.Value, withBlock: { (data:FDataSnapshot!) -> Void in
                
                if (data.value == nil) {
                    return
                }
                
                if (self.editable) {
                    return
                }
                
                let base64: NSString = data.value["post"] as NSString
                let data = NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                
                self.cubes = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as NSMutableArray
                
                println(self.cubes.count)
                self.tableView.reloadData()
            })
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
    func editSelected() {
        self.editingText = true
        //self.calloutView.dismissCalloutAnimated(false)
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
        
        self.cubes.removeObjectAtIndex(self.selectedIndexPath!.row)
        self.tableView.deleteRowsAtIndexPaths([self.selectedIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
        
        // move current index path to previous index item
        //if (self.currentIndexPath.row > 0) {
        //    self.currentIndexPath.row.advancedBy(-1)
        //}
        
        self.selectedIndexPath = nil
        self.deleteBtn.enabled = false
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
            
            let ref = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed)
            
            self.fireRef.setValue(["name":"eyekon", "post":ref])
            
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
        self.editingText = false
        self.keyboardToolBar!.frame = CGRectMake(0, 0, self.view.frame.width, 35)
        self.keyboardToolBarTextView!.frame = CGRectMake(0, 0, self.view.frame.width, 35)
        self.keyboardToolBarTextView!.text = ""
        self.textView!.text = ""
        
        self.textView!.becomeFirstResponder()
        self.keyboardToolBarTextView!.text = ""
        self.keyboardToolBarTextView!.becomeFirstResponder()
        //self.calloutView.dismissCalloutAnimated(false)
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
            textView.resignFirstResponder()
            //self.displayEditTools(self.currentIndexPath)
        } else {
            let frameWidth = self.tableView.frame.size.width
            let cellHeight = textView.frame.size.height
            
            textView.sizeToFit()
            textView.frame.size.width = frameWidth
            
            if (textView.frame.size.height != cellHeight) {
                //self.tableView.collectionViewLayout.invalidateLayout()
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
            let frameWidth = self.tableView.frame.size.width
            
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
                self.tableView.insertRowsAtIndexPaths([self.currentIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                //self.collectionView.insertItemsAtIndexPaths([self.currentIndexPath])
                self.currentIndexPath = NSIndexPath(forRow: self.currentIndexPath.row+1, inSection: self.currentIndexPath.section)
                
                //self.calloutView.dismissCalloutAnimated(false)
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
        
        if (!self.editable) {
            return
        }
        
        // add a blue border around the selection
        let view = self.cubes.objectAtIndex(indexPath.row) as UIView
        
        if (view is MIView) {
            view.layer.borderColor = UIColor(red: 0.64, green: 0.76, blue: 0.96, alpha: 1).CGColor
            view.layer.borderWidth = 3.0
            self.deleteBtn.enabled = true
        } else if (view is UITextView) {
            self.editBtn.enabled = true
        }
        
        
        //self.displayEditTools(indexPath)
        self.currentIndexPath = indexPath
        self.selectedIndexPath = indexPath
    }
}
