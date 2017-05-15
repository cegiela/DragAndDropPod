//
//  ViewController.swift
//  DragAndDrop
//
//  Created by encodery@gmail.com on 05/13/2017.
//  Copyright (c) 2017 encodery@gmail.com. All rights reserved.
//

import UIKit
import DragAndDrop

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = "\(DragAndDropCoordinator.testVal)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
