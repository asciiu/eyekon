//
//  HowToListViewController.swift
//  Spotter
//
//  Created by LV426 on 8/27/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate {

    var context: NSManagedObjectContext?
    var stories: [Story] = [Story]()
    var selectedStory: Story?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var profileImageButton: UIButton!
    
    let imagePicker: UIImagePickerController = UIImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        
        self.profileImageButton.layer.cornerRadius = self.profileImageButton.layer.frame.size.width/2
        self.profileImageButton.clipsToBounds = true
        self.profileImageButton.layer.borderWidth = 1.0
        self.profileImageButton.layer.borderColor = UIColor.grayColor().CGColor
        self.profileImageButton.imageView!.contentMode = UIViewContentMode.ScaleAspectFill
        
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.usernameLabel.text = ""
        
        EKClient.userHomeURL?.observeEventType(FEventType.Value, withBlock: { (data:FDataSnapshot!) -> Void in
            if (data.value === NSNull()) {
                return
            }
            
            let first: NSString = data.value["first"] as NSString
            let last: NSString = data.value["last"] as NSString
            self.usernameLabel.text = first + " " + last

            let base64Image: NSString? = data.value["profileImage"] as? NSString
            
            if (base64Image != nil) {
                let data = NSData(base64EncodedString: base64Image!, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                
                let image = UIImage(data: data!)
                self.profileImageButton.setImage(image, forState: UIControlState.Normal)
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadManagedCollection()
        self.tableView.reloadData()
        
        //self.usernameLabel.text = EKClient.username
        
        self.navigationItem.rightBarButtonItem?.title = "Logout"
        
//        let postURL = url + "/users/" + EKClient.authData!.uid + "/posts"
//        let ref = Firebase(url: postURL)
//
        EKClient.userPostsRef?.observeEventType(FEventType.Value, withBlock: { (data:FDataSnapshot!) -> Void in
            
            if (data.value === NSNull()) {
                return
            }
            
            let hashtag: NSString = data.value["hashtag"] as NSString
            let base64: NSString = data.value["packet"] as NSString
            
            let data = NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
            
            let story: Story = NSEntityDescription.insertNewObjectForEntityForName("Story", inManagedObjectContext: self.context!) as Story
            story.title = hashtag
            story.summary = "Summary"
            
            let content = NSEntityDescription.insertNewObjectForEntityForName("StoryContent", inManagedObjectContext: self.context!) as StoryContent
            
            story.content = content
            content.story = story
            content.data = data

            //var error: NSError?
            //if( content.managedObjectContext!.save(&error)) {
            //    println("could not save story: \(error?.localizedDescription)")
            //} else {
                self.stories.append(story)
                self.tableView.reloadData()
            //}
            
            //self.cubes = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as NSMutableArray
            
            //println(self.cubes.count)
            //self.tableView.reloadData()
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    

    
    func loadManagedCollection() {
        
        let entityDesc: NSEntityDescription? = NSEntityDescription.entityForName("Story", inManagedObjectContext: self.context!)
        
        // create a fetch request with the entity description
        // this works like a SQL SELECT statement
        let request: NSFetchRequest = NSFetchRequest()
        request.entity = entityDesc!
        
        var error: NSError?
        
        self.stories = self.context!.executeFetchRequest(request, error: &error) as [Story]
    }
    
    // MARK: - Actions
    @IBAction func addStory(sender: AnyObject) {
        self.selectedStory = nil
        self.performSegueWithIdentifier("FromCollectionToStory", sender: self)
    }
    
    @IBAction func logout(sender: AnyObject) {
        EKClient.logout()
        self.navigationController?.popToRootViewControllerAnimated(true)
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
        self.profileImageButton.imageView!.image = croppedImage
        
        // convert profile image into a base64 string 
        let data = UIImagePNGRepresentation(croppedImage)
        let base64Image = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed)
        
        // send the profile image to the server
        let serverRef = EKClient.userHomeURL?.childByAppendingPath("profileImage")
        serverRef?.setValue(base64Image)
    }
    
    func imageCropViewControllerDidCancelCrop(controller: RSKImageCropViewController!) {
        self.imagePicker.popViewControllerAnimated(true)
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        self.selectedStory = self.stories[indexPath.row]
        self.performSegueWithIdentifier("FromCollectionToStory", sender: self)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("CollectionCell", forIndexPath: indexPath) as UITableViewCell
        
        let story: Story = self.stories[indexPath.row]
        
        cell.textLabel.text = story.title
        
        return cell
    }
    
    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        
        let story: Story = self.stories[indexPath.row]
        
        self.stories.removeAtIndex(indexPath.row)
        self.context!.deleteObject(story)
        
        var error: NSError?
        if (!self.context!.save(&error)) {
                println("CollectionViewController: could not remove item from store")
        }
        
        self.tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.stories.count
    }
    
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
        self.tableView.reloadData()
    }
}
