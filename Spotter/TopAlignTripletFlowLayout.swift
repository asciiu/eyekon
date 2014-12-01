//
//  TripletFlowLayout.swift
//  Eyekon
//
//  Created by LV426 on 12/1/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class TopAlignTripletFlowLayout: UICollectionViewFlowLayout, UICollectionViewDelegateFlowLayout {
 
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
        
        var topInset: CGFloat = 0
            
        if (self.delegate != nil) {
            topInset = self.delegate!.collectionView!(self.collectionView!, layout: self, insetForSectionAtIndex: indexPath.section).top
        }
        
        // First row should be aligned at the top
        if (indexPath.item < self.numColumns) {
            var frame: CGRect = currentItemAttributes.frame
            frame.origin.y = topInset
            currentItemAttributes.frame = frame
            
            return currentItemAttributes
        }
    
        
        /*
        * if (firstItemInRow) Get height of highest item of previous row, add it to the origin.y of that item and assign it to the current item + topinset
        * else (secondItemInRow OR thirdItemInRow) origin.y should be the same as the first item in the row
        */
        if (indexPath.item % self.numColumns == 0) {
            // Get the heights of the previous row's items
            let frameOne: CGRect = self.getFrameForItem(indexPath.item - self.numColumns, inSection:indexPath.section)
            let frameTwo: CGRect = self.getFrameForItem(indexPath.item - (self.numColumns - 1), inSection:indexPath.section)
            let frameThree: CGRect = self.getFrameForItem(indexPath.item - (self.numColumns - 2), inSection:indexPath.section)
            
            // Add them to an array and retreive the biggest value
            let heights = [frameOne.size.height, frameTwo.size.height, frameThree.size.height]
            let highestValue = heights.reduce(CGFloat.max, { min($0, $1) })
            
            // Assign the highest value to the y coordinate of its frame
            var frame: CGRect = currentItemAttributes.frame
            frame.origin.y = topInset + frameOne.origin.y + highestValue
            currentItemAttributes.frame = frame
            
            self.firstItemInRowMaxY = currentItemAttributes.frame.origin.y
        } else {
            // This item should have the same origin.y as the first item in the row
            var frame: CGRect = currentItemAttributes.frame
            frame.origin.y = self.firstItemInRowMaxY
            currentItemAttributes.frame = frame
        }
    
        return currentItemAttributes
    }


    func getFrameForItem(item: NSInteger, inSection section:NSInteger) -> CGRect {
        let indexPath: NSIndexPath = NSIndexPath(forItem: item, inSection: section)
        
        return self.layoutAttributesForItemAtIndexPath(indexPath).frame
    }
}