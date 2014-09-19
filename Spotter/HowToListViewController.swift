//
//  HowToListViewController.swift
//  Spotter
//
//  Created by LV426 on 8/27/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class HowToListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var context: NSManagedObjectContext?
    var frameSets: [FrameSet] = [FrameSet]()
    
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.allowsMultipleSelectionDuringEditing = false
        
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
        
        self.loadManagedCollection()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    func loadManagedCollection() {
        
        let entityDesc: NSEntityDescription? = NSEntityDescription.entityForName("FrameSet", inManagedObjectContext: self.context!)
        
        // create a fetch request with the entity description
        // this works like a SQL SELECT statement
        let request: NSFetchRequest = NSFetchRequest()
        request.entity = entityDesc!
        
        var error: NSError?
        
        self.frameSets = self.context!.executeFetchRequest(request, error: &error) as [FrameSet]
        
//        if self.frameSets.count == 0 {
//            println("Empty List")
//        }
    }

    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        SharedDataFrameSet.dataFrameSet = self.frameSets[indexPath.row]
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("CollectionCell", forIndexPath: indexPath) as UITableViewCell
        
        let frameSet: FrameSet = self.frameSets[indexPath.row]
        
        cell.textLabel?.text = frameSet.title
        
        return cell
    }
    
    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        
        let frameSet: FrameSet = self.frameSets[indexPath.row]
        
        self.frameSets.removeAtIndex(indexPath.row)
        self.context!.deleteObject(frameSet)
        
        var error: NSError?
        if (!self.context!.save(&error)) {
                println("HowToViewController: could not remove item from store")
        }
        
        self.tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.frameSets.count
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        // if storyboard FroCollectinoToCapture segue then we are going to
        // create a new dataFrameSet
        if (segue.identifier == "FromCollectionToCapture") {
            // set the shared data frame set to nil
            SharedDataFrameSet.dataFrameSet = nil
        }
    }
    
    @IBAction func unwindToCollection(unwindSegue: UIStoryboardSegue) {
        self.loadManagedCollection()
    }
}
