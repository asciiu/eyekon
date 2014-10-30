//
//  LXReorderableCollectionViewFlowLayout.m
//
//  Created by Stan Chang Khin Boon on 1/10/12.
//  Copyright (c) 2012 d--buzz. All rights reserved.
//

#import "LXReorderableCollectionViewFlowLayout.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#ifndef CGGEOMETRY_LXSUPPORT_H_
CG_INLINE CGPoint
LXS_CGPointAdd(CGPoint point1, CGPoint point2) {
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}
#endif

typedef NS_ENUM(NSInteger, LXScrollingDirection) {
    LXScrollingDirectionUnknown = 0,
    LXScrollingDirectionUp,
    LXScrollingDirectionDown,
    LXScrollingDirectionLeft,
    LXScrollingDirectionRight
};

static NSString * const kLXScrollingDirectionKey = @"LXScrollingDirection";
static NSString * const kLXCollectionViewKeyPath = @"collectionView";

@interface CADisplayLink (LX_userInfo)
@property (nonatomic, copy) NSDictionary *LX_userInfo;
@end

@implementation CADisplayLink (LX_userInfo)
- (void) setLX_userInfo:(NSDictionary *) LX_userInfo {
    objc_setAssociatedObject(self, "LX_userInfo", LX_userInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *) LX_userInfo {
    return objc_getAssociatedObject(self, "LX_userInfo");
}
@end

@interface UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIView *)LX_snapshotView;

@end

@implementation UICollectionViewCell (LXReorderableCollectionViewFlowLayout)

- (UIView *)LX_snapshotView {
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        return [self snapshotViewAfterScreenUpdates:YES];
    } else {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return [[UIImageView alloc] initWithImage:image];
    }
}

@end

@interface LXReorderableCollectionViewFlowLayout ()

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) UIView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (assign, nonatomic) CGPoint panTranslationInCollectionView;
@property (strong, nonatomic) CADisplayLink *displayLink;

@property (assign, nonatomic) CGPoint currentPoint;
@property (assign, nonatomic) CGRect targetRect;
@property (strong, nonatomic) UIView *shadowView;

@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDataSource> dataSource;
@property (assign, nonatomic, readonly) id<LXReorderableCollectionViewDelegateFlowLayout> delegate;

@end

@implementation LXReorderableCollectionViewFlowLayout

- (void)setDefaults {
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
}

- (void)setupCollectionView {
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }
    
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handlePanGesture:)];
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];

    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name: UIApplicationWillResignActiveNotification object:nil];
    
    self.shadowView = [[UIView alloc] init];
    self.shadowView.hidden = true;
    self.shadowView.backgroundColor = [UIColor grayColor];
    self.shadowView.alpha = 0.15;

    [self.collectionView addSubview:self.shadowView];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kLXCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self invalidatesScrollTimer];
    [self removeObserver:self forKeyPath:kLXCollectionViewKeyPath];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    
    [self.shadowView removeFromSuperview];
    self.shadowView = nil;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        layoutAttributes.hidden = YES;
    }
}

- (id<LXReorderableCollectionViewDataSource>)dataSource {
    return (id<LXReorderableCollectionViewDataSource>)self.collectionView.dataSource;
}

- (id<LXReorderableCollectionViewDelegateFlowLayout>)delegate {
    return (id<LXReorderableCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
}

- (NSArray *)reduceRectsToFitWidth:(NSArray *)rects {
    
    NSMutableArray *newRects = rects.mutableCopy;
    float frameWidth = self.collectionViewContentSize.width;
    float spacing = [self.delegate collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:self.selectedItemIndexPath.section];
    
    float totalWidth = frameWidth - (spacing * (rects.count-1));
    
    float r = 0;
    for(int i = 0; i < rects.count; ++i) {
        CGRect rect = [[rects objectAtIndex:i] CGRectValue];
        r += rect.size.width / rect.size.height;
    }

    float height = floorf((float)totalWidth / r);
    float x = 0;
    float y = [[rects objectAtIndex:0] CGRectValue].origin.y;
    
    for(int j = 0; j < rects.count; ++j) {
        CGRect rect = [[rects objectAtIndex:j] CGRectValue];
        
        float imageWidth = rect.size.width;
        float imageHeight = rect.size.height;
        float width = height * imageWidth / imageHeight;
        
        newRects[j] = [NSValue valueWithCGRect:CGRectMake(x, y, width, height)];
        x += width + self.minimumInteritemSpacing;
    }
    
    return newRects;
}

/*
 * returns the sized path rects to fit the content width
 *
 */
- (NSArray *)resizePathRectsToFitWidth:(NSArray *)indexPaths {
    NSMutableArray *imageRects = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (int i = 0; i < indexPaths.count; ++i) {
        NSIndexPath *path = indexPaths[i];
        
        // get dimensions of path from the datasource
        CGRect imageRect = [self.dataSource itemSizeAtIndexPath:path];
        CGRect frameRect = [self layoutAttributesForItemAtIndexPath:path].frame;
        CGRect pathRect = CGRectMake(frameRect.origin.x, frameRect.origin.y, imageRect.size.width, imageRect.size.height);
        [imageRects addObject:[NSValue valueWithCGRect:pathRect]];
    }
    
    return [self reduceRectsToFitWidth:imageRects];
}

- (void)resizeIndexPath:(NSIndexPath *)indexPath rect:(CGRect)newRect {
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    
    cell.contentView.autoresizesSubviews = YES;
    [UIView transitionWithView:self.collectionView
                      duration:0.3
                       options:UIViewAnimationOptionCurveLinear
                    animations:^{
                        cell.frame = newRect;
                    }
                    completion:^(BOOL finished) {
                        cell.contentView.autoresizesSubviews = NO;
                        //[self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
                    }];
}

- (CGRect)sectionRectForIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewLayoutAttributes* attrs = [self layoutAttributesForItemAtIndexPath:indexPath];
    CGRect frame = attrs.frame;
    
    return CGRectMake(0, frame.origin.y, self.collectionViewContentSize.width, frame.size.height);
}

- (NSArray *)indexPathsInRect:(CGRect)rect {
    NSArray *attributes = [self layoutAttributesForElementsInRect:rect];
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:attributes.count];
    
    for (UICollectionViewLayoutAttributes *attrs in attributes) {
        [paths addObject:attrs.indexPath];
    }
    
    return paths;
}

- (void)invalidateLayoutAtIndexPaths:(NSArray *)indexPaths {

    NSArray *newRects = [self resizePathRectsToFitWidth:indexPaths];
    CGRect firstRect = [newRects[0] CGRectValue];
    CGRect oldRect = [self layoutAttributesForItemAtIndexPath:indexPaths[0]].frame;
    CGFloat diff = oldRect.size.height - firstRect.size.height;
    
    if (diff == 0) {
        return;
    }
    
    NSLog([NSString stringWithFormat:@"diff: %f", diff]);
    
    //CGFloat y = [self layoutAttributesForItemAtIndexPath:indexPaths[0]].frame.origin.y;
    
    for (int j = 0; j < indexPaths.count; ++j) {
        NSIndexPath *path = indexPaths[j];
        CGRect reducedRect = [newRects[j] CGRectValue];

        [self resizeIndexPath:path rect:reducedRect];
    }
    
    //CGPoint offset = self.collectionView.contentOffset;
    //self.currentView.center = CGPointMake(self.currentView.center.x, self.currentView.center.y + diff);
    //self.collectionView.contentOffset = CGPointMake(offset.x, offset.y - diff);
}

- (void)invalidateLayoutIfNecessary {

    // default new index path comes from the collection view
    NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:self.currentView.center];

    NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
    CGRect targetRect = [self layoutAttributesForItemAtIndexPath:newIndexPath].frame;
    BOOL flag = false;
    
    // if the delegate implements this method ask for the new index path
    if (newIndexPath == nil) {
        flag = true;
        
        // if we are beyond the content bounds expand to full width
        if (self.currentView.center.y >= self.collectionViewContentSize.height) {
            NSInteger section = self.collectionView.numberOfSections;
            NSInteger items = [self.collectionView numberOfItemsInSection:section-1];
            
            newIndexPath = [NSIndexPath indexPathForRow:items-1 inSection:section-1];
            
            NSArray *rects = [self resizePathRectsToFitWidth:@[previousIndexPath]];
            [self.dataSource itemAtIndexPath:previousIndexPath didResize:[rects[0] CGRectValue].size];
            
            if ([newIndexPath isEqual:previousIndexPath]) {
                CGRect shadowRect = [self layoutAttributesForItemAtIndexPath:previousIndexPath].frame;
                
                self.shadowView.frame = shadowRect;
                self.shadowView.hidden = false;
            }
            
        } else if (CGRectContainsPoint(self.originRect, self.currentView.center)) {
            
            // we are going back to the empty space that we previously occupied
            [self.dataSource itemAtIndexPath:previousIndexPath didResize:self.previousRect.size];
            CGRect shadowRect = [self layoutAttributesForItemAtIndexPath:previousIndexPath].frame;
            
            self.shadowView.frame = shadowRect;
            self.shadowView.hidden = false;
        }
    }
    
    if ((newIndexPath == nil) || [newIndexPath isEqual:previousIndexPath]) {
        return;
    }
    
    // if we are not in the original rect
    if (!CGRectContainsPoint(self.originRect, self.currentView.center) && !flag) {
        CGRect sectionRect = [self sectionRectForIndexPath:newIndexPath];
        NSMutableArray *paths = [self indexPathsInRect:sectionRect].mutableCopy;
        [paths addObject:self.selectedItemIndexPath];
    
        // resize the selected item to fit our target section
        NSMutableArray *newRects = [self resizePathRectsToFitWidth:paths].mutableCopy;
        CGSize selectedSize = [newRects.lastObject CGRectValue].size;
        [self.dataSource itemAtIndexPath:self.selectedItemIndexPath didResize:selectedSize];

        /*
        for(int i = 0; i < newRects.count -1; ++i) {
            [self resizeIndexPath:paths[i] rect:[newRects[i] CGRectValue]];
        }*/
        
        [self invalidateLayoutAtIndexPaths:paths];
    } else {
        // back in original rect restore original size
        [self.dataSource itemAtIndexPath:previousIndexPath didResize:self.previousRect.size];
    }
    
    
    
//    if (CGRectContainsPoint(self.originRect, self.currentView.center)) {
//        [self.delegate shouldResizeItemAtIndexPath:previousIndexPath rect:CGRectMake(0, 0, self.previousRect.size.width, self.previousRect.size.height)];
//    }
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
        ![self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath]) {
        return;
    }
    
    self.selectedItemIndexPath = newIndexPath;
    self.targetRect = targetRect;
    
    //[self invalidateLayoutAtIndexPaths:@[newIndexPath, previousIndexPath]];
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:newIndexPath];
    }
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.collectionView moveItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
        }
    } completion:^(BOOL finished) {
        // move finished
        if (!CGRectEqualToRect(self.targetRect, CGRectZero)) {
            CGRect shadowRect = [self layoutAttributesForItemAtIndexPath:newIndexPath].frame;
            
            self.shadowView.frame = shadowRect;
            self.shadowView.hidden = false;
        }
        
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            [strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath didMoveToIndexPath:newIndexPath];
        }
        
       
    }];
}

- (void)invalidatesScrollTimer {
    if (!self.displayLink.paused) {
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
}

- (void)setupScrollTimerInDirection:(LXScrollingDirection)direction {
    if (!self.displayLink.paused) {
        LXScrollingDirection oldDirection = [self.displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];

        if (direction == oldDirection) {
            return;
        }
    }
    
    [self invalidatesScrollTimer];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
    self.displayLink.LX_userInfo = @{ kLXScrollingDirectionKey : @(direction) };

    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - Target/Action methods

// Tight loop, allocate memory sparely, even if they are stack allocation.
- (void)handleScroll:(CADisplayLink *)displayLink {
    LXScrollingDirection direction = (LXScrollingDirection)[displayLink.LX_userInfo[kLXScrollingDirectionKey] integerValue];
    if (direction == LXScrollingDirectionUnknown) {
        return;
    }
    
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    // Important to have an integer `distance` as the `contentOffset` property automatically gets rounded
    // and it would diverge from the view's center resulting in a "cell is slipping away under finger"-bug.
    CGFloat distance = rint(self.scrollingSpeed * displayLink.duration);
    CGPoint translation = CGPointZero;
    
    switch(direction) {
        case LXScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f - contentInset.top;
            
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y - contentInset.top;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height + contentInset.bottom;
            
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case LXScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0f - contentInset.left;
            
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x - contentInset.left;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        case LXScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width + contentInset.right;
            
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, translation);
    self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
    self.collectionView.contentOffset = LXS_CGPointAdd(contentOffset, translation);
}


- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            self.selectedItemIndexPath = currentIndexPath;
            
            // selected item will be nil if there is no cell at touch point
            if (self.selectedItemIndexPath == nil) {
                return;
            }
            
            // can the item at the selected index be moved
            if ([self.dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)] &&
               ![self.dataSource collectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                self.selectedItemIndexPath = nil;
                return;
            }
            
            // inform delegate of drag
            if ([self.delegate respondsToSelector:@selector(collectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate collectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            self.currentView = [[UIView alloc] initWithFrame:collectionViewCell.frame];
            self.previousRect = collectionViewCell.frame;
            self.originRect = CGRectMake(0, self.previousRect.origin.y, self.collectionViewContentSize.width, self.previousRect.size.height);
            
            // add drop shadow
            self.currentView.layer.shadowColor = [UIColor blackColor].CGColor;
            self.currentView.layer.shadowOpacity = 0.8;
            self.currentView.layer.shadowRadius = 3.0;
            self.currentView.layer.shadowOffset = CGSizeMake(2.0, 2.0);
            
            collectionViewCell.highlighted = YES;
            UIView *highlightedImageView = [collectionViewCell LX_snapshotView];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha = 1.0f;
            
            collectionViewCell.highlighted = NO;
            
            // display the shadowView to indicate previous location
            UICollectionViewLayoutAttributes *attr = [self.collectionView layoutAttributesForItemAtIndexPath:self.selectedItemIndexPath];
            self.shadowView.frame = attr.frame;
            self.shadowView.hidden = false;
            
            UIView *imageView = [collectionViewCell LX_snapshotView];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 0.0f;
            
            [self.currentView addSubview:imageView];
            [self.currentView addSubview:highlightedImageView];
            //[[self.collectionView superview] addSubview:self.currentView];
            [self.collectionView addSubview:self.currentView];
            
            CGPoint coords = [gestureRecognizer locationInView:gestureRecognizer.view];
            self.currentViewCenter = self.currentView.center;
            
            __weak typeof(self) weakSelf = self;
            [UIView
             animateWithDuration:0.3
             delay:0.0
             options:UIViewAnimationOptionBeginFromCurrentState
             animations:^{
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     CGFloat scale = 75 / strongSelf.currentView.frame.size.width;
                     //strongSelf.currentView.transform = CGAffineTransformMakeScale(1.05f, 1.05f);
                     strongSelf.currentView.transform = CGAffineTransformMakeScale(scale, scale);
                     strongSelf.currentView.center = coords;
                     highlightedImageView.alpha = 0.0f;
                     imageView.alpha = 1.0f;
                 }
             }
             completion:^(BOOL finished) {
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     
                     strongSelf.currentViewCenter = strongSelf.currentView.center;

                     [highlightedImageView removeFromSuperview];
                     
                     if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                         [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didBeginDraggingItemAtIndexPath:strongSelf.selectedItemIndexPath];
                     }
                 }
             }];
            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            
            if (currentIndexPath) {
                if ([self.delegate respondsToSelector:@selector(collectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate collectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                }
                
                self.selectedItemIndexPath = nil;
                self.currentViewCenter = CGPointZero;
                self.targetRect = CGRectZero;
                self.shadowView.hidden = true;
                
                NSArray *attributes = [self layoutAttributesForElementsInRect:self.originRect];
                NSMutableArray *paths = [NSMutableArray arrayWithCapacity:attributes.count];

                for (UICollectionViewLayoutAttributes *attrs in attributes) {
                    [paths addObject:attrs.indexPath];
                }
                
                // if release point of currentView is not in the original rect
                if (!CGRectContainsPoint(self.originRect, self.currentView.center)) {
                    [self invalidateLayoutAtIndexPaths:paths];
                }
                
                __weak typeof(self) weakSelf = self;
                [UIView
                 animateWithDuration:0.3
                 delay:0.0
                 options:UIViewAnimationOptionBeginFromCurrentState
                 animations:^{
                     //__strong typeof(self) strongSelf = weakSelf;
                     //if (strongSelf) {
                         //strongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                         //strongSelf.currentView.center = layoutAttributes.center;
                     //}
                 }
                 completion:^(BOOL finished) {
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         [strongSelf.currentView removeFromSuperview];
                         strongSelf.currentView = nil;
                         [strongSelf invalidateLayout];
                         
                         if ([strongSelf.delegate respondsToSelector:@selector(collectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                             [strongSelf.delegate collectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:currentIndexPath];
                         }
                         
//                         if ([strongSelf.dataSource respondsToSelector:@selector(resizeItemsAtIndexPaths:)]) {
//                             [strongSelf.dataSource resizeItemsAtIndexPaths:paths];
//                         }
                     }
                 }];
            }
        } break;
            
        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            self.panTranslationInCollectionView = [gestureRecognizer translationInView:self.collectionView];
            
            CGPoint viewCenter = self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
            
            [self invalidateLayoutIfNecessary];

            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical: {
                    if (viewCenter.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionUp];
                    } else {
                        if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionDown];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
                case UICollectionViewScrollDirectionHorizontal: {
                    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
                        [self setupScrollTimerInDirection:LXScrollingDirectionLeft];
                    } else {
                        if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
                            [self setupScrollTimerInDirection:LXScrollingDirectionRight];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
            }
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self invalidatesScrollTimer];
        } break;
        default: {
            // Do nothing...
        } break;
    }
}

#pragma mark - UICollectionViewLayout overridden methods

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesForElementsInRect) {
        switch (layoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell: {
                [self applyLayoutAttributes:layoutAttributes];
            } break;
            default: {
                // Do nothing...
            } break;
        }
    }
    
    return layoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
            [self applyLayoutAttributes:layoutAttributes];
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    return layoutAttributes;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    return NO;
}

#pragma mark - Key-Value Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kLXCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        } else {
            [self invalidatesScrollTimer];
        }
    }
}

#pragma mark - Notifications

- (void)handleApplicationWillResignActive:(NSNotification *)notification {
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
}

#pragma mark - Depreciated methods

#pragma mark Starting from 0.1.0
- (void)setUpGestureRecognizersOnCollectionView {
    // Do nothing...
}

@end
