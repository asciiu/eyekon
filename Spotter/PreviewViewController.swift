//
//  PreviewViewController.swift
//  Spotter
//
//  Created by LV426 on 9/11/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    
    var segments: [UIImage]?
    var segmentIndex: Int?
    var segmentViews: [UIImageView] = [UIImageView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.userInteractionEnabled = true
        
        let swipeLeft: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipe:")
        let swipeRight: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "handleSwipe:")
       
         // Setting the swipe direction.
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        
        // Adding the swipe gesture on image view
        self.view.addGestureRecognizer(swipeLeft)
        self.view.addGestureRecognizer(swipeRight)
        
        self.view.clipsToBounds = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.segmentIndex = 0
        self.imageView.image = self.segments![0]
        
        let origin = self.imageView.frame.origin
        let frameWidth = self.imageView.frame.width
        let originalWidth = self.segments![0].size.width
        let originalHeight = self.segments![0].size.height
        
        let height = frameWidth * originalHeight / originalWidth
        self.imageView.frame = CGRectMake(origin.x, origin.y, frameWidth, height)
        
        //self.imageView.frame = CGRectMake(origin.x, origin.y, originalWidth, originalHeight)
//        float oldWidth = sourceImage.size.width;
//        float scaleFactor = i_width / oldWidth;
//        
//        float newHeight = sourceImage.size.height * scaleFactor;
//        float newWidth = oldWidth * scaleFactor;
//        
//        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
//        [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
//        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//        return newImage;
        
        self.segmentViews.removeAll(keepCapacity: false)
        self.segmentViews.append(self.imageView)
        
        let viewFrame = self.imageView.frame
        
        for (var i = 1; i < self.segments!.count; ++i) {
            let imageWidth = self.segments![i].size.width
            let imageHeight = self.segments![i].size.height
            let frameHeight = frameWidth * imageHeight / imageWidth
            
            let imageView: UIImageView = UIImageView(image: self.segments![i])
            imageView.frame = CGRectMake(frameWidth, origin.y, frameWidth, frameHeight)
            
            self.view.addSubview(imageView)
            self.segmentViews.append(imageView)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleSwipe(swipe: UISwipeGestureRecognizer) {
    
        if swipe.direction == UISwipeGestureRecognizerDirection.Left {
            
            if self.segmentIndex! < self.segments!.count - 1 {
                
                let imageView1 = self.segmentViews[self.segmentIndex!++]
                let imageView2 = self.segmentViews[self.segmentIndex!]
                
                UIView.animateWithDuration(0.25,
                    animations: {
                        
                        imageView1.frame = CGRectMake(-imageView1.frame.width, imageView1.frame.origin.y, imageView1.frame.width, imageView1.frame.height)
                        imageView2.frame = CGRectMake(0, imageView2.frame.origin.y, imageView2.frame.width, imageView2.frame.height)

                    }, completion: { (value: Bool) in
                        
                })
            }
        }
        
        if swipe.direction == UISwipeGestureRecognizerDirection.Right {
            
            if self.segmentIndex! > 0 {
                
                let imageView1 = self.segmentViews[self.segmentIndex!--]
                let imageView2 = self.segmentViews[self.segmentIndex!]
                
                UIView.animateWithDuration(0.25,
                    animations: {
                        
                        imageView1.frame = CGRectMake(imageView1.frame.width, imageView1.frame.origin.y, imageView1.frame.width, imageView1.frame.height)
                        imageView2.frame = CGRectMake(0, imageView2.frame.origin.y, imageView2.frame.width, imageView2.frame.height)
                        
                    }, completion: { (value: Bool) in
                        
                })
            }
        }
    }
    
    
    // MARK: - Actions
    @IBAction func publish(sender: AnyObject) {
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
//        let publishController: PublishViewController? = segue.destinationViewController as? PublishViewController
//        
//        if publishController != nil {
//            publishController!.segments = self.segments
//            //destinationController!.imageView.image = self.capturedImages[0]
//        }
        
    }
    

}
