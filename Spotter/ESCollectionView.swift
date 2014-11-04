//
//  ESCollectionView.swift
//  Eyekon
//
//  Created by LV426 on 10/29/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

class ESTableView: UITableView, UIGestureRecognizerDelegate {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    let children: [UIView] = [UIView]()
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    func setupTableView() {
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture")
        self.longPressGestureRecognizer!.delegate = self
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
//    // by enforcing failure dependency so that they doesn't clash.
//    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
//    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
//    [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
//    }
//    }
//    
//    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
//    
//    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
//    action:@selector(handlePanGesture:)];
//    _panGestureRecognizer.delegate = self;
//    [self.collectionView addGestureRecognizer:_panGestureRecognizer];
//    
//    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name: UIApplicationWillResignActiveNotification object:nil];
//    
//    self.shadowView = [[UIView alloc] init];
//    self.shadowView.hidden = true;
//    self.shadowView.backgroundColor = [UIColor grayColor];
//    self.shadowView.alpha = 0.35;
//    
//    [self.collectionView addSubview:self.shadowView];
    }
    

    func appendChildView(view: UIView) {
        
        let x: CGFloat = 0
        let y: CGFloat = 0
        
        //view.frame
        if(children.count == 0) {
            
        }
    }
}
