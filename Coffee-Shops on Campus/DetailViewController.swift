//
//  DetailViewController.swift
//  Coffee-Shops on Campus
//
//  Created by Rushworth, Ashley on 26/11/2019.
//  Copyright © 2019 Rushworth, Ashley. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    var coffeeShop = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        id.text = coffeeShop
    }
    
    @IBOutlet weak var id: UILabel!
}
