//
//  Contact.swift
//  Eyekon
//
//  Created by LV426 on 11/18/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import Foundation
import CoreData

class Contact: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var email: String
    @NSManaged var profileImage: NSData

}
