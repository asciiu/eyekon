//
//  CircleViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/9/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit
import CoreData

class UserInfo {
    var id: String
    var email: String
    var name: String
    var profileImage: UIImage?
    
    init(id: String, email: String, name: String) {
        self.id = id
        self.email = email
        self.name = name
    }
}

class AddContactViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    var users: [UserInfo] = [UserInfo]()
    var selectedUsers: [UserInfo] = [UserInfo]()
    var post: Dictionary<String, String>?
    var context: NSManagedObjectContext?
    var coreContext: CoreContext = CoreContext()
    var contacts: [Contact] = [Contact]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.context = NSManagedObjectContext()
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context!.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
    }

    override func viewWillAppear(animated: Bool) {
        EKClient.usersURL.observeEventType(.Value, withBlock: { snapshot in
            
            let users = snapshot.children.allObjects as [FDataSnapshot]
            
            for user in users {
                
                if (user.key == EKClient.authData!.uid) {
                    continue
                }
                
                let email = user.value["email"] as String
                let first = user.value["first"] as String
                let last = user.value["last"] as String
                let name = first + " " + last
                
                let userInfo = UserInfo(id: user.key, email: email, name: name)
                
                let base64Image: NSString? = user.value["profileImage"] as? NSString
                
                if (base64Image != nil) {
                    
                    let data = NSData(base64EncodedString: base64Image!, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                    
                    let image = UIImage(data: data!)
                    userInfo.profileImage = image
                }
        
                let found = self.users.filter({ (user) -> Bool in
                    if (user.id == user.name) {
                        return true
                    }
                    return false
                })
                
                if (found.count == 0)  {
                    self.users.append(userInfo)
                }
            }
            self.tableView.reloadData()
        }, withCancelBlock: { error in
            println(error.description)
        })
        
        // fetch existing contacts from core data
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
        for user in self.selectedUsers {
            
            // filter the contacts array to see if the contact was already added
            let filter = self.contacts.filter({ (addedContact: Contact) -> Bool in
                if (addedContact.contactID == user.id) {
                    return true
                }
                return false
            })
            // if already added skip
            if (filter.count > 0) {
                continue
            }
            
            let contact = self.coreContext.createEntity("Contact") as Contact
            
            //let contact: Contact = NSEntityDescription.insertNewObjectForEntityForName("Contact", inManagedObjectContext: self.context!) as Contact
            
            contact.ownerID = EKClient.authData!.uid
            contact.contactID = user.id
            contact.name = user.name
            contact.email = user.email
            
            if (user.profileImage != nil) {
                contact.profileImage = UIImagePNGRepresentation(user.profileImage)
            }
            
            var error: NSError?
            if( !contact.managedObjectContext!.save(&error)) {
                println("could not save Contact: \(error?.localizedDescription)")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setPost(post: Dictionary<String, String>) {
        self.post = post
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: ContactTableViewCell = tableView.dequeueReusableCellWithIdentifier("ContactCell", forIndexPath: indexPath) as ContactTableViewCell
        
        //let story: Story = self.stories[indexPath.row]
        
        let userInfo = self.users[indexPath.row]
        cell.username.text = userInfo.name
        
        if (userInfo.profileImage != nil) {
            cell.profileImageView.image = userInfo.profileImage
        } else {
            cell.profileImageView.image = UIImage(named: "contact-default.png")
        }
        cell.imageView.layer.cornerRadius = cell.imageView.layer.frame.size.width/2
        cell.imageView.clipsToBounds = true
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        let type = cell?.accessoryType
        if (type == UITableViewCellAccessoryType.Checkmark) {
            cell?.accessoryType = UITableViewCellAccessoryType.None
            
            // remove selected user
            let userID = self.users[indexPath.row].id
            for (var i = 0; i < self.selectedUsers.count; ++i) {
                let user = self.selectedUsers[i]
                if (user.id == userID) {
                    self.selectedUsers.removeAtIndex(i)
                }
            }
        } else {
            self.selectedUsers.append(self.users[indexPath.row])
            cell?.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
    }
}
