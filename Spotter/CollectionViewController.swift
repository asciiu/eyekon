//
//  HowToListViewController.swift
//  Spotter
//
//  Created by LV426 on 8/27/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class CollectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var context: NSManagedObjectContext?
    var stories: [Story] = [Story]()
    var selectedStory: Story?
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadManagedCollection()
        self.tableView.reloadData()
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
        
        cell.textLabel?.text = story.title
        
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
