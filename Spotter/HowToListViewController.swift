//
//  HowToListViewController.swift
//  Spotter
//
//  Created by LV426 on 8/27/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class HowToListViewController: UIViewController, UITableViewDataSource {

    var context: NSManagedObjectContext?
    var frameSets: [FrameSet] = [FrameSet]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        
        self.context = appDelegate.managedObjectContext
        self.loadList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindToList(unwindSegue: UIStoryboardSegue) {
        println("Canceled Creation")
        self.loadList()
    }
    
    func loadList() {
        let entityDesc: NSEntityDescription = NSEntityDescription.entityForName("FrameSet", inManagedObjectContext: self.context!)
        
        // create a fetch request with the entity description
        // this works like a SQL SELECT statement
        let request: NSFetchRequest = NSFetchRequest()
        request.entity = entityDesc
        
        var error: NSError?
        self.frameSets = self.context!.executeFetchRequest(request, error: &error) as [FrameSet]
        
        if self.frameSets.count == 0 {
            println("Empty List")
        }
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return self.frameSets.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("ListPrototypeCell", forIndexPath: indexPath) as UITableViewCell
    
        let frameSet: FrameSet = self.frameSets[indexPath.row]
        cell.textLabel.text = frameSet.synopsis
        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
