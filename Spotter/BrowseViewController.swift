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
    var authorID: String
    var hashtag: String
    var thumbnail: UIImage
    var summary: String
    var cubeCount: Int
    var s3Bucket: String
    
    init(storyID: String, authorID: String, hashtag: String,
        summary: String, thumbnail: UIImage, cubeCount: Int, s3Bucket: String) {
        self.storyID = storyID
        self.authorID = authorID
        self.hashtag = hashtag
        self.thumbnail = thumbnail
        self.summary = summary
        self.cubeCount = cubeCount
        self.s3Bucket = s3Bucket
    }
}

class BrowseViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var collectionView: UICollectionView!
    var stories: [StoryInfo] = []
    var selectedStoryInfo: StoryInfo?
    var firebaseRef: UInt?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        if (!animated) {
            self.populateStories()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        EKClient.stories.removeObserverWithHandle(self.firebaseRef!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func populateStories() {
        self.stories.removeAll(keepCapacity: false)
        self.collectionView.reloadData()
        
        self.firebaseRef = EKClient.stories.observeEventType(.Value, withBlock: { snapshot in
            
            let stories = snapshot.children.allObjects as [FDataSnapshot]
            
            for story in stories {
                
                let storyID = story.name
                let authorID = story.value["authorID"] as String
                let hashtag = story.value["hashtag"] as String
                let summary = story.value["summary"] as String
                let cubeCount = story.value["cubeCount"] as Int
                let base64Str = story.value["thumbnailStr"] as String
                let bucket = story.value["s3Bucket"] as String
                
//                var compressedStr = ""
//                for chunk in base64Compressed! {
//                    compressedStr += chunk
//                }
                
                var error: NSError?
                let compressedData = NSData(base64EncodedString: base64Str,
                    options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let data = BZipCompression.decompressedDataWithData(compressedData, error:&error)
                
                if (error != nil) {
                    println("BrowseViewController could not inflate thumbnail: \(error)")
                    return
                }
                    
                let thumbnail = UIImage(data: data)!
                
                let storyInfo = StoryInfo(storyID: storyID, authorID: authorID,
                    hashtag: hashtag, summary: summary, thumbnail: thumbnail,
                    cubeCount: cubeCount, s3Bucket: bucket)
                
                let index = NSIndexPath(forItem: self.stories.count, inSection: 0)
                
//                let found = self.stories.filter({ (info: StoryInfo) -> Bool in
//                    if (info.storyID == storyInfo.storyID) {
//                        return true
//                    }
//                    return false
//                })
                
                //if (found.count == 0) {
                    self.stories.append(storyInfo)
                    self.collectionView.insertItemsAtIndexPaths([index])
                //}
            }
        })
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "FromBrowseToStory") {
            let destination = segue.destinationViewController as StoryViewController
            destination.setStoryInfo(self.selectedStoryInfo!)
        }
    }


    // MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TitleCell", forIndexPath: indexPath) as TitleCollectionViewCell
        
        let storyInfo = self.stories[indexPath.item]
        cell.imageView.contentMode = UIViewContentMode.ScaleAspectFill
        cell.imageView.image = storyInfo.thumbnail
        cell.title.text = storyInfo.hashtag
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.stories.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        self.selectedStoryInfo = self.stories[indexPath.item]
        self.performSegueWithIdentifier("FromBrowseToStory", sender: self)
    }
}
