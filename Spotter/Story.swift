//
//  Spotter.swift
//  Spotter
//
//  Created by LV426 on 10/4/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import Foundation
import CoreData

class Story: NSManagedObject {

    @NSManaged var summary: String
    @NSManaged var title: String
    @NSManaged var content: StoryContent
}
