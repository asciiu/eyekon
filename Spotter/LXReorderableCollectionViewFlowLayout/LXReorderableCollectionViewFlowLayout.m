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

@property (assign, nonatomic) CGRect parentRect;
@property (assign, nonatomic) CGRect previousRect;
@property (assign, nonatomic) NSArray *sectionPaths;
@property (assign, nonatomic) BOOL moving;
@property (assign, nonatomic) BOOL resizing;
@property (assign, nonatomic) CGSize previousSize;

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
    self.shadowView.alpha = 0.35;

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

    float height = floorf(totalWidth / r);
    float x = 0;
    float y = [[rects objectAtIndex:0] CGRectValue].origin.y;
    
    for(int j = 0; j < rects.count; ++j) {
        CGRect rect = [[rects objectAtIndex:j] CGRectValue];
        
        float imageWidth = rect.size.width;
        float imageHeight = rect.size.height;
        float width = floorf(height * imageWidth / imageHeight);

        if (j != rects.count - 1) {
            totalWidth -= width;
        } else {
            // last rect should fill the width
            width = totalWidth;
        }
        
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

- (void)resizeIndexPath:(NSIndexPath *)indexPath rect:(CGRect)newRect withScroll:(BOOL)scroll {
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    UICollectionViewLayoutAttributes *attrs = [self layoutAttributesForItemAtIndexPath:indexPath];
    
    CGSize newSize = newRect.size;
    //CGSize oldSize = cell.frame.size;
    CGSize oldSize = attrs.frame.size;
    CGFloat diff = oldSize.height - newSize.height;
    
    if (diff == 0) {
        return;
    }
    
    _resizing = YES;
    CGPoint offset = self.collectionView.contentOffset;
    offset = CGPointMake(offset.x, offset.y-diff);
    
    //CGSize contentSize = [self collectionViewContentSize];
    //self.collectionView.contentSize = CGSizeMake(contentSize.width, contentSize.height - diff);
    
    cell.contentView.autoresizesSubviews = YES;

    [UIView animateWithDuration:0.3 animations:^{

        [self.collectionView performBatchUpdates:^{
            cell.frame = newRect;
            
            if (scroll) {
                self.collectionView.contentOffset = offset;
            }

        } completion:^(BOOL finished) {
        
            cell.contentView.autoresizesSubviews = NO;
            _resizing = NO;
        }];
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

- (void)invalidateLayoutAtIndexPaths:(NSArray *)indexPaths withScroll:(BOOL)scroll {

    NSArray *newRects = [self resizePathRectsToFitWidth:indexPaths];
    
    for (int j = 0; j < indexPaths.count; ++j) {
        NSIndexPath *path = indexPaths[j];
        CGRect reducedRect = [newRects[j] CGRectValue];
        
        // only scroll the first item
        if (j != 0 && scroll) {
            scroll = NO;
        }

        [self resizeIndexPath:path rect:reducedRect withScroll:scroll];
    }
}

- (void)invalidateLayoutIfNecessary {

    if (_resizing || _moving) {
        return;
    }
    
    // default new index path comes from the collection view
    CGPoint currentPoint = [self.collectionView.superview convertPoint:self.currentView.center
                                                         toView:self.collectionView];
    NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:currentPoint];

    NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
    //CGRect targetRect = [self layoutAttributesForItemAtIndexPath:newIndexPath].frame;
    BOOL flag = false;
    
    // if the delegate implements this method ask for the new index path
    if (newIndexPath == nil) {
        flag = true;
        
        CGSize superSize = [super collectionViewContentSize];
        
        // if we are beyond the content bounds expand to full width
        if (currentPoint.y >= superSize.height) {
            NSInteger section = self.collectionView.numberOfSections;
            NSInteger items = [self.collectionView numberOfItemsInSection:section-1];
            
            newIndexPath = [NSIndexPath indexPathForRow:items-1 inSection:section-1];
            
            NSArray *rects = [self resizePathRectsToFitWidth:@[previousIndexPath]];
            [self.dataSource itemAtIndexPath:previousIndexPath didResize:[rects[0] CGRectValue].size];
            
            _sectionPaths = [self indexPathsInRect:self.parentRect];
            [self invalidateLayoutAtIndexPaths:_sectionPaths withScroll:YES];
            
            if ([newIndexPath isEqual:previousIndexPath]) {
                CGRect shadowRect = [self layoutAttributesForItemAtIndexPath:previousIndexPath].frame;
                
                self.shadowView.frame = shadowRect;
                self.shadowView.hidden = false;
            }
        }
    }
    
    if ((newIndexPath == nil) || [newIndexPath isEqual:previousIndexPath] || CGRectContainsPoint(self.targetRect, currentPoint)) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
        ![self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath]) {
        return;
    }
    
    NSMutableArray *paths;
    BOOL scroll = NO;
    NSMutableArray *newRects;
    
    // if we are not in the original rect
    if (!CGRectContainsPoint(self.parentRect, currentPoint) && !flag) {
        
        // get all paths in the section that we are leaving
        NSMutableArray *previousPaths = [self indexPathsInRect:self.parentRect].mutableCopy;
        for (int i = 0; i < previousPaths.count; ++i) {
            NSIndexPath *path = previousPaths[i];
            if([path compare:self.selectedItemIndexPath] == NSOrderedSame) {
                [previousPaths removeObject:path];
            }
        }
        
        // get paths in new section rect
        CGRect sectionRect = [self sectionRectForIndexPath:newIndexPath];
        paths = [self indexPathsInRect:sectionRect].mutableCopy;
        
        // resize the remaining items in the section that we are leaving
        if (previousPaths.count > 0) {
            
            if (newIndexPath.row > previousIndexPath.row) {
                scroll = YES;
            }
            
            [paths addObject:self.selectedItemIndexPath];
            newRects = [self resizePathRectsToFitWidth:paths].mutableCopy;
            
            [self invalidateLayoutAtIndexPaths:previousPaths withScroll:scroll];
            
            // resize the new paths items in the new rect
            for( int i = 0; i < paths.count-1; ++i) {
                NSIndexPath *path = paths[i];
                
                // we only want to scroll the first item
                if (i == 0 && !scroll) {
                    [self resizeIndexPath:path rect:[newRects[i] CGRectValue] withScroll:YES];
                } else {
                    [self resizeIndexPath:path rect:[newRects[i] CGRectValue] withScroll:NO];
                }
            }
            
            CGSize selectedSize = [newRects.lastObject CGRectValue].size;
            [self.dataSource itemAtIndexPath:self.selectedItemIndexPath didResize:selectedSize];
        } else {
            // we are attempting to move a single item that spans the width, do not resize it!
            if (newIndexPath.row > previousIndexPath.row) {
                newIndexPath = paths.lastObject;
            } else {
                newIndexPath = paths.firstObject;
            }
        }
    }
    
    if ([self.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [self.dataSource collectionView:self.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:newIndexPath];
    }
    
    _selectedItemIndexPath = newIndexPath;
    _targetRect = [self layoutAttributesForItemAtIndexPath:newIndexPath].frame;
    _moving = YES;
    
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            _shadowView.hidden = YES;
            [strongSelf.collectionView moveItemAtIndexPath:previousIndexPath toIndexPath:newIndexPath];
        }
    } completion:^(BOOL finished) {

        // new index path rect has changed update it
        CGRect sectionRect = [self sectionRectForIndexPath:newIndexPath];
        _parentRect = sectionRect;
        
        // move finished
        if (!CGRectEqualToRect(self.targetRect, CGRectZero)) {
            CGRect shadowRect = [self layoutAttributesForItemAtIndexPath:newIndexPath].frame;
            
            _shadowView.frame = shadowRect;
            _shadowView.hidden = NO;
        }
        
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf.dataSource respondsToSelector:@selector(collectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            [strongSelf.dataSource collectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath didMoveToIndexPath:newIndexPath];
        }
        
        _moving = NO;
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
    
    //self.currentViewCenter = LXS_CGPointAdd(self.currentViewCenter, translation);
    //self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);
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
            
            _previousSize = self.collectionViewContentSize;
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            // the cell frame must be translated to the parent coordinate system
            CGRect cellFrame = [self.collectionView.superview convertRect:collectionViewCell.frame
                                                                 fromView:self.collectionView];
            
            self.currentView = [[UIView alloc] initWithFrame:cellFrame];
            self.previousRect = collectionViewCell.frame;
            self.parentRect = CGRectMake(0, self.previousRect.origin.y, self.collectionViewContentSize.width, self.previousRect.size.height);
            
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
            // the current view belongs in the parent view of the collection view
            [[self.collectionView superview] addSubview:self.currentView];
            //[self.collectionView addSubview:self.currentView];
            
            CGPoint coords = [gestureRecognizer locationInView:gestureRecognizer.view.superview];
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
                
                self.previousSize = CGSizeZero;
                self.selectedItemIndexPath = nil;
                self.currentViewCenter = CGPointZero;
                self.targetRect = CGRectZero;
                self.shadowView.hidden = true;
                self.parentRect = CGRectZero;
                
//                NSArray *attributes = [self layoutAttributesForElementsInRect:self.originRect];
//                NSMutableArray *paths = [NSMutableArray arrayWithCapacity:attributes.count];
//
//                for (UICollectionViewLayoutAttributes *attrs in attributes) {
//                    [paths addObject:attrs.indexPath];
//                }
//                
//                // if release point of currentView is not in the original rect
//                CGPoint point = [self.collectionView convertPoint:self.currentView.center fromView:self.collectionView.superview];
//                if (!CGRectContainsPoint(self.originRect, point) && paths.count > 0) {
//                    [self invalidateLayoutAtIndexPaths:paths];
//                }
                
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
            
            self.currentView.center = LXS_CGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView);

            CGPoint viewCenter = [self.collectionView convertPoint:self.currentView.center
                                                          fromView:self.collectionView.superview];
            
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

- (CGSize)collectionViewContentSize {
    CGSize size = [super collectionViewContentSize];
    CGFloat minHeight = self.collectionView.superview.frame.size.height;
    
    if (size.height < minHeight) {
        size = CGSizeMake(size.width, minHeight);
    } else {
        size = CGSizeMake(size.width, size.height + minHeight/2);
    }
    
    return size;
}

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
