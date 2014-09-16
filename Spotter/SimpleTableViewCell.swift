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
    @IBOutlet var annotationTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.addObserver(self, forKeyPath: "frame", options: NSKeyValueObservingOptions.Old, context: nil)
    }

    deinit {
        self.contentView.removeObserver(self, forKeyPath:"frame")
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        
        if ( keyPath == "frame" && object === self.contentView ) {
            let newFrame = self.contentView.frame
            let oldFrame = change[NSKeyValueChangeOldKey]?.CGRectValue()
            
            if ( newFrame.origin.x != 0 ) {
                self.contentView.frame = oldFrame!
            }
        }
    }
}
