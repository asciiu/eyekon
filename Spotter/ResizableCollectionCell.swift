//
//  MIView.swift
//  Eyekon
//
//  Created by LV426 on 10/15/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

enum DraggableDirection: Int {
    case Horizontal = 0
    case Vertical = 1
    case HorizontalAndVertical = 3
}

class DraggableHandle: UIView {
    
    var refPoint: CGPoint = CGPointZero
    let direction: DraggableDirection = DraggableDirection.Vertical
    
    let panGesture: UIPanGestureRecognizer?
    weak var cell: ResizeableCollectionCell?
    
    var minPadding: CGFloat = 10
    
    init(frame: CGRect, cell: ResizeableCollectionCell, resizeDirection: DraggableDirection) {
        self.cell = cell
        self.direction = resizeDirection
        
        super.init(frame: frame)
        
        
        self.backgroundColor = UIColor.blackColor()
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: "handlePan:")
        self.addGestureRecognizer(self.panGesture!)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        switch (gestureRecognizer.state) {
        case UIGestureRecognizerState.Began:
            // When resizing, all calculations are done in the superview's coordinate space.
            self.refPoint = gestureRecognizer.locationInView(self.superview)
            self.cell!.contentView.autoresizesSubviews = true
            
            break
        case UIGestureRecognizerState.Changed:
            let touchLocation = gestureRecognizer.locationInView(self.superview)
            let deltaX = touchLocation.x - self.refPoint.x
            let deltaY = touchLocation.y - self.refPoint.y
            let maxWidth = self.cell!.maxWidth
            let cellSize = self.cell!.frame.size

            if (self.direction == DraggableDirection.Horizontal) {
                var newWidth = cellSize.width + deltaX
                
                if (newWidth > self.cell!.maxWidth) {
                    newWidth = self.cell!.maxWidth
                } else if (newWidth < self.cell!.minimumSize.width) {
                    newWidth = self.cell!.minimumSize.width
                }
                
                self.cell!.frame.size.width = newWidth

            } else if (self.direction == DraggableDirection.Vertical){
                var newHeight = cellSize.height + deltaY
                
                if (newHeight < self.cell!.minimumSize.height) {
                    newHeight = self.cell!.minimumSize.height
                }
                
                self.cell!.frame.size.height = newHeight
                
            } else {
                self.cell!.frame.size = CGSizeMake(cellSize.width + deltaX, cellSize.height + deltaY)
            }
            
            (self.cell!.superview as UICollectionView).performBatchUpdates({ () -> Void in
                (self.cell!.superview as UICollectionView).collectionViewLayout.invalidateLayout()
                }, completion: { (fin:Bool) -> Void in
                
            })
            
            self.refPoint = touchLocation
            break
        case UIGestureRecognizerState.Ended:
            //self.cell!.contentView.autoresizesSubviews = false

            break
        default:
            // Do nothing...
            break
        }
    }
}

class ResizeableCollectionCell: UICollectionViewCell  {
    
    var minimumSize: CGSize = CGSizeMake(100, 100)
    var maxWidth: CGFloat = 100
    
    let rightHandle: DraggableHandle?
    let bottomHandle: DraggableHandle?
    let cornerHandle: DraggableHandle?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let height = self.frame.size.height
        let width = self.frame.size.width
        let hDim: CGFloat = 40.0
        
        self.bottomHandle = DraggableHandle(frame: CGRectMake(0, 0, hDim, hDim),
            cell: self, resizeDirection: DraggableDirection.Vertical)
        self.bottomHandle!.center = CGPointMake(width/2, height)
        self.bottomHandle!.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin |
            UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin
        self.addSubview(self.bottomHandle!)
        
        self.rightHandle = DraggableHandle(frame: CGRectMake(0, 0, hDim, hDim),
            cell: self, resizeDirection: DraggableDirection.Horizontal)
        self.rightHandle!.center = CGPointMake(width, height/2)
        self.rightHandle!.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin |
            UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleBottomMargin
        self.addSubview(self.rightHandle!)
        
        self.cornerHandle = DraggableHandle(frame: CGRectMake(0, 0, hDim, hDim),
            cell: self, resizeDirection: DraggableDirection.HorizontalAndVertical)
        self.cornerHandle!.center = CGPointMake(width, height)
        self.cornerHandle!.autoresizingMask = UIViewAutoresizing.FlexibleTopMargin |
            UIViewAutoresizing.FlexibleLeftMargin
        self.addSubview(self.cornerHandle!)
    }
}
