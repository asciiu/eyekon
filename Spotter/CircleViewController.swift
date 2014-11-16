//
//  CircleViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/9/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

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

class CircleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    var users: [UserInfo] = [UserInfo]()
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
                let first = user.value["first"] as String
                let last = user.value["last"] as String
                let name = first + " " + last
                
                let userInfo = UserInfo(id: user.name, email: email, name: name)
                
                let base64Image: NSString? = user.value["profileImage"] as? NSString
                
                if (base64Image != nil) {
                    let data = NSData(base64EncodedString: base64Image!, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                    
                    let image = UIImage(data: data!)
                    userInfo.profileImage = image
                }

        
                //println(user.name)
                self.users.append(userInfo)
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
        //let contact: Dictionary<String, String> = self.users[indexPath.row]
        //EKClient.sendData(self.post!, toUserID: contact["id"]!)
    }
}
