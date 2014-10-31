//
//  ESCollectionView.swift
//  Eyekon
//
//  Created by LV426 on 10/29/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class ESCollectionView: UIScrollView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    let children: [UIView] = [UIView]()

    func appendChildView(view: UIView) {
        
        let x: CGFloat = 0
        let y: CGFloat = 0
        
        //view.frame
        if(children.count == 0) {
            
        }
    }
}
