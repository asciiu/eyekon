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
    
    //var nipple: UIView?
    var refPoint: CGPoint = CGPointZero
    let panGesture: UIPanGestureRecognizer?
    let tapGesture: UITapGestureRecognizer?
    var views: [UIView] = [UIView]()
    var direction: ResizeDirection = ResizeDirection.Horizontal
    //var tableView: UITableView?
    var delegate: ResizeButtonDelegate?
    weak var parentView: MIView?
    
    var minPadding: CGFloat = 10
    
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
        super.init()
        // do nothing
        //fatalError("init(coder:) has not been implemented")
    }
    
    func resizeHorizontal(deltaX: CGFloat) {
        if (self.views.count > 0) {
            let view1 = self.views[0]
            let view2 = self.views[1]
            let frame1 = view1.frame
            let frame2 = view2.frame
            
            if (frame1.size.width + deltaX < self.frame.size.width ||
                frame2.size.width - deltaX < self.frame.size.width) {
                return
            }
            
            view1.frame.size.width += deltaX
            view2.frame.origin.x += deltaX
            view2.frame.size.width -= deltaX
            
            self.center = CGPointMake(self.center.x + deltaX, self.center.y)
        }
    }
    
    func resizeVertical(deltaY: CGFloat) {
        let view = self.views[0]
        let frame = view.frame
        let origin = view.frame.origin
        let size = view.frame.size
        let newSize = CGSizeMake(size.width, size.height+deltaY)
        
        if (newSize.height < self.frame.size.height) {
            return
        }
        
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
            
            if (self.direction == ResizeDirection.Horizontal) {
                let view1 = self.views[0]
                let view2 = self.views[1]
                
                if (view1.frame.size.width < self.parentView!.minimumSize.width) {
                    let delta = self.parentView!.minimumSize.width - view1.frame.size.width
                    self.resizeHorizontal(delta)
                } else if (view2.frame.size.width < self.parentView!.minimumSize.width) {
                    let delta = self.parentView!.minimumSize.width - view2.frame.size.width
                    self.resizeHorizontal(-delta)
                }
            } else {
                let view = self.views[0]
                if (view.frame.size.height < self.parentView!.minimumSize.height) {
                    
                    let delta = self.parentView!.minimumSize.height - view.frame.size.height
                    self.resizeVertical(delta)
                    
                }
            }
            break
        default:
            // Do nothing...
            break
        }
    }
}


class MIView: UIView, NSCoding, ResizeButtonDelegate  {
    
    var views: NSMutableArray = NSMutableArray()
    var resizeHandles: [ResizeButton] = [ResizeButton]()
    var cellSpacing: CGFloat = 0
    var delegate: MIDelegate?
    var indexPath: NSIndexPath?
    var minimumSize: CGSize = CGSizeMake(50, 50)
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.views = aDecoder.decodeObjectForKey("views") as NSMutableArray
        self.cellSpacing = CGFloat(aDecoder.decodeFloatForKey("spacing"))
        
        for (var i = 0; i < self.views.count; ++i) {
            let view = self.views.objectAtIndex(i) as UIImageView
            self.addSubview(view)
        }
        
        //aDecoder.decode)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //self.backgroundColor = UIColor.whiteColor()
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        
        // we do not want these to be encoded
        self.removeResizeViews()
        
        super.encodeWithCoder(aCoder)
        
        for (var i = 0; i < self.views.count; ++i) {
            let imageView = self.views.objectAtIndex(i) as UIImageView
            imageView.highlighted = false
        }
        
        aCoder.encodeObject(self.views, forKey: "views")
        aCoder.encodeFloat(Float(self.cellSpacing), forKey: "spacing")
    }
    
    func addImageView(view: UIImageView) {
        views.addObject(view)
        self.addSubview(view)

        var images: [UIImage] = [UIImage]()
        for (var i = 0; i < self.views.count; ++i) {
            let imageView = self.views.objectAtIndex(i) as UIImageView
            images.append(imageView.image!)
        }
        
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
            
            let iv = self.views[j] as UIImageView
            
            iv.frame = rect
        }
    }
    
    func removeSubviews() {
        for view in self.views {
            view.removeFromSuperview()
        }
        views.removeAllObjects()
        //views.removeAll(keepCapacity: false)
    }
    
    func removeResizeViews() {
        for view in self.resizeHandles {
            view.removeFromSuperview()
        }
    }
    
    func removeImageView(imageView: UIImageView) {
        
        for (var i = 0; i < self.views.count; ++i) {
            if (self.views[i] === imageView) {
                self.views[i].removeFromSuperview()
                self.views.removeObjectAtIndex(i)
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
                resizeBtn.parentView = self
                
                self.addSubview(resizeBtn)
                self.resizeHandles.append(resizeBtn)
            }
        }
        let verticalBtn = ResizeButton(frame: CGRectMake(0, 0, 100, 50))
        verticalBtn.direction = ResizeDirection.Vertical
        verticalBtn.center = CGPointMake(self.frame.size.width/2, height + self.cellSpacing/2)
        verticalBtn.views.append(self)
        verticalBtn.delegate = self
        verticalBtn.parentView = self
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
