//
//  FrameSet.swift
//  Spotter
//
//  Created by LV426 on 9/4/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import Foundation
import CoreData

struct SharedDataFrameSet {
    static var dataFrameSet: FrameSet?
    
    static func findFrameNumber(number: Int) -> Frame? {
        let allObjects = SharedDataFrameSet.dataFrameSet!.frames.allObjects
        
        for(var i = 0; i < allObjects.count; ++i) {
            let dataFrame: Frame = allObjects[i] as Frame
            
            if (dataFrame.frameNumber == number) {
                return dataFrame
            }
        }
        return nil
    }
    
    static func sortedDataFrames() -> [Frame] {
        let frameNumDescriptor: NSSortDescriptor = NSSortDescriptor(key: "frameNumber", ascending: true)
        
        let frames = SharedDataFrameSet.dataFrameSet!.frames
        
        return frames.sortedArrayUsingDescriptors(NSArray(object:frameNumDescriptor)) as [Frame]
    }
    
    static func removeDataFrame(frameNumber: Int) {
        let dataFrame = SharedDataFrameSet.findFrameNumber(frameNumber)
        if (dataFrame != nil) {
            SharedDataFrameSet.dataFrameSet!.frames.removeObject(dataFrame!)
        }
    }
}

class FrameSet: NSManagedObject {

    @NSManaged var frameCount: NSNumber
    @NSManaged var detailedDescription: String
    @NSManaged var title: String
    @NSManaged var frames: NSMutableSet
}
