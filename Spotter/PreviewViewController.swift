//
//  PreviewViewController.swift
//  Spotter
//
//  Created by LV426 on 9/11/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, LXReorderableCollectionViewDataSource {

    //@IBOutlet var upperLeftButton: UIBarButtonItem!
    @IBOutlet var upperRightButton: UIBarButtonItem!
    @IBOutlet var collectionView: UICollectionView!
    
    var dataFrames: [Frame]?
    var cubes: NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.collectionView.clipsToBounds = false
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
        self.dataFrames = SharedDataFrameSet.sortedDataFrames()
        
        let frameWidth = self.collectionView.frame.width
        for cube in self.dataFrames! {
            let image = UIImage(data: cube.imageData)
            
            let originalWidth = image.size.width
            let originalHeight = image.size.height
            let height = frameWidth * originalHeight / originalWidth
            
            let imageView = UIImageView(frame: CGRectMake(0, 0, frameWidth, height))
            imageView.image = image
            
            self.cubes.addObject(imageView)
            //println("add frame data to cubes array")
            
            if(cube.annotation != nil && cube.annotation != "") {
                let textView = UITextView(frame: CGRectMake(0, 0, frameWidth, 0))
                textView.editable = false
                textView.selectable = false
                textView.text = cube.annotation
                textView.sizeToFit()
                
                self.cubes.addObject(textView)
            }
        }
        
        let controllers = self.navigationController!.viewControllers
        let previousController: UIViewController = controllers[controllers.count-2] as UIViewController
        
        if (previousController is CollectionViewController) {
            self.upperRightButton.title = "Edit"
        } else if(previousController is CaptureViewController || previousController is AnnotateViewController) {
            self.upperRightButton.title = "Publish"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    
    @IBAction func returnToPrevious(sender: AnyObject) {
        // pop myself off the stack of view controllers and show the previous 
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func publish(sender: AnyObject) {
        
        if (self.upperRightButton.title == "Publish") {
            self.performSegueWithIdentifier("FromPreviewToPublish", sender: self)
        } else {
            // edit
            self.performSegueWithIdentifier("FromPreviewToCapture", sender: self)
            
            // MARK: - todo show editing tools here and remove seque above
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
    }
    
    // MARK: - LXReorderableCollectionViewDataSource
    func collectionView(collectionView: UICollectionView!, canMoveItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var cell: UICollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("EmptyCell", forIndexPath: indexPath) as UICollectionViewCell
        
        let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        //let frame = self.dataFrames![indexPath.row]
        //let image = UIImage(data: frame.imageData)
        //let imageView = UIImageView(image: image)

        cell.addSubview(view)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, didMoveToIndexPath toIndexPath: NSIndexPath!) {
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, willMoveToIndexPath toIndexPath: NSIndexPath!) {
        let view: UIView = self.cubes.objectAtIndex(fromIndexPath.row) as UIView
        self.cubes.removeObject(view)
        self.cubes.insertObject(view, atIndex: toIndexPath.row)        
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return self.dataFrames!.count
        return self.cubes.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
//        let frame = self.dataFrames![indexPath.row]
//        let image = UIImage(data: frame.imageData)
//        
//        let frameWidth = collectionView.frame.width
//        let originalWidth = image.size.width
//        let originalHeight = image.size.height
//        let height = frameWidth * originalHeight / originalWidth
        let view: UIView = self.cubes.objectAtIndex(indexPath.row) as UIView
        let size = view.frame.size
        
        
        return size
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
    
    // MARK: - UITableViewDataSource
   
//    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
//        
//        let data = self.dataFrames![sourceIndexPath.row]
//        self.dataFrames!.removeAtIndex(sourceIndexPath.row)
//        self.dataFrames!.insert(data, atIndex: destinationIndexPath.row)
//    }
//    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return SharedDataFrameSet.dataFrameSet!.frames.count
//    }
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        
//        // try to get a reusable cell for our custom cell class
//        var cell: SimpleTableViewCell = tableView.dequeueReusableCellWithIdentifier("SimpleTableViewCell") as SimpleTableViewCell
//        
//        let frame = self.dataFrames![indexPath.row]
//        let image = UIImage(data: frame.imageData)
//        
//        let frameWidth = cell.mainImage.frame.width
//        let originalWidth = image.size.width
//        let originalHeight = image.size.height
//        let height = frameWidth * originalHeight / originalWidth
//        
//        cell.mainImage.frame.size = CGSizeMake(frameWidth, height)
//        cell.mainImage.image = image
//        cell.annotationTextView.frame.origin.y = height
//        cell.showsReorderControl = true
//    
//        // show annotation if the info frame has one
//        if(frame.annotation != nil && frame.annotation != "") {
//            cell.annotationTextView.text = frame.annotation
//            
//            cell.annotationTextView.sizeToFit()
//            //let textFrame = cell.annotationTextView.contentSize
//            
//            //cell.annotationTextView.backgroundColor = UIColor.blackColor()
//            //cell.annotationTextView.textColor = UIColor.whiteColor()
//            cell.annotationTextView.hidden = false
//        } else {
//            cell.annotationTextView.hidden = true
//        }
//        
//        return cell
//    }

    // MARK: UITableViewDelegate
//    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        return true
//    }
//    
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        
//        let frame = self.dataFrames![indexPath.row]
//        let image = UIImage(data: frame.imageData)
//        
//        let frameWidth = self.tableView.contentSize.width
//        let gap = (self.view.frame.width - frameWidth) / 2
//        let originalWidth = image.size.width
//        let originalHeight = image.size.height
//        var height = frameWidth * originalHeight / originalWidth
//        
//        if( frame.annotation != nil) {
//            let attributes: NSDictionary = [NSFontAttributeName: UIFont.systemFontOfSize(15)]
//            
//            // NSString class method: boundingRectWithSize:options:attributes:context is
//            // available only on ios7.0 sdk.
//            let rect: CGRect = frame.annotation!.boundingRectWithSize(CGSizeMake(frameWidth, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: attributes, context: nil)
//            
//            height += rect.height + 5
//        }
//        
//        return height + gap
//    }
    
//    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
//        
//    }
}
