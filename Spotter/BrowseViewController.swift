//
//  BrowseViewController.swift
//  Eyekon
//
//  Created by LV426 on 12/2/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class StoryInfo {
    var storyID: String
    var author: String
    var hashtag: String
    var titleImage: UIImage
    
    init(id: String, author: String, hashtag: String, image: UIImage) {
        self.storyID = id
        self.author = author
        self.hashtag = hashtag
        self.titleImage = image
    }
}

class BrowseViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var collectionView: UICollectionView!
    var stories: [StoryInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        EKClient.stories.observeEventType(.Value, withBlock: { snapshot in
            
            let stories = snapshot.children.allObjects as [FDataSnapshot]
            
            for story in stories {
                
                let storyID = story.name
                let author = story.value["author"] as String
                let hashtag = story.value["hashtag"] as String
                let base64Image = story.value["titleData"] as [NSString]
                
                var str = ""
                for chunk in base64Image {
                    str += chunk
                }
                
                let data = NSData(base64EncodedString: str, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let image = UIImage(data: data!)
                
                let storyInfo = StoryInfo(id: storyID, author: author, hashtag: hashtag, image: image!)
                self.stories.append(storyInfo)
            }
            
            self.collectionView.reloadData()
        }, withCancelBlock: { error in
            println(error.description)
        })
    }

    override func viewWillAppear(animated: Bool) {
        self.stories.removeAll(keepCapacity: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TitleCell", forIndexPath: indexPath) as TitleCollectionViewCell
        
        let storyInfo = self.stories[indexPath.item]
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
        cell.imageView.image = storyInfo.titleImage
        cell.title.text = storyInfo.hashtag
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.stories.count
    }
}
