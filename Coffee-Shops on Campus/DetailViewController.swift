//
//  DetailViewController.swift
//  Coffee-Shops on Campus
//
//  Created by Rushworth, Ashley on 26/11/2019.
//  Copyright © 2019 Rushworth, Ashley. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var id: UILabel!
    
    var aShop: coffeeShop?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateCoffeeShopDetails() {
            DispatchQueue.main.async {
                self.id.text = self.aShop?.details?.url
            }
            
        }
    }
    
    func populateCoffeeShopDetails(callback: @escaping () -> Void) {
        if let url = URL(string: "https://dentistry.liverpool.ac.uk/_ajax/coffee/info/?id=1") {
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else {
                    return
                }
                do {
                    // decode JSON
                    let decoder = JSONDecoder()
                    let aShopDetails = try decoder.decode(coffeeOnCampusDetails.self, from: jsonData)
                    self.aShop?.details = aShopDetails.data
                } catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                }
                callback()
            }.resume()
        }
    }
}
