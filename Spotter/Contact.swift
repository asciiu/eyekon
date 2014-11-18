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

    @NSManaged var ownerID: String
    @NSManaged var contactID: String
    @NSManaged var name: String
    @NSManaged var email: String
    @NSManaged var profileImage: NSData?
}

class CoreContext {
    
    let context: NSManagedObjectContext = NSManagedObjectContext()
    
    init() {
        // Do any additional setup after loading the view.
        let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        self.context.persistentStoreCoordinator = appDelegate.persistentStoreCoordinator
    }
    
    func createEntity(entity: String) -> AnyObject {
        return NSEntityDescription.insertNewObjectForEntityForName(entity, inManagedObjectContext: self.context)
    }
}