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
            if letter == "B" { item.x = 1; item.y = 2 }
            if letter == "C" { item.x = 4; item.y = 4 }
            if letter == "D" { item.x = 4; item.y = 8 }
            if letter == "E" { item.x = 1; item.y = 5 }
            if letter == "F" { item.x = 2; item.y = 3 }
            if letter == "G" { item.x = 6; item.y = 2 }
            if letter == "I" { item.x = 2; item.y = 4 }
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
    var gridPositions = [GridLayoutPosition : ExampleModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = "test"
        
        viewOne.dragAndDropDelegate = self
        viewTwo.dragAndDropDelegate = self
        
        collectionViewOne.delegate = self
        collectionViewOne.dataSource = self
        collectionViewOne.dragAndDropDelegate = self
        gridLayout.layoutDelegate = self
        gridLayout.defaultItemSize = CGSize(width: 50.0, height: 50.0)
        flowLayout.sectionInset = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0)
        flowLayout.minimumInteritemSpacing = 8.0
        
        layoutSwitchAction(self)
    }
    
    @IBAction func layoutSwitchAction(_ sender: Any) {
        collectionViewOne.setCollectionViewLayout(layoutSwitch.isOn ? gridLayout : flowLayout, animated: true) { (finished) in
            ///
        }
    }
}

extension ViewController: DDCollectionViewDelegateGridLayout, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        if indexPath.row == 5 { return CGSize(width: 100.0, height: 100.0) }
        return CGSize(width: 50.0, height: 50.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, gridLayoutPositionFor indexPath: IndexPath) -> GridLayoutPosition {
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

extension ViewController: DDItemDelegate {
    
    func ddItemCanDrag(_ item: DDItem, originView: UIView) -> Bool {
        item.payload = "One" as AnyObject
        return true
    }
    
    func ddItemActiveDragUpdate(_ item: DDItem) {
        collectionViewOne.autoScrollForDragItem(item)
    }
    
    func ddItemCanDrop(_ item: DDItem) -> Bool {
        return item.payload as? String == "One"
    }
    
    func ddItemDidDrop(_ item: DDItem, success: Bool) {
        collectionViewOne.autoScrollForDragItem(item)
    }
}
