//
//  HowToListViewController.swift
//  Spotter
//
//  Created by LV426 on 8/27/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate {

    var stories: [Story] = [Story]()
    var selectedStory: Story?
    let coreContext: CoreContext = CoreContext()
    var user: User?
    
    @IBOutlet var collectionView: UICollectionView!
    //@IBOutlet var tableView: UITableView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var profileImageButton: UIButton!
    
    let imagePicker: UIImagePickerController = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()

       // self.tableView.allowsMultipleSelectionDuringEditing = false
        
        self.profileImageButton.layer.cornerRadius = self.profileImageButton.layer.frame.size.width/2
        self.profileImageButton.clipsToBounds = true
        self.profileImageButton.layer.borderWidth = 1.0
        self.profileImageButton.layer.borderColor = UIColor.grayColor().CGColor
        //self.profileImageButton.imageView!.contentMode = UIViewContentMode.ScaleAspectFill
        
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.usernameLabel.text = ""
        
        let entityDesc: NSEntityDescription? = NSEntityDescription.entityForName("User", inManagedObjectContext: self.coreContext.context)
        
        // create a fetch request with the entity description
        // this works like a SQL SELECT statement
        let request: NSFetchRequest = NSFetchRequest()
        request.entity = entityDesc!
        
        let pred: NSPredicate = NSPredicate(format:"(uid = %@)", EKClient.authData!.uid)!
        request.predicate = pred
        
        var error: NSError?
        let users = self.coreContext.context.executeFetchRequest(request, error: &error) as [User]
        
        if (users.count == 0) {
            EKClient.userHomeURL?.observeSingleEventOfType(FEventType.Value, withBlock: { (data:FDataSnapshot!) -> Void in
                if (data.value === NSNull()) {
                    return
                }
                
                let user: User = self.coreContext.createEntity("User") as User
                
                user.uid = EKClient.authData!.uid
                user.first = data.value["first"] as NSString
                user.last  = data.value["last"] as NSString
                self.usernameLabel.text = user.first + " " + user.last
                
                let base64Image: [NSString]? = data.value["profileImage"] as? [NSString]
                
                if (base64Image != nil) {
                    var str = ""
                    for chunk in base64Image! {
                        str += chunk
                    }
                    
                    let data = NSData(base64EncodedString: str, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                   
                    user.profileImage = data
                    
                    let image = UIImage(data: data!)
                    self.profileImageButton.setImage(image, forState: UIControlState.Normal)
                }
                
                var error: NSError?
                if( !user.managedObjectContext!.save(&error)) {
                    println("ProfileViewControler: could not save User: \(error?.localizedDescription)")
                } else {
                    self.user = user
                }
            })
        } else {
            let user = users[0]
            self.usernameLabel.text = user.first + " " + user.last
            
            if (user.profileImage != nil) {
                let image = UIImage(data: user.profileImage!)
                self.profileImageButton.setImage(image, forState: UIControlState.Normal)
            }
            self.user = user
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadManagedCollection()
        self.collectionView.reloadData()
        //self.tableView.reloadData()
        
        //self.usernameLabel.text = EKClient.username
        
        self.navigationItem.rightBarButtonItem?.title = "Logout"
        
//        let postURL = url + "/users/" + EKClient.authData!.uid + "/posts"
//        let ref = Firebase(url: postURL)
//
        let userStories = EKClient.userStories.childByAppendingPath(EKClient.authData?.uid)
        userStories.observeEventType(FEventType.Value, withBlock: { (data: FDataSnapshot!) -> Void in
            if (data.value === NSNull()) {
                return
            }
            let stories = data.children.allObjects as [FDataSnapshot]
            
            for story in stories {
                let storyID = story.name
                let title = story.value["hashtag"] as NSString
                //println(storyID + " " + title)
            }
        })
        
//        EKClient.userPostsRef?.observeEventType(FEventType.Value, withBlock: { (data:FDataSnapshot!) -> Void in
//            
//            if (data.value === NSNull()) {
//                return
//            }
//            
//            let hashtag: NSString = data.value["hashtag"] as NSString
//            let base64: NSString = data.value["packet"] as NSString
//            
//            let data = NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
//            
//            let story: Story = NSEntityDescription.insertNewObjectForEntityForName("Story", inManagedObjectContext: self.context!) as Story
//            story.title = hashtag
//            story.summary = "Summary"
//            
//            let content = NSEntityDescription.insertNewObjectForEntityForName("StoryContent", inManagedObjectContext: self.context!) as StoryContent
//            
//            story.content = content
//            content.story = story
//            content.data = data
//
//            //var error: NSError?
//            //if( content.managedObjectContext!.save(&error)) {
//            //    println("could not save story: \(error?.localizedDescription)")
//            //} else {
//                self.stories.append(story)
//                self.tableView.reloadData()
//            //}
//            
//            //self.cubes = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as NSMutableArray
//            
//            //println(self.cubes.count)
//            //self.tableView.reloadData()
//        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    func loadManagedCollection() {
        
        let entityDesc: NSEntityDescription? = NSEntityDescription.entityForName("Story", inManagedObjectContext: self.coreContext.context)
        
        // create a fetch request with the entity description
        // this works like a SQL SELECT statement
        let request: NSFetchRequest = NSFetchRequest()
        request.entity = entityDesc!
        
        let pred: NSPredicate = NSPredicate(format:"(uid = %@)", EKClient.authData!.uid)!
        request.predicate = pred
        
        var error: NSError?
        self.stories = self.coreContext.context.executeFetchRequest(request, error: &error) as [Story]
    }
    
    // MARK: - Actions
    @IBAction func addStory(sender: AnyObject) {
        self.selectedStory = nil
        self.performSegueWithIdentifier("FromCollectionToStory", sender: self)
    }
    
    @IBAction func logout(sender: AnyObject) {
        EKClient.logout()
        NSNotificationCenter.defaultCenter().postNotificationName(EKLogoutNotification, object: self)
        self.dismissViewControllerAnimated(true, completion: nil)

        //self.navigationController?.popToRootViewControllerAnimated(true)
    }

    @IBAction func changeProfileImage(sender: AnyObject) {
        self.presentViewController(self.imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        let cropController = RSKImageCropViewController(image: image)
        cropController.delegate = self
        
        picker.pushViewController(cropController, animated: true)
    }
    
    // MARK: - RSKImageCropViewControllerDelegate
    // Crop image has been canceled.
    func imageCropViewController(controller: RSKImageCropViewController!, didCropImage croppedImage: UIImage!) {
        self.imagePicker.dismissViewControllerAnimated(true, completion: nil)
        self.profileImageButton.setImage(croppedImage, forState: UIControlState.Normal)
        //self.profileImageButton.imageView!.image = croppedImage
        
        // convert profile image into a base64 string 
        let data: NSData = UIImagePNGRepresentation(croppedImage)
        self.user!.profileImage = data
        
        var error: NSError?
        if( !self.user!.managedObjectContext!.save(&error)) {
            println("ProfileViewControler: could not save profileImage: \(error?.localizedDescription)")
        }
        
        let base64String = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed)
        
        let chunks: [NSString] = divideString(base64String)
        
        // send the profile image to the server
        let serverRef = EKClient.userHomeURL?.childByAppendingPath("profileImage")
        serverRef?.setValue(chunks)
    }
    
    func imageCropViewControllerDidCancelCrop(controller: RSKImageCropViewController!) {
        self.imagePicker.popViewControllerAnimated(true)
    }
    
    // MARK: - UITableViewDelegate
    
//    func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
//        return true
//    }
//    
//    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
//        self.selectedStory = self.stories[indexPath.row]
//        self.performSegueWithIdentifier("FromCollectionToStory", sender: self)
//    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.stories.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: TitleCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("TitleCell", forIndexPath: indexPath) as TitleCollectionViewCell
     
        let story = self.stories[indexPath.row]
        
        cell.imageView.image = UIImage(named: "placeholder.png")
        cell.title.text = story.title
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedStory = self.stories[indexPath.row]
        self.performSegueWithIdentifier("FromCollectionToStory", sender: self)
    }
    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("TitleCell", forIndexPath: indexPath) as UITableViewCell
//        
//        let story: Story = self.stories[indexPath.row]
//        
//        cell.textLabel.text = story.title
//        
//        return cell
//    }
//    
//    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
//        
//        let story: Story = self.stories[indexPath.row]
//        
//        self.stories.removeAtIndex(indexPath.row)
//        self.coreContext.context.deleteObject(story)
//        
//        var error: NSError?
//        if (!self.coreContext.context.save(&error)) {
//                println("CollectionViewController: could not remove item from store")
//        }
//        
//        self.collectionView.reloadData()
//        //self.tableView.reloadData()
//    }
//    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return self.stories.count
//    }
//    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let destination: StoryViewController? = segue.destinationViewController as? StoryViewController
        
        if (destination != nil) {
            if (self.selectedStory != nil) {
                destination!.setStoryContent(self.selectedStory!.content)
                destination!.upperRightButton.title = "Edit"
                destination!.editable = false
            } else {
                destination!.storyContent = nil
                destination!.upperRightButton.title = "Save"
            }
        }
    }
    
    @IBAction func unwindToCollection(unwindSegue: UIStoryboardSegue) {
        self.loadManagedCollection()
        self.collectionView.reloadData()
        //self.tableView.reloadData()
    }
}
