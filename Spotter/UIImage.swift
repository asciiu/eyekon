//
//  UIImageNSCoding.swift
//  Spotter
//
//  Created by LV426 on 10/4/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

let kEncodingKey = "UIImage"

//extension UIImage: NSCoding {
//   
//    init(coder aDecoder: NSCoder) {
//        //super.init(coder: aDecoder)
//        let data: NSData = aDecoder.decodeObjectForKey(kEncodingKey) as NSData
//    }
//    
////    override init(data: NSData) {
////        super.init(data: data)
////    }
////    
////    override init(contentsOfFile: String) {
////        super.init(contentsOfFile: contentsOfFile)
////    }
//    
//    func encodeWithCoder(aCoder: NSCoder) {
//        let data: NSData = UIImagePNGRepresentation(self)
//        aCoder.encodeObject(data, forKey: kEncodingKey)
//    }
//}
