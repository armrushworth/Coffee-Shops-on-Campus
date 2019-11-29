//
//  DetailViewController.swift
//  Coffee-Shops on Campus
//
//  Created by Rushworth, Ashley on 26/11/2019.
//  Copyright © 2019 Rushworth, Ashley. All rights reserved.
//

import CoreData
import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var id: UILabel!
    
    // core data
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    
    var aShop: coffeeShop?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // populate coffee shops array
        context = appDelegate.persistentContainer.viewContext
        populateCoffeeShopDetails() {
            DispatchQueue.main.async {
                self.id.text = self.aShop?.details?.url
            }
        }
    }
    
    func populateCoffeeShopDetails(callback: @escaping () -> Void) {
        if let url = URL(string: "https://dentistry.liverpool.ac.uk/_ajax/cofee/info/?id=\(aShop!.id)") {
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
                    
                    // add coffee shop details to core data
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoffeeShops")
                    fetchRequest.predicate = NSPredicate(format: "id = %@", self.aShop!.id)

                    if let fetchResults = try self.context!.fetch(fetchRequest) as? [NSManagedObject] {
                        if fetchResults.count != 0{

                            let managedObject = fetchResults[0]
                            managedObject.setValue(aShopDetails.data.url, forKey: "url")
                            managedObject.setValue(aShopDetails.data.photo_url, forKey: "photo_url")
                            managedObject.setValue(aShopDetails.data.phone_number, forKey: "phone_number")
                            managedObject.setValue(aShopDetails.data.monday, forKey: "monday")
                            managedObject.setValue(aShopDetails.data.tuesday, forKey: "tuesday")
                            managedObject.setValue(aShopDetails.data.wednesday, forKey: "wednesday")
                            managedObject.setValue(aShopDetails.data.thursday, forKey: "thursday")
                            managedObject.setValue(aShopDetails.data.friday, forKey: "friday")

                            do {
                                try self.context!.save()
                            } catch {
                                print("Error saving coffee shop details to core data")
                            }
                        }
                    }
                } catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                    
                    // retrieve coffee shops from core data if unable to decode JSON
                    do {
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CoffeeShops")
                        request.predicate = NSPredicate(format: "id = %@", self.aShop!.id)
                        request.returnsObjectsAsFaults = false
                        let result = try self.context!.fetch(request)
                        for data in result as! [NSManagedObject] {
                            self.aShop!.details = coffeeShopDetails(
                                url: data.value(forKey: "url") as! String,
                                photo_url: data.value(forKey: "photo_url") as? String,
                                phone_number: data.value(forKey: "phone_number") as? String,
                                opening_hours: [
                                    "monday": data.value(forKey: "monday") as! String,
                                    "tuesday": data.value(forKey: "tuesday") as! String,
                                    "wednesday": data.value(forKey: "wednesday") as! String,
                                    "thursday": data.value(forKey: "thursday") as! String,
                                    "friday": data.value(forKey: "friday") as! String
                                ]
                            )
                            
                        }
                    } catch {
                        print("Error retrieving coffee shops from core data")
                    }
                }
                callback()
            }.resume()
        }
    }
}
