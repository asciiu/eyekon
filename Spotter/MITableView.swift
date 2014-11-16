//
//  ESCollectionView.swift
//  Eyekon
//
//  Created by LV426 on 10/29/14.
//  Copyright (c) 2014 Bleu Bee LLC. All rights reserved.
//

import UIKit

enum LXScrollingDirection: Int {
    case LXScrollingDirectionUnknown = 0
    case LXScrollingDirectionUp = 1
    case LXScrollingDirectionDown = 2
    case LXScrollingDirectionLeft = 3
    case LXScrollingDirectionRight = 4
}

func CGPointAdd(point1: CGPoint, point2: CGPoint) -> CGPoint {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

let kLXScrollingDirectionKey = "LXScrollingDirection"
let kLXCollectionViewKeyPath = "collectionView"

extension CADisplayLink {
    var userInfo: Dictionary<String, Int> {
        get{
            return objc_getAssociatedObject(self, "userInfo") as Dictionary<String, Int>
        }
        set (userInfo) {
            objc_setAssociatedObject(self, "userInfo", userInfo, objc_AssociationPolicy(OBJC_ASSOCIATION_COPY))
        }
    }
}


@objc protocol MITableViewDelegate: UITableViewDelegate {
    optional func doubleTab(indexPath: NSIndexPath)
}

class MITableView: UITableView, UIGestureRecognizerDelegate {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    var displayLink: CADisplayLink?
    var selectedItemIndexPath: NSIndexPath?
    var doubleTapGestureRecognier: UITapGestureRecognizer?
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    var currentView: UIView?
    var currentViewCenter: CGPoint = CGPointZero
    let shadowView: UIView = UIView()

    //var panGestureRecognizer: UIPanGestureRecognizer?
    //@property (assign, nonatomic) CGFloat scrollingSpeed;
    //@property (assign, nonatomic) UIEdgeInsets scrollingTriggerEdgeInsets;
    var miDelegate: MITableViewDelegate?
    
    override init() {
        super.init()
        setupTableView()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTableView()
        //fatalError("init(coder:) has not been implemented")
    }
    
    
    
    func setupTableView() {
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
        self.longPressGestureRecognizer!.delegate = self
        //self.longPressGestureRecognizer!.cancelsTouchesInView = false
        self.addGestureRecognizer(self.longPressGestureRecognizer!)
        
        self.panGestureRecognizer.addTarget(self, action: "handlePanGesture:")
        self.panGestureRecognizer.delegate = self
        
        self.doubleTapGestureRecognier = UITapGestureRecognizer(target: self, action: "handleDoubleTap:")
        self.doubleTapGestureRecognier!.numberOfTapsRequired = 2
        self.addGestureRecognizer(self.doubleTapGestureRecognier!)
        
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
        self.shadowView.hidden = true
        self.shadowView.backgroundColor = UIColor.grayColor()
        self.shadowView.alpha = 0.35
        self.addSubview(self.shadowView)
    }
    
    func invalidatesScrollTimer() {
        if (self.displayLink == nil) {
            return
        } else if (!self.displayLink!.paused) {
            self.displayLink!.invalidate()
        }
        
        self.displayLink = nil
    }
    
    func setupScrollTimerInDirection(direction: LXScrollingDirection) {
        if (!self.displayLink!.paused) {
            let oldDirection = LXScrollingDirection(rawValue: self.displayLink!.userInfo[kLXScrollingDirectionKey]!)
            
            if (direction == oldDirection) {
                return
            }
        }
        
        self.invalidatesScrollTimer()
        
        self.displayLink = CADisplayLink(target: self, selector: "handleScroll:")
        self.displayLink!.userInfo = [kLXScrollingDirectionKey : direction.rawValue]
        self.displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    // MARK: - Target/Action methods
    // Tight loop, allocate memory sparely, even if they are stack allocation.
    func handleDoubleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        let point = gestureRecognizer.locationInView(self)
        let indexPath = self.indexPathForRowAtPoint(point)
        
        if (indexPath != nil) {
            self.miDelegate?.doubleTab?(indexPath!)
        }
    }
    
    func handleScroll(displayLink: CADisplayLink) {

    }

    func handleLongPressGesture(gestureRecognizer: UILongPressGestureRecognizer) {
        switch(gestureRecognizer.state) {
        case UIGestureRecognizerState.Began:
            let point1 = gestureRecognizer.locationInView(self)
            let point2 = gestureRecognizer.locationInView(self.superview)

            self.selectedItemIndexPath = self.indexPathForRowAtPoint(point1)
            
            // selectesd item will be nil if there is no cell at touch point
            if (self.selectedItemIndexPath == nil) {
                return
            }
            
            // can the item at the selected index be moved
//            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
//            ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
//                self.selectedItemIndexPath = nil;
//                return;
//            }
//            
//            // inform delegate of drag
//            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
//                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
//            }
            let tableCell: UITableViewCell = self.cellForRowAtIndexPath(self.selectedItemIndexPath!)!
            let cellFrame: CGRect = tableCell.frame
            
            self.currentView = tableCell.snapshotViewAfterScreenUpdates(false)
            self.currentView!.frame = self.superview!.convertRect(cellFrame, fromView: self)
            let parentRect = cellFrame;
            
            // add drop shadow
            self.currentView!.layer.shadowColor = UIColor.blackColor().CGColor
            self.currentView!.layer.shadowOpacity = 0.8
            self.currentView!.layer.shadowRadius = 3.0
            self.currentView!.layer.shadowOffset = CGSizeMake(2.0, 2.0)
            
            // display the shadowView to indicate previous location
            self.shadowView.frame = cellFrame
            self.shadowView.hidden = false
            
            // the current view belongs in the parent view of the collection view
            self.superview!.addSubview(self.currentView!)
            self.currentViewCenter = self.currentView!.center
            tableCell.hidden = true
            
            UIView.animateWithDuration(0.3,
                delay: 0.0,
                options: UIViewAnimationOptions.BeginFromCurrentState,
                animations: {
                    let scale = 75 / self.currentView!.frame.size.width
                    self.currentView!.transform = CGAffineTransformMakeScale(scale, scale)
                    self.currentView!.center = point2
                },
                completion: { (fin: Bool) -> Void in
                    self.currentViewCenter = self.currentView!.center
                    //self.delegate?tableView(something
                    //if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                    //  [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                    //}
                    
            })
            break
        case UIGestureRecognizerState.Ended:
            
            if (self.selectedItemIndexPath == nil) {
                return
            }
            
            let tableCell: UITableViewCell = self.cellForRowAtIndexPath(self.selectedItemIndexPath!)!
            tableCell.hidden = false

            self.selectedItemIndexPath = nil
            self.currentView!.removeFromSuperview()
            self.shadowView.hidden = true
            
            break
        default:
            // do nothing
            break
        }
    }
    
    func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        if (self.selectedItemIndexPath == nil) {
            return
        }
        
        switch(gestureRecognizer.state) {
        case UIGestureRecognizerState.Changed:
            let panTranslation = gestureRecognizer.translationInView(self)
            self.currentView!.center = CGPointAdd(self.currentViewCenter, panTranslation)
            
            let viewCenter: CGPoint = self.convertPoint(self.currentView!.center, fromView: self.superview!)
            
            self.invalidatesScrollTimer()
            //[self invalidateLayoutIfNecessary];
            
            //if (viewCenter.y < (CGRectGetMinY(self.bounds) +
                
//                self.scrollIndicatorInsets.top )) {
//                    [self setupScrollTimerInDirection:LXScrollingDirectionUp];
//                } else {
//                    if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
//                        [self setupScrollTimerInDirection:LXScrollingDirectionDown];
//                    } else {
//                        [self invalidatesScrollTimer];
//                    }
//                }
//            } break;
//            case UICollectionViewScrollDirectionHorizontal: {
//                if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
//                    [self setupScrollTimerInDirection:LXScrollingDirectionLeft];
//                } else {
//                    if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
//                        [self setupScrollTimerInDirection:LXScrollingDirectionRight];
//                    } else {
//                        [self invalidatesScrollTimer];
//                    }
//                }
//            } break;
//            }

            
            break
        case UIGestureRecognizerState.Ended:
            println("pan ended")
            break
        default:
            // do nothing
            break
        }
    }

    // MARK: - UIGestureRecognizerDelegate methods
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if (self.longPressGestureRecognizer!.isEqual(gestureRecognizer)) {
            return self.panGestureRecognizer.isEqual(otherGestureRecognizer)
        }
        
        if (self.panGestureRecognizer.isEqual(gestureRecognizer)) {
            return self.longPressGestureRecognizer!.isEqual(otherGestureRecognizer)
        }
        
        return false
    }
    
    // MARK: - Notifications

    func handleApplicationWillResignActive(notification: NSNotification) {
        self.panGestureRecognizer.enabled = false
        self.panGestureRecognizer.enabled = true
    }
}
