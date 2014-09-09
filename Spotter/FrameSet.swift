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
    @NSManaged var synopsis: String
    @NSManaged var frames: NSSet

}
