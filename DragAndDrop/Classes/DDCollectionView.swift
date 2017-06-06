//
//  DDCollectionView.swift
//  Pods
//
//  Created by Mat Cegiela on 5/13/17.
//
//

import UIKit

public class DDCollectionView: UICollectionView {

    public var dragAndDropDelegate: DDItemDelegate?
    public let dragAndDropGestureRecogniser = UILongPressGestureRecognizer()
    public var nativeDragAndDropItem: DDItem?
    
//    public var autoScrollsWhileDragging = true
    public var autoScrollZone = UIEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0)
    public var autoScrollDragSpeedCutoff = CGFloat(500.0)//UIEdgeInsets(top: 500.0, left: 500.0, bottom: 500.0, right: 500.0)
    public var autoScrollSpeedLimit = UIEdgeInsets(top: 100.0, left: 100.0, bottom: 100.0, right: 100.0)
    //In points per second
    public var autoScrollBoundsStretchLimit = UIEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0)
    
    private var lastKnownTouchLocation: CGPoint?
    private var autoScrollSpeed = CGPoint()
    private var lockHorizontalAutoScroll = false
    private var lockVerticalAutoScroll = false
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        
        super.init(frame: frame, collectionViewLayout: layout)
        configureAfterInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        configureAfterInit()
    }
    
    func configureAfterInit() {
        
        dragAndDropGestureRecogniser.addTarget(self, action: #selector(DDView.gestureUpdate(_:)))
        dragAndDropGestureRecogniser.minimumPressDuration = 0.3
        self.addGestureRecognizer(dragAndDropGestureRecogniser)
    }
    
    func gestureUpdate(_ gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            let location = gesture.location(in: self)
            beginPossibleDragAndDrop(location)
        }
        
        nativeDragAndDropItem?.updateWithGesture(gesture)

        if gesture.state == .ended {
            nativeDragAndDropItem = nil
        }
    }
    
    func beginPossibleDragAndDrop(_ location: CGPoint) {
        
        guard
            let ddDelegate = dragAndDropDelegate,
            let indexPath = indexPathForItem(at: location),
            let attributes = collectionViewLayout.layoutAttributesForItem(at: indexPath),
            let cell = cellForItem(at: indexPath),
            let transitView = cell.snapshotView(afterScreenUpdates: false)
        else {
            return
        }
        
        let superview = DDView.rootSuperviewFor(self)
        let frame = self.convert(attributes.frame, to: superview)
        transitView.frame = frame
        let item = DDItem(transitView: transitView, sharedSuperview: superview, delegate: ddDelegate)
        if ddDelegate.ddItemCanDrag(item, originView: self) {
            nativeDragAndDropItem = item
        }
    }
    
    public func autoScrollForDragItem(_ item: DDItem) {
        
        if item.isCompleted {
            resetToBounds()
            return
        }
        
        let localCoordinateTouch = item.sharedSuperview.convert(item.touchLocation, to: self)
        
        if lastKnownTouchLocation == nil {
            
            //Assume this is a new drag and drop action
            
            //If touch began outside of the non-autoScroll zone (center region),
            //lock autoScroll untill after the user drags into the center region
            let width = frame.size.width - contentInset.right
            if (localCoordinateTouch.x < autoScrollZone.left ||
                localCoordinateTouch.x > width - autoScrollZone.right)
            {
                lockHorizontalAutoScroll = true
            }
            let height = frame.size.height - contentInset.bottom
            if (localCoordinateTouch.y < autoScrollZone.top ||
                localCoordinateTouch.y > height - autoScrollZone.bottom)
            {
                lockVerticalAutoScroll = true
            }
        }
        
        if localCoordinateTouch != lastKnownTouchLocation {
            lastKnownTouchLocation = localCoordinateTouch
            recalculateAutoScrollSpeedAndDirectionForDragItem(item)
        }
        
        updateContentOffsetForDragItem(item)
    }
    
    private func recalculateAutoScrollSpeedAndDirectionForDragItem(_ item: DDItem) {
        
        guard let touchLocation = lastKnownTouchLocation else { return }
        
        autoScrollSpeed = CGPoint.zero
        
        let leftThreshold = autoScrollZone.left + contentInset.left
        let rightThreshold = frame.size.width - autoScrollZone.right - contentInset.right
        let topThreshold = autoScrollZone.top + contentInset.top
        let bottomThreshold = frame.size.height - autoScrollZone.bottom - contentInset.bottom
        
        //Check if touch is located in any autoScroll zones, 
        //if it is, calculate scroll speed based on how close it is to the edge of view
        
        //Left or
        if (touchLocation.x < leftThreshold) {
            if (touchLocation.x > leftThreshold - autoScrollZone.left) {
                
                //Factor scroll speed by proximity to outer edge
                let distance_X = leftThreshold - touchLocation.x
                let factor = distance_X / autoScrollZone.left
                autoScrollSpeed.x = -throttleSpeed(autoScrollSpeedLimit.left, factor: factor)
                
                //Prevent scrolling beyond the bounds stretch limit
                if (-contentOffset.x - contentInset.left) >= autoScrollBoundsStretchLimit.left {
                    autoScrollSpeed.x = 0.0
                }
            }
        }
        
        //Right
        else if (touchLocation.x > rightThreshold) {
            if (touchLocation.x < rightThreshold + autoScrollZone.right) {
                
                //Factor scroll speed by proximity to outer edge
                let distance_X = touchLocation.x - rightThreshold
                let factor = distance_X / autoScrollZone.right
                autoScrollSpeed.x = throttleSpeed(autoScrollSpeedLimit.right, factor: factor)
                
                //Prevent scrolling beyond the bounds stretch limit
                if (contentOffset.x + bounds.size.width) - contentSize.width + contentInset.right >=
                    autoScrollBoundsStretchLimit.right {
                    autoScrollSpeed.x = 0.0
                }
            }
        }
        else {
            //Touch is now in the non-autoScroll zone (center region), unlock any future autoScroll
            lockHorizontalAutoScroll = false
        }
        
        //Top or
        if (touchLocation.y < topThreshold) {
            if (touchLocation.y > topThreshold - autoScrollZone.top) {
                
                //Factor scroll speed by proximity to outer edge
                let distance_Y = topThreshold - touchLocation.y
                let factor = distance_Y / autoScrollZone.top
                autoScrollSpeed.y = -throttleSpeed(autoScrollSpeedLimit.top, factor: factor)
                
                //Prevent scrolling beyond the bounds stretch limit
                if (-contentOffset.y - contentInset.top) >= autoScrollBoundsStretchLimit.top {
                    autoScrollSpeed.y = 0.0
                }
            }
        }
        
        //Bottom
        else if (touchLocation.y > bottomThreshold) {
            if (touchLocation.y < bottomThreshold + autoScrollZone.bottom) {
                
                //Factor scroll speed by proximity to outer edge
                let distance_Y = touchLocation.y - bottomThreshold
                let factor = distance_Y / autoScrollZone.bottom
                autoScrollSpeed.y = throttleSpeed(autoScrollSpeedLimit.bottom, factor: factor)
                
                //Prevent scrolling beyond the bounds stretch limit
                if (contentOffset.y + bounds.size.height) - contentSize.height + contentInset.bottom >=
                    autoScrollBoundsStretchLimit.bottom {
                    autoScrollSpeed.y = 0.0
                }
            }
        }
        else {
            //Touch is now in the non-autoScroll zone (center region), unlock any future autoScroll
            lockVerticalAutoScroll = false
        }
        
//        print(currentAutoScrollSpeed)
    }
    
    private func updateContentOffsetForDragItem(_ item: DDItem) {
        ///Scroll self according to autoScroll speed
        
//        guard let touchLocation = lastKnownTouchLocation else { return }
        
        
        //////!!!!!///////
        // Include checks for scroll locks, which was done elswhere before
        // Include checks for velocity
        
        //NOTE: When the touch velocity is high,
        //we can assume the user is dragging out of this collection view.
        //We can forgo AutoScroll to make a smother experience.
        //Cancel AutoScroll if touch is travelling at high speed.
        
        if item.touchVelocity > autoScrollDragSpeedCutoff { return }
        
        /*
         CGPoint currentContentOffset = self.collectionView.contentOffset;
         CGSize contentSize = self.collectionView.contentSize;
         CGRect bounds = self.collectionView.bounds;
         UIEdgeInsets insets = self.collectionView.contentInset;
         
         contentSize.height += insets.top + insets.bottom;
         contentSize.width += insets.left + insets.right;
         
         //Determine if we're out of bounds
         
         CGFloat overscroll_X = 0.f;
         CGFloat overscroll_Y = 0.f;
         
         if (currentContentOffset.x + insets.left < 0 && _dragScrollSpeed.x < 0)
         {
         overscroll_X = -currentContentOffset.x - insets.left;
         }
         
         else if (currentContentOffset.x + bounds.size.width - insets.right > contentSize.width && _dragScrollSpeed.x > 0)
         {
         overscroll_X = (currentContentOffset.x + bounds.size.width) - contentSize.width + insets.right;
         }
         
         if (currentContentOffset.y + insets.top < 0 && _dragScrollSpeed.y < 0)
         {
         overscroll_Y = -currentContentOffset.y - insets.top;
         }
         
         else if (currentContentOffset.y + bounds.size.height > contentSize.height && _dragScrollSpeed.y > 0)
         {
         overscroll_Y = (currentContentOffset.y + bounds.size.height) - contentSize.height;
         }
         
         //Factor speed by distance out of bounds, slowing to a halt as it gets to maxOverscroll
         CGFloat factoredSpeed_X = _dragScrollSpeed.x * factorByOverscroll(overscroll_X, maxOverscroll.x);
         CGFloat factoredSpeed_Y = _dragScrollSpeed.y * factorByOverscroll(overscroll_Y, maxOverscroll.y);
         
         //Calculate distance to scroll
         CGPoint distanceToScroll = CGPointMake(factoredSpeed_X, factoredSpeed_Y);
         CGPoint newOffset = pointAplusB(currentContentOffset, distanceToScroll);
         
         //Scroll calculated distance
         self.collectionView.contentOffset = newOffset;
         */
        
        //TODO: Speed should probably be calculated based on framerate of CADisplayLink
        
        if item.frameRate == 0.0 { return }
        
        let scrollSpeedX = lockHorizontalAutoScroll ? 0.0 : autoScrollSpeed.x
        let scrollSpeedY = lockVerticalAutoScroll ? 0.0 : autoScrollSpeed.y
        let delta = CGPoint(x: scrollSpeedX / item.frameRate, y: scrollSpeedY / item.frameRate)
        let newOffset = CGPoint(x: contentOffset.x + delta.x, y: contentOffset.y + delta.y)
        contentOffset = newOffset
//        if delta != CGPoint.zero {
//            print("\(delta.x)" + " " + "\(delta.y)")
//        }
    }
    
    private func resetToBounds() {
        
        /*
        CGRect bounds = self.collectionView.bounds;
        CGPoint offset = self.collectionView.contentOffset;
        UIEdgeInsets insets = self.collectionView.contentInset;
        CGSize contentSize = self.collectionView.contentSize;
        CGFloat rightEdge = offset.x + bounds.size.width;
        CGFloat bottomEdge = offset.y + bounds.size.height + insets.bottom;
        
        contentSize.height += insets.top + insets.bottom;
        contentSize.width += insets.left + insets.right;
        
        BOOL overscrolled = NO;
        
        if (offset.x < 0)
        {
            overscrolled = YES;
            offset.x = 0 - insets.left;
        }
        else if (rightEdge > contentSize.width)
        {
            overscrolled = YES;
            offset.x = contentSize.width - bounds.size.width;
        }
        
        if (offset.y < 0)
        {
            overscrolled = YES;
            offset.y = 0 - insets.top;
        }
        else if (bottomEdge > contentSize.height)
        {
            overscrolled = YES;
            offset.y = contentSize.height - bounds.size.height;
        }
        
        if (overscrolled)
        {
            [self.collectionView setContentOffset:offset animated:YES];
        }
        */
        
    }
}

extension DDCollectionView {
    
    func throttleSpeed(_ maxSpeed: CGFloat, factor: CGFloat) -> CGFloat {
        return min(maxSpeed, maxSpeed * factor);
    }
}
