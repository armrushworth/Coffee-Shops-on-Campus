//
//  DetailViewController.swift
//  Coffee-Shops on Campus
//
//  Created by Rushworth, Ashley on 26/11/2019.
//  Copyright © 2019 Rushworth, Ashley. All rights reserved.
//

import CoreData
import SystemConfiguration
import UIKit

class DetailViewController: UIViewController {

    // outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var openingTimesLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var websiteButton: UIButton!
    
    // show coffee shop website button if a url is present
    @IBAction func websiteButton(_ sender: Any) {
        if let url = URL(string: aShop?.details?.url ?? "") {
            UIApplication.shared.open(url)
        }
    }
    
    // network reachability
    let reachability = SCNetworkReachabilityCreateWithName(nil, "https://dentistry.liverpool.ac.uk/_ajax/coffee/")
    
    // core data
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    
    // coffee shop object
    var aShop: coffeeShop?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // populate coffee shops array
        context = appDelegate.persistentContainer.viewContext
        populateCoffeeShopDetails() {
            DispatchQueue.main.async {
                // display image if present, otherwise display default image
                if (self.aShop?.details?.photo_url?.isEmpty ?? true) {
                    self.imageView.image = UIImage(named: "no-image")
                } else {
                    let imageUrl = URL(string: self.aShop?.details?.photo_url ?? "")!
                    let imageData = try! Data(contentsOf: imageUrl)
                    self.imageView.image = UIImage(data: imageData)
                }
                
                // display coffee shops details in relevant labels
                self.nameLabel.text = self.aShop?.name
                self.openingTimesLabel.text = "Monday: \(self.aShop?.details?.opening_hours.monday ?? "")\nTuesday: \(self.aShop?.details?.opening_hours.tuesday ?? "")\nWednesday: \(self.aShop?.details?.opening_hours.wednesday ?? "")\nThursday: \(self.aShop?.details?.opening_hours.thursday ?? "")\nFriday: \(self.aShop?.details?.opening_hours.friday ?? "")"
                self.phoneLabel.text = "Phone: \(self.aShop?.details?.phone_number ?? "")"
                
                // display visit website button if url is present
                if (!(self.aShop?.details?.url?.isEmpty ?? true)) {
                    self.websiteButton.isHidden = false
                }
            }
        }
    }
    
    // populate coffee shop details for the coffee shop object
    func populateCoffeeShopDetails(callback: @escaping () -> Void) {
        // check network reachability
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(self.reachability!, &flags)
        
        // retrieve coffee shop details from URL if network is available
        if (isNetworkReachable(with: flags)) {
            if let url = URL(string: "https://dentistry.liverpool.ac.uk/_ajax/coffee/info/?id=\(aShop!.id)") {
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
                        
                        // fetch coffee shop record from core data
                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoffeeShops")
                        fetchRequest.predicate = NSPredicate(format: "id = %@", self.aShop!.id)
                        fetchRequest.returnsObjectsAsFaults = false
                        
                        // update coffee shop details in core data
                        do {
                            let results = try self.context!.fetch(fetchRequest) as? [NSManagedObject]
                            if results?.count != 0 {
                                results?[0].setValue(aShopDetails.data.url, forKey: "url")
                                results?[0].setValue(aShopDetails.data.photo_url, forKey: "photo_url")
                                results?[0].setValue(aShopDetails.data.phone_number, forKey: "phone_number")
                                results?[0].setValue(aShopDetails.data.opening_hours.monday, forKey: "monday")
                                results?[0].setValue(aShopDetails.data.opening_hours.tuesday, forKey: "tuesday")
                                results?[0].setValue(aShopDetails.data.opening_hours.wednesday, forKey: "wednesday")
                                results?[0].setValue(aShopDetails.data.opening_hours.thursday, forKey: "thursday")
                                results?[0].setValue(aShopDetails.data.opening_hours.friday, forKey: "friday")
                            }
                        } catch {
                            print("Error fetching coffee shop details from core data")
                        }
                        
                        // save updated details to core data
                        do {
                            try self.context!.save()
                        } catch {
                            print("Error saving coffee shop details to core data")
                        }
                    } catch let jsonErr {
                        print("Error decoding JSON", jsonErr)
                    }
                    callback()
                }.resume()
            }
            
        // retrieve coffee shops details from core data if network is unreachable
        } else if (!isNetworkReachable(with: flags)) {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoffeeShops")
            fetchRequest.predicate = NSPredicate(format: "id = %@", self.aShop!.id)
            fetchRequest.returnsObjectsAsFaults = false
            
            // add coffee shop details to object
            do {
                let result = try self.context!.fetch(fetchRequest)
                for data in result as! [NSManagedObject] {
                    self.aShop!.details = coffeeShopDetails(
                        url: data.value(forKey: "url") as? String,
                        photo_url: data.value(forKey: "photo_url") as? String,
                        phone_number: data.value(forKey: "phone_number") as? String,
                        opening_hours: openingHours(
                            monday: data.value(forKey: "monday") as? String,
                            tuesday: data.value(forKey: "tuesday") as? String,
                            wednesday: data.value(forKey: "wednesday") as? String,
                            thursday: data.value(forKey: "thursday") as? String,
                            friday: data.value(forKey: "friday") as? String
                        )
                    )
                }
            } catch {
                print("Error fetching coffee shop details from core data")
            }
            callback()
        }
        
    }
    
    // check if network is reachable
    func isNetworkReachable (with flags: SCNetworkReachabilityFlags)
        -> Bool {
            let isReachable = flags.contains (.reachable)
            let needsConnection = flags.contains (.connectionRequired)
            let canConnectAutomaticaly = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
            let canConnectWithoutUserInteraction = canConnectAutomaticaly && !flags.contains(.interventionRequired)
            return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
}
