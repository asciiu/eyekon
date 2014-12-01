//
//  TripletFlowLayout.swift
//  Eyekon
//
//  Created by LV426 on 12/1/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class TripletFlowLayout: UICollectionViewFlowLayout {
    var delegate: UICollectionViewDelegateFlowLayout?
    let numColumns = 3
    var firstItemInRowMaxY: CGFloat = 0
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        
        let attributesToReturn = super.layoutAttributesForElementsInRect(rect) as [UICollectionViewLayoutAttributes]
        
        for attributes: UICollectionViewLayoutAttributes in attributesToReturn {
            
            if (nil == attributes.representedElementKind) {
                let indexPath = attributes.indexPath
                attributes.frame = self.layoutAttributesForItemAtIndexPath(indexPath).frame
            }
        }
        return attributesToReturn
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        
        let currentItemAttributes: UICollectionViewLayoutAttributes = super.layoutAttributesForItemAtIndexPath(indexPath)
        
        var spacing: CGFloat = 3
        var inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        if (self.delegate != nil) {
            inset = self.delegate!.collectionView!(self.collectionView!, layout: self, insetForSectionAtIndex: indexPath.section)
            spacing = self.delegate!.collectionView!(self.collectionView!, layout: self, minimumInteritemSpacingForSectionAtIndex: indexPath.section)
        }
        
        let viewWidth = self.collectionView!.frame.size.width
        let layoutWidth = viewWidth - inset.left - inset.right
        let width = (layoutWidth - (spacing * CGFloat(self.numColumns - 1))) / CGFloat(self.numColumns)
        
        // if very first item
        if (indexPath.item == 0) {
            currentItemAttributes.frame = CGRectMake(inset.left, inset.top, width, width)
            return currentItemAttributes;
        }
        
        let previousIndexPath: NSIndexPath = NSIndexPath(forItem: indexPath.item-1, inSection: indexPath.section)
        let previousFrame: CGRect = self.layoutAttributesForItemAtIndexPath(previousIndexPath).frame
        var previousFrameRightPoint: CGFloat = previousFrame.origin.x + previousFrame.size.width + spacing
        var previousFrameTopPoint: CGFloat = previousFrame.origin.y
       
        let stretchedCurrentFrame = CGRectMake(inset.left, currentItemAttributes.frame.origin.y, layoutWidth, width)
        // if the current frame, once left aligned to the left and stretched to the full collection view
        // width intersects the previous frame then they are on the same line
        //if (!CGRectIntersectsRect(previousFrame, stretchedCurrentFrame)) {
        if (indexPath.item % 3 == 0) {

            // make sure the first item on a line is left aligned
            previousFrameRightPoint = inset.left
            previousFrameTopPoint = previousFrame.origin.y + previousFrame.size.height + spacing
        }
        
        currentItemAttributes.frame = CGRectMake(previousFrameRightPoint, previousFrameTopPoint, width, width)
        return currentItemAttributes
    }
}
