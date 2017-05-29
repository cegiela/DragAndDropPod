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
    var string: String = ""
    var x: Int = 0
    var y: Int = 0
    var color: UIColor = UIColor.lightGray
    
    init(_ string: String, x: Int, y: Int) {
        self.string = string
    }
    
    static func exampleArray() -> [ExampleModel] {
        var array = [ExampleModel]()
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".characters.flatMap { $0.description }
        for letter in alphabet {
            var item = ExampleModel(letter, x: 0, y: 0)
            if letter == "B" { item.x = 2; item.y = 2 }
            if letter == "C" { item.x = 4; item.y = 4 }
            array.append(item)
        }
        return array
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var collectionViewOne: DDCollectionView!
    @IBOutlet weak var collectionViewTwo: UICollectionView!
    
    @IBOutlet weak var viewOne: DDView!
    @IBOutlet weak var viewTwo: DDView!
    
    @IBOutlet weak var layoutSwitch: UISwitch!
    
    let gridLayout = DDCollectionViewGridLayout()
    let flowLayout = UICollectionViewFlowLayout()
    let modelArray = ExampleModel.exampleArray()

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = "test"
        
        viewOne.delegate = self
        viewTwo.delegate = self
        
        collectionViewOne.delegate = self
        collectionViewOne.dataSource = self
        gridLayout.layoutDelegate = self
        layoutSwitchAction(self)
    }
    
    @IBAction func layoutSwitchAction(_ sender: Any) {
//        collectionViewOne.collectionViewLayout = layoutSwitch.isOn ? gridLayout : flowLayout
        collectionViewOne.setCollectionViewLayout(layoutSwitch.isOn ? gridLayout : flowLayout, animated: true) { (finished) in
            ///
        }
    }
}

extension ViewController: DDCollectionViewGridLayoutDelegate {
    
    func collectionView(_ collectionView:UICollectionView, sizeOfItemAt indexPath:IndexPath) -> CGSize {
        return CGSize(width: 50.0, height: 50.0)
    }
    
    func collectionView(_ collectionView:UICollectionView, gridLayoutPositionFor indexPath:IndexPath) -> GridLayoutPosition {
        let item = modelArray[indexPath.row]
        return GridLayoutPosition(x: item.x, y: item.y)
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return modelArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionViewOne.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ExampleCollectionViewCell
        cell.label.text = modelArray[indexPath.row].string
        return cell
    }
}

extension ViewController: DDViewDelegate, DDItemDelegate {
    
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
