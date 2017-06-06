//
//  DDView.swift
//  Pods
//
//  Created by Mat Cegiela on 5/13/17.
//
//

import UIKit

//public protocol DDViewDelegate {
//    
//    func ddView(_ ddView: UIView, itemForDragAttemptAt point: CGPoint, transitView: UIView) -> DDItem?
//    func ddView(_ ddView: UIView, canDrag item: DDItem) -> Bool
//}

public class DDView: UIView {

    public var dragAndDropDelegate: DDItemDelegate?
    public let dragAndDropGestureRecogniser = UILongPressGestureRecognizer()
    public var activeDragAndDropItem: DDItem?
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
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
        
        activeDragAndDropItem?.updateWithGesture(gesture)
        
        if gesture.state == .ended {
            activeDragAndDropItem = nil
        }
    }
    
    func beginPossibleDragAndDrop(_ location: CGPoint) {
        
        if let ddDelegate = dragAndDropDelegate, let transitView = self.snapshotView(afterScreenUpdates: false) {
            
            let superview = DDView.rootSuperviewFor(self)
            let center = self.superview?.convert(self.center, to: superview)
            transitView.center = center ?? CGPoint()
            let item = DDItem(transitView: transitView, sharedSuperview: superview, delegate: ddDelegate)
            if ddDelegate.ddItemCanDrag(item, originView: self) {
                activeDragAndDropItem = item
            }
        }
    }
    
    public func activeDragUpdate(_ item: DDItem) {
        ///auto-scroll if needed
    }
}

extension DDView {
    
    class func rootSuperviewFor(_ view: UIView) -> UIView {
        if let superview = view.superview {
            if type(of: superview) == UIView.self {
                return rootSuperviewFor(superview)
            } else {
                return view
            }
        } else {
            return view
        }
    }
}
