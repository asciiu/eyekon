//
//  MIView.swift
//  Eyekon
//
//  Created by LV426 on 10/15/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

enum ResizeDirection: Int {
    case Horizontal = 0
    case Vertical = 1
}

@objc protocol MIDelegate {
    optional func resized(indexPath: NSIndexPath)
}

@objc protocol ResizeButtonDelegate {
    optional func view(view: UIView, didResize: CGSize)
}

class ResizeButton: UIView {
    
    var nipple: UIView?
    var refPoint: CGPoint = CGPointZero
    let panGesture: UIPanGestureRecognizer?
    let tapGesture: UITapGestureRecognizer?
    var views: [UIView] = [UIView]()
    var direction: ResizeDirection = ResizeDirection.Horizontal
    var tableView: UITableView?
    var delegate: ResizeButtonDelegate?
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        //self.backgroundColor = UIColor.blackColor()
        //nipple = UIView(frame: CGRectMake(0, 0, 5, 5))
        //nipple!.backgroundColor = UIColor.redColor()
        
        //nipple!.center = CGPointMake(frame.size.height/2, frame.size.width/2)
        //self.addSubview(nipple!)
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: "handlePan:")
        self.addGestureRecognizer(self.panGesture!)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resizeHorizontal(deltaX: CGFloat) {
        if (self.views.count > 0) {
            let view1 = self.views[0]
            
            let frame1 = view1.frame
            view1.frame = CGRectMake(frame1.origin.x, frame1.origin.y, frame1.size.width+deltaX, frame1.size.height)
            //view1.frame.size.width += deltaX
            
            let view2 = self.views[1]
            view2.frame.origin.x += deltaX
            view2.frame.size.width -= deltaX
        }
        
        self.center = CGPointMake(self.center.x + deltaX, self.center.y)
    }
    
    func resizeVertical(deltaY: CGFloat) {
        let view = self.views[0]
        let frame = view.frame
        let origin = view.frame.origin
        let size = view.frame.size
        let newSize = CGSizeMake(size.width, size.height+deltaY)
        
        view.autoresizesSubviews = true
        view.frame = CGRectMake(origin.x, origin.y, newSize.width, newSize.height)
        view.autoresizesSubviews = false
        
        self.center = CGPointMake(self.center.x, self.center.y+deltaY)
        self.delegate?.view?(view, didResize: newSize)
    }
    
    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        switch (gestureRecognizer.state) {
        case UIGestureRecognizerState.Began:
            // When resizing, all calculations are done in the superview's coordinate space.
            self.refPoint = gestureRecognizer.locationInView(self.superview)
            
            break
        case UIGestureRecognizerState.Changed:
            let touchLocation = gestureRecognizer.locationInView(self.superview)
            let point = gestureRecognizer.locationInView(self.superview)
            
            if (self.direction == ResizeDirection.Horizontal) {
                let deltaX = point.x - self.refPoint.x
                self.resizeHorizontal(deltaX)
            } else {
                let deltaY = point.y - self.refPoint.y
                self.resizeVertical(deltaY)
            }
            
            self.refPoint = point
            break
        case UIGestureRecognizerState.Ended:
            break
        default:
            // Do nothing...
            break
        }
    }
}


class MIView: UIView, ResizeButtonDelegate {
    
    var views: [UIImageView] = [UIImageView]()
    var resizeHandles: [ResizeButton] = [ResizeButton]()
    var cellSpacing: CGFloat = 0
    var delegate: MIDelegate?
    var indexPath: NSIndexPath?
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //self.backgroundColor = UIColor.whiteColor()
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

        let height: CGFloat = totalWidth / r
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
    
    func enableResize() {
        
        for view in self.resizeHandles {
            view.removeFromSuperview()
        }
        self.resizeHandles.removeAll(keepCapacity: true)
        
        let height = self.frame.size.height
        let y = height/2
        var x: CGFloat = 0
        
        for (var i = 0; i < self.views.count; ++i) {
            let view = self.views[i] as UIView
            view.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        
            if (i < self.views.count-1) {
                x += view.frame.size.width + (self.cellSpacing * CGFloat(i))

                let resizeBtn = ResizeButton(frame: CGRectMake(0, 0, 50, 100))
                resizeBtn.autoresizingMask = UIViewAutoresizing.FlexibleBottomMargin | UIViewAutoresizing.FlexibleTopMargin
                
                resizeBtn.center = CGPointMake(x+self.cellSpacing/2, y)
                resizeBtn.views.append(view)
                resizeBtn.views.append(self.views[i+1] as UIView)
                
                self.addSubview(resizeBtn)
                self.resizeHandles.append(resizeBtn)
            }
        }
        let verticalBtn = ResizeButton(frame: CGRectMake(0, 0, 100, 50))
        verticalBtn.direction = ResizeDirection.Vertical
        verticalBtn.center = CGPointMake(self.frame.size.width/2, height + self.cellSpacing/2)
        verticalBtn.views.append(self)
        verticalBtn.delegate = self
        self.addSubview(verticalBtn)
        self.resizeHandles.append(verticalBtn)
    }
    
    
    func subviewCount() -> Int {
        return self.views.count
    }
    
    func view(view: UIView, didResize: CGSize) {
        self.delegate?.resized?(self.indexPath!)
    }
}
