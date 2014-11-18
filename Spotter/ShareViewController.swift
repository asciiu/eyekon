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
    let coreContext: CoreContext = CoreContext()
    
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
