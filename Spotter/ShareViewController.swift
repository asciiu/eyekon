//
//  ShareViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/18/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class ShareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    
    var contacts: [Contact] = [Contact]()
    var selectedContacts: [Contact] = []
    let coreContext: CoreContext = CoreContext()
    
    var storyInfo: (String, String)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
            
        let entityDesc: NSEntityDescription? = NSEntityDescription.entityForName("Contact", inManagedObjectContext: self.coreContext.context)
        
        // create a fetch request with the entity description
        // this works like a SQL SELECT statement
        let request: NSFetchRequest = NSFetchRequest()
        request.entity = entityDesc!
        
        let pred: NSPredicate = NSPredicate(format:"(ownerID = %@)", EKClient.authData!.uid)!
        request.predicate = pred
        
        var error: NSError?
        self.contacts = self.coreContext.context.executeFetchRequest(request, error: &error) as [Contact]
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        for contact in self.selectedContacts {
            let username = contact.name
            let userID = contact.contactID
            
            if (self.storyInfo != nil) {
                let (storyID, hashtag) = self.storyInfo!
                
                let userStories = EKClient.appRef.childByAppendingPath("user-stories").childByAppendingPath(userID).childByAppendingPath(storyID)
                userStories.setValue(["hashtag": hashtag])
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        let cell = self.tableView.dequeueReusableCellWithIdentifier("ContactCell", forIndexPath: indexPath) as ContactTableViewCell
        let contact = self.contacts[indexPath.row]
        
        cell.username.text = contact.name
        
        if (contact.profileImage != nil) {
            cell.profileImageView.image = UIImage(data: contact.profileImage!)
        }
   
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        let type = cell?.accessoryType
        if (type == UITableViewCellAccessoryType.Checkmark) {
            cell?.accessoryType = UITableViewCellAccessoryType.None
            
            // remove selected user
            let userID = self.contacts[indexPath.row].contactID
            for (var i = 0; i < self.selectedContacts.count; ++i) {
                let user = self.selectedContacts[i]
                if (user.contactID == userID) {
                    self.selectedContacts.removeAtIndex(i)
                }
            }
        } else {
            self.selectedContacts.append(self.contacts[indexPath.row])
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
