//
//  ViewController.swift
//  Coffee-Shops on Campus
//
//  Created by Rushworth, Ashley on 26/11/2019.
//  Copyright © 2019 Rushworth, Ashley. All rights reserved.
//

import CoreData
import CoreLocation
import MapKit
import UIKit

class ViewController: UIViewController, UISearchBarDelegate, UISearchResultsUpdating, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    
    var selectedPerson = ("", "", "")
    var currentCell = -1
    
    struct coffeeShop: Decodable {
        let id: String
        let name: String
        let latitude: String
        let longitude: String
    }
    
    struct coffeeOnCampus: Decodable {
        let data: [coffeeShop]
        let code: Int
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    var coffeeShops = [coffeeShop]()
    var filteredCoffeeShops = [coffeeShop]()
    // location manager
    let locationManager = CLLocationManager()
    
    // search Bar
    let searchController = UISearchController(searchResultsController: nil)
    
    // determine the number of rows in each table section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering() ? filteredCoffeeShops.count : coffeeShops.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "myCell")
        cell.textLabel!.text = isFiltering() ? filteredCoffeeShops[indexPath.row].name : coffeeShops[indexPath.row].name
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentCell = indexPath.row
        selectedPerson = (coffeeShops[currentCell].name, coffeeShops[currentCell].latitude, coffeeShops[currentCell].longitude)
        performSegue(withIdentifier: "toDetailView", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for a coffee shop..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // setup the map
        locationManager.delegate = self as CLLocationManagerDelegate //we want messages about location
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization() //ask the user for permission to get their location
        locationManager.startUpdatingLocation() //and start receiving those messages (if we’re allowed to)
        
        context = appDelegate.persistentContainer.viewContext
        
         // decode JSON
         if let url = URL(string: "https://dentistry.liverpool.ac.uk/_ajax/coffee/"){
             let session = URLSession.shared
             session.dataTask(with: url) { (data, response, err) in
                 guard let jsonData = data else {
                     return
                 }
                 do {
                    let decoder = JSONDecoder()
                    let shops = try decoder.decode(coffeeOnCampus.self, from: jsonData)
                    self.deleteAllData(entity: "CoffeeShops")
                    for aShop in shops.data {
                        self.coffeeShops.append(aShop)
                        let entity = NSEntityDescription.entity(forEntityName: "CoffeeShops", in: self.context!)
                        let newItem = NSManagedObject(entity: entity!, insertInto: self.context)
                        newItem.setValue(aShop.id, forKey: "id")
                        newItem.setValue(aShop.name, forKey: "name")
                        newItem.setValue(aShop.latitude, forKey: "latitude")
                        newItem.setValue(aShop.longitude, forKey: "longitude")
                        do {
                            try self.context!.save()
                        } catch {
                            print("Failed saving")
                        }
                    }
                 } catch let jsonErr {
                     print("Error decoding JSON", jsonErr)
                    
                    do {
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CoffeeShops")
                        request.returnsObjectsAsFaults = false
                        
                        let result = try self.context!.fetch(request)
                        for data in result as! [NSManagedObject] {
                            self.coffeeShops.append(coffeeShop(id: data.value(forKey: "id") as! String, name: data.value(forKey: "name") as! String, latitude: data.value(forKey: "latitude") as! String, longitude: data.value(forKey: "longitude") as! String))
                        }
                    } catch {
                        print("Failed")
                    }
                 }
             }.resume()
         }
    }
    
    // delete all records for a given entity
    func deleteAllData(entity: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        do {
            let objects = try context!.fetch(fetchRequest)
            for object in objects {
                context!.delete(object as! NSManagedObject)
            }
            try context!.save()
        } catch _ {
            print("Failed deleting")
        }
    }
    
    // reload the table and map when the view appears
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
        mapView.reloadInputViews()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailView" {
            let secondViewController = segue.destination as! DetailViewController
            secondViewController.selectedPerson = selectedPerson
        }
    }
    
    // filter coffee shops by the string entered in the search bar
    func updateSearchResults(for searchController: UISearchController) {
        filteredCoffeeShops = coffeeShops.filter({( coffeeShop : coffeeShop) -> Bool in
            return coffeeShop.name.lowercased().contains(searchController.searchBar.text!.lowercased())
        })
        tableView.reloadData()
    }
    
    // determine if the user is filtering the table using the search bar
    func isFiltering() -> Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { let locationOfUser = locations[0] //get the first location (ignore any others)
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.002
        let lonDelta: CLLocationDegrees = 0.002
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        self.mapView.setRegion(region, animated: true)
    }
}
