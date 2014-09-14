//
//  DraggableImageView.swift
//  Spotter
//
//  Created by LV426 on 9/13/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class DraggableImageView: UIImageView {

    var startLocation: CGPoint?
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch: UITouch = touches.anyObject() as UITouch
        let pt: CGPoint = touch.locationInView(self)
        
        self.startLocation = pt
        
        self.superview?.bringSubviewToFront(self)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        //- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
        let touch: UITouch = touches.anyObject() as UITouch
        let pt: CGPoint = touch.locationInView(self)
        
        
        //CGPoint pt = [[touches anyObject] locationInView:self];
        var frame: CGRect = self.frame
        frame.origin.x += pt.x - self.startLocation!.x
        frame.origin.y += pt.y - self.startLocation!.y
        self.frame = frame
    }
}
