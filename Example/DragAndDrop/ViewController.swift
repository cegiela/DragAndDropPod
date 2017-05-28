//
//  ViewController.swift
//  DragAndDrop
//
//  Created by encodery@gmail.com on 05/13/2017.
//  Copyright (c) 2017 encodery@gmail.com. All rights reserved.
//

import UIKit
import DragAndDrop

struct ExampleModel {
    var letter: String = ""
    var xPosition: Int = 0
    var yPosition: Int = 0
    var color: UIColor = UIColor.lightGray
    
    static func randomDistribution() -> [ExampleModel] {
        return [ExampleModel]()
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var collectionViewOne: UICollectionView!
    @IBOutlet weak var collectionViewTwo: UICollectionView!
    
    @IBOutlet weak var viewOne: DDView!
    @IBOutlet weak var viewTwo: DDView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = "test"
        
        viewOne.delegate = self
        viewTwo.delegate = self
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionViewOne.dequeueReusableCell(withReuseIdentifier: "", for: indexPath)
        return cell
    }
}

extension ViewController: DDViewDelegate {
    
    func ddView(_ view: DDView, itemForDragAttemptAt point: CGPoint) -> DDItem? {

        if let transitView = view.snapshotView(afterScreenUpdates: true) {
            let payload = view == viewOne ? "One" : "Two"
            return DDItem(payload: payload as AnyObject,
                          transitView:transitView,
                          sharedSuperview: view,
                          delegate: self)
        }
        
        return nil
    }
}

extension ViewController: DDItemDelegate {
    
    func ddItemDragUpdate(_ item: DDItem) {
        ///
    }
    
    func ddItemCanDrop(_ item: DDItem) -> Bool {
        return item.payload as? String == "One"
    }
    
    func ddItemDropOffset(_ item: DDItem) -> CGPoint {
        return CGPoint()
    }
    
    func ddItemDidDrop(_ item: DDItem, success: Bool) {
        ///
    }
}
