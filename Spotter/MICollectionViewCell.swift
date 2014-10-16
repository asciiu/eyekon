//
//  MIView.swift
//  Eyekon
//
//  Created by LV426 on 10/15/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class MIView: UIView {
    
    let views: NSMutableArray = NSMutableArray()
    
    override func addSubview(view: UIView) {
        views.addObject(view)
    }
    
    func removeSubviews() {
        views.removeAllObjects()
    }
    
    func removeSubview(view: UIView) {
        if (views.containsObject(view)) {
            views.removeObject(view)
        }
    }
}
