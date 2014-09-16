//
//  SimpleTableViewCell.swift
//  Spotter
//
//  Created by LV426 on 9/16/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class SimpleTableViewCell: UITableViewCell {

    @IBOutlet var mainImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.contentView.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.Old, context: nil)
    }

    deinit {
        self.contentView.removeObserver(self, forKeyPath:"frame")
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        
        //NSLog(@"observed value for kp %@ changed: %@",keyPath,change);
        if ( keyPath == "frame" && object === self.contentView ) {
            let newFrame = self.contentView.frame
            let oldFrame = change[NSKeyValueChangeOldKey]?.CGRectValue()
            
            //NSLog(@"frame old: %@  new: %@",NSStringFromCGRect(oldFrame),NSStringFromCGRect(newFrame));
        
            println(newFrame.origin.x)
            if ( newFrame.origin.x != 0 ) {
                self.contentView.frame = oldFrame!
            }
        }
    }
}
