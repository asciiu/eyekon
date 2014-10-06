//
//  StoryContent.swift
//  Spotter
//
//  Created by LV426 on 10/4/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import Foundation
import CoreData

class StoryContent: NSManagedObject {

    @NSManaged var data: NSData?
    @NSManaged var story: Story

}
