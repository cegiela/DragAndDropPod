//
//  DDItem.swift
//  Pods
//
//  Created by Mat Cegiela on 5/13/17.
//
//

import UIKit

public protocol DDItemDelegate {
    
    func ddItemDragUpdate(_ item: DDItem)
    func ddItemCanDrop(_ item: DDItem) -> Bool
    func ddItemDropOffset(_ item: DDItem) -> CGPoint
    func ddItemDidDrop(_ item: DDItem, success: Bool)
}

public protocol DDAnimationDelegate {
    //animationForPickUp
    //animationForTransit (?)
    //animationForDrop
}

public class DDItem: NSObject {
    
    private override init() {}
    
    fileprivate var displayLink : CADisplayLink?
    public var payload: AnyObject!
    public var transitView: UIView!
    public var sharedSuperview: UIView!
    public var delegate: DDItemDelegate!
    public var originCenter = CGPoint()
//    public var originOffset = CGPoint() //Set if the origin view scrolls during drag
    
    public var touchLocation = CGPoint()
    public var pickupOffset = CGPoint(x: 0.0, y: -4.0)
    public var pickupScale = CGSize(width: 1.1, height: 1.1)

    public init(payload: AnyObject, transitView: UIView, sharedSuperview: UIView, delegate: DDItemDelegate) {
        super.init()
        
        self.delegate = delegate
        self.payload = payload
        self.transitView = transitView
        self.sharedSuperview = sharedSuperview
    }
    
    func updateWithGesture(_ gesture: UILongPressGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            
            originCenter = transitView.center
            touchLocation = gesture.location(in: sharedSuperview)

            animatePickup(completion: {
                self.beginDisplayUpdates()
            })
            break
            
        case .changed:
            
            touchLocation = gesture.location(in: sharedSuperview)
            break
            
        case .ended:
            
            endDisplayUpdates()
            
            if delegate.ddItemCanDrop(self) {
                animateDrop(completion: {
                    delegate.ddItemDidDrop(self, success: true)
                })
            } else {
                animateCancel(completion: {
                    delegate.ddItemDidDrop(self, success: false)
                })
            }
            break
            
        default:
            break
        }
    }
    
    func animatePickup(completion: @escaping () -> ())  {
        
        sharedSuperview.addSubview(transitView)
        
        UIView.animate(withDuration: 0.1, animations: {
            
            self.transitView.center = self.touchLocation
            self.transitView.transform = CGAffineTransform(scaleX: self.pickupScale.width, y: self.pickupScale.height)
            self.transitView.alpha = 0.5

        }) { (finished) in
            completion()
        }
    }
    
    func animateNewLocation(completion: () -> ()) {
        delegate.ddItemDragUpdate(self)
    }
    
    func animateDrop(completion: () -> ()) {
        
        let dropOffset = delegate.ddItemDropOffset(self)
        let center = CGPoint(x: transitView.center.x + dropOffset.x, y: transitView.center.y + dropOffset.y)
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
            self.transitView.center = center
            self.transitView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }) { (finished) in
            self.transitView.removeFromSuperview()
        }
    }
    
    func animateCancel(completion: () -> ()) {
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.transitView.center = self.originCenter
            self.transitView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }) { (finished) in
            self.transitView.removeFromSuperview()
        }
    }
}

public extension DDItem {
    
    fileprivate func beginDisplayUpdates() {
        
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(DDItem.updateDisplay))
        displayLink?.add(to: .current, forMode: .defaultRunLoopMode)
    }
    
    fileprivate func endDisplayUpdates() {
        
        displayLink?.invalidate()
    }
    
    func updateDisplay(displaylink: CADisplayLink) {
        self.transitView.center = self.touchLocation
    }
}
