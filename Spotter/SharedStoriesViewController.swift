//
//  SharedStoriesViewController.swift
//  Eyekon
//
//  Created by LV426 on 11/20/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class SharedStoriesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    
    let coreContext: CoreContext = CoreContext()
    var sharedStories: [Story] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        let userStories = EKClient.userStories.childByAppendingPath(EKClient.authData?.uid)
        userStories.observeEventType(FEventType.Value, withBlock: { (data: FDataSnapshot!) -> Void in
            if (data.value === NSNull()) {
                return
            }
            let stories = data.children.allObjects as [FDataSnapshot]
            
            for story in stories {
                let storyID = story.key
                let title = story.value["hashtag"] as NSString
                
                let coreStory = self.coreContext.createEntity("Story") as Story
                coreStory.title = title
                coreStory.storyID = storyID
                coreStory.summary = "empty"
                coreStory.uid = EKClient.authData!.uid
                
                let filtered = self.sharedStories.filter({ (s) -> Bool in
                    if (s.storyID == storyID) {
                        return true
                    }
                    return false
                })
                
                if (filtered.count == 0) {
                    self.sharedStories.append(coreStory)
                }
            }
            
            self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sharedStories.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("CollectionCell", forIndexPath: indexPath) as UITableViewCell
        
        let story: Story = self.sharedStories[indexPath.row]
        
        cell.textLabel!.text = story.title
        
        return cell
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
