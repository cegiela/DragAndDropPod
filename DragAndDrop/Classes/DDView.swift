//
//  DDView.swift
//  Pods
//
//  Created by Mat Cegiela on 5/13/17.
//
//

import UIKit

public protocol DDViewDelegate {
    
    func ddView(_ view: DDView, itemForDragAttemptAt point: CGPoint) -> DDItem?
    
//    func payloadForDragAt(point: CGPoint, in view: UIView) -> AnyObject?
//    func transitViewForDragAt(point: CGPoint, in view: UIView) -> UIView
//    func sharedSuperviewForDragAt(point: CGPoint, in view: UIView) -> UIView
//    func dropDelegateForDragAt(point: CGPoint, in view: UIView) -> DDItemDelegate
//    func willDrag(_ item: DDItem)
}

public class DDView: UIView {

    public var delegate: DDViewDelegate?
    public let gestureRecogniser = UILongPressGestureRecognizer()
    public var activeDragAndDropItem: DDItem?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        didLoad()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didLoad()
    }
    
    func didLoad() {
        gestureRecogniser.addTarget(self, action: #selector(DDView.gestureUpdate(_:)))
        gestureRecogniser.minimumPressDuration = 0.3
        self.addGestureRecognizer(gestureRecogniser)
    }
    
    func gestureUpdate(_ gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            let location = gesture.location(in: self)
            beginPossibleDragAndDrop(location)
        }
        
        activeDragAndDropItem?.updateWithGesture(gesture)
    }
    
    func beginPossibleDragAndDrop(_ location: CGPoint) {
        
        if let delegate = delegate {
//            if let payload = delegate.payloadForDragAt(point: location, in: self) {
//                let transitView = delegate.transitViewForDragAt(point: location, in: self)
//                let sharedSuperview = delegate.sharedSuperviewForDragAt(point: location, in: self)
//                let dropDelegate = delegate.dropDelegateForDragAt(point: location, in: self)
//                
//                let item = DDItem(payload: payload,
//                                  transitView: transitView,
//                                  sharedSuperview: sharedSuperview,
//                                  delegate: dropDelegate)
//                
//                delegate.willDrag(item)
//                activeDragAndDropItem = item
//            }
            let item = delegate.ddView(self, itemForDragAttemptAt: location)
            activeDragAndDropItem = item
        }
    }
    
    func snapShot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
