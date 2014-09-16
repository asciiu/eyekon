//
//  FrameSet.swift
//  Spotter
//
//  Created by LV426 on 9/4/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import Foundation
import CoreData

class FrameSet: NSManagedObject {

    @NSManaged var frameCount: NSNumber
    @NSManaged var detailedDescription: String
    @NSManaged var title: String
    @NSManaged var frames: NSSet
}
