//
//  Frame.swift
//  Spotter
//
//  Created by LV426 on 9/4/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import Foundation
import CoreData

class Frame: NSManagedObject {

    @NSManaged var imageData: NSData
    @NSManaged var frameNumber: NSNumber
    @NSManaged var frameSet: FrameSet

}
