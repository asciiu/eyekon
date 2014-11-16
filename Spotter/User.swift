//
//  Eyekon.swift
//  Eyekon
//
//  Created by LV426 on 11/15/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import Foundation
import CoreData

class User: NSManagedObject {

    @NSManaged var first: String
    @NSManaged var last: String
    @NSManaged var uid: String
    @NSManaged var profileImage: NSData
}
