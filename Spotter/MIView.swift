//
//  MIView.swift
//  Eyekon
//
//  Created by LV426 on 10/15/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class MIView: UIView {
    
    //let views: NSMutableArray = NSMutableArray()
    var views: [UIImageView] = [UIImageView]()
    var cellSpacing: CGFloat = 0
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
    }
    
    func addImageView(view: UIImageView) {
        views.append(view)
        self.addSubview(view)

        let images: [UIImage] = self.views.map{ (var imageView) -> UIImage in return imageView.image! }
        
        let frameWidth = self.frame.width
        let imageCount = images.count
        let totalWidth = frameWidth - (self.cellSpacing * (CGFloat(imageCount)-1))

        var r: CGFloat = 0
        for(var i = 0; i < imageCount; ++i) {
            let image = images[i]
            r += image.size.width / image.size.height
        }

        let height: CGFloat = CGFloat(floorf(Float(totalWidth / r)))
        self.frame.size.height = height

        var x: CGFloat = 0.0
        for(var j = 0; j < imageCount; ++j) {
            let image = images[j]
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            let width = height * imageWidth / imageHeight
            let rect = CGRectMake(x, 0, width, height)
            
            x += width + self.cellSpacing
            
            let iv = self.views[j]
            
            iv.frame = rect
        }
    }
    
    func removeSubviews() {
        for view in self.views {
            view.removeFromSuperview()
        }
        views.removeAll(keepCapacity: false)
    }
    
    func removeImageView(imageView: UIImageView) {
        
        for (var i = 0; i < self.views.count; ++i) {
            if (self.views[i] === imageView) {
                self.views[i].removeFromSuperview()
                self.views.removeAtIndex(i)
            }
        }
    }
    
    func subviewCount() -> Int {
        return self.views.count
    }
}
