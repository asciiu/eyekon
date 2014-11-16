//
//  CircleViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/9/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class CircleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    var users: [Dictionary<String, String>] = [Dictionary<String, String>]()
    var post: Dictionary<String, String>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        EKClient.usersURL.observeEventType(.Value, withBlock: { snapshot in
            
            let users = snapshot.children.allObjects as [FDataSnapshot]
            
            for user in users {
                
                if (user.name == EKClient.authData!.uid) {
                    continue
                }
                
                let email = user.value["email"] as String
                //println(user.name)
                let user: Dictionary<String, String> = ["id": user.name, "email": email];
                self.users.append(user)
            }
            self.tableView.reloadData()
        }, withCancelBlock: { error in
            println(error.description)
        })
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
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("ContactCell", forIndexPath: indexPath) as UITableViewCell
        
        //let story: Story = self.stories[indexPath.row]
        
        cell.textLabel.text = self.users[indexPath.row]["email"]
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let contact: Dictionary<String, String> = self.users[indexPath.row]
        EKClient.sendData(self.post!, toUserID: contact["id"]!)
    }
}
