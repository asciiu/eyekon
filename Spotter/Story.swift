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

    @NSManaged var uid: String
    @NSManaged var storyID: String
    @NSManaged var summary: String
    @NSManaged var title: String
    @NSManaged var content: StoryContent
}


//...thx: http://blog.logichigh.com/2008/06/05/uiimage-fix/
func scaleAndRotateImage(imageIn: UIImage) -> UIImage {
    var kMaxResolution: CGFloat = 3264 // Or whatever
    
    let imgRef: CGImageRef = imageIn.CGImage
    let width: CGFloat = CGFloat(CGImageGetWidth(imgRef))
    let height: CGFloat = CGFloat(CGImageGetHeight(imgRef))
    var transform: CGAffineTransform = CGAffineTransformIdentity
    var bounds: CGRect = CGRectMake(0, 0, width, height)
    
    
    if ( width > kMaxResolution || height > kMaxResolution ) {
        let ratio: CGFloat = width/height
        
        if (ratio > 1) {
            bounds.size.width  = kMaxResolution
            bounds.size.height = bounds.size.width / ratio
        } else {
            bounds.size.height = kMaxResolution
            bounds.size.width  = bounds.size.height * ratio
        }
    }
    
    let scaleRatio: CGFloat = bounds.size.width / width
    let imageSize: CGSize = CGSizeMake( width, height)
    let orient: UIImageOrientation = imageIn.imageOrientation
    var boundHeight: CGFloat
    
    switch(orient) {
    case UIImageOrientation.Up:                                         //EXIF = 1
        transform = CGAffineTransformIdentity
        break
        
    case UIImageOrientation.UpMirrored:                                //EXIF = 2
        transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0)
        transform = CGAffineTransformScale(transform, -1.0, 1.0)
        break
        
    case UIImageOrientation.Down:                                      //EXIF = 3
        transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height)
        transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        break
        
    case UIImageOrientation.DownMirrored:                              //EXIF = 4
        transform = CGAffineTransformMakeTranslation(0.0, imageSize.height)
        transform = CGAffineTransformScale(transform, 1.0, -1.0)
        break
        
    case UIImageOrientation.LeftMirrored:                              //EXIF = 5
        boundHeight = bounds.size.height
        bounds.size.height = bounds.size.width
        bounds.size.width = boundHeight
        transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width)
        transform = CGAffineTransformScale(transform, -1.0, 1.0)
        transform = CGAffineTransformRotate(transform, 3.0 * CGFloat(M_PI) / 2.0)
        break
        
    case UIImageOrientation.Left:                                      //EXIF = 6
        boundHeight = bounds.size.height
        bounds.size.height = bounds.size.width
        bounds.size.width = boundHeight
        transform = CGAffineTransformMakeTranslation(0.0, imageSize.width)
        transform = CGAffineTransformRotate(transform, 3.0 * CGFloat(M_PI) / 2.0)
        break
        
    case UIImageOrientation.RightMirrored:                             //EXIF = 7
        boundHeight = bounds.size.height
        bounds.size.height = bounds.size.width
        bounds.size.width = boundHeight
        transform = CGAffineTransformMakeScale(-1.0, 1.0)
        transform = CGAffineTransformRotate(transform, CGFloat(M_PI) / 2.0)
        break
        
    case UIImageOrientation.Right:                                     //EXIF = 8
        boundHeight = bounds.size.height
        bounds.size.height = bounds.size.width
        bounds.size.width = boundHeight
        transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0)
        transform = CGAffineTransformRotate(transform, CGFloat(M_PI) / 2.0)
        break
        
    default:
        let e = NSException(name: NSInternalInconsistencyException, reason: "Invalid image orientation", userInfo: nil)
        e.raise()
    }
    
    UIGraphicsBeginImageContext( bounds.size )
    
    let context: CGContextRef = UIGraphicsGetCurrentContext()
    
    if ( orient == UIImageOrientation.Right || orient == UIImageOrientation.Left ) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio)
        CGContextTranslateCTM(context, -height, 0)
    } else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio)
        CGContextTranslateCTM(context, 0, -height)
    }
    
    CGContextConcatCTM( context, transform )
    
    CGContextDrawImage( UIGraphicsGetCurrentContext(), CGRectMake( 0, 0, width, height ), imgRef )
    let imageCopy: UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return( imageCopy )
}