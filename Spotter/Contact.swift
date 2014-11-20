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

func divideString(data: NSString) -> [String] {
    
    var offset = 0
    let chunkSize = 10 * 1024 * 1024
    let length = data.length
    
    var chunks: [String] = []
    
    do {
        // get the chunk location
        let thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset
    
        let string = data.substringWithRange(NSRange(location: offset, length: thisChunkSize))
        chunks.append(string)
        
        // update the offset
        offset += thisChunkSize
    } while (offset < length)
    
    return chunks
}