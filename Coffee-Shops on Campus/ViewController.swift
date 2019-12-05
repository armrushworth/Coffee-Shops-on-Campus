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
import SystemConfiguration
import UIKit

struct coffeeOnCampus: Decodable {
    let data: [coffeeShop]
    let code: Int
}

struct coffeeOnCampusDetails: Decodable {
    let data: coffeeShopDetails
    let code: Int
}

struct coffeeShop: Decodable {
    let id: String
    let name: String
    let latitude: String
    let longitude: String
    var details: coffeeShopDetails?
    
    init(id: String, name: String, latitude: String, longitude: String, details: coffeeShopDetails? = nil) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.details = details
    }
    
    var location: CLLocation {
        return CLLocation(latitude: CLLocationDegrees(self.latitude)!, longitude: CLLocationDegrees(self.longitude)!)
    }
    
    func distance(to location: CLLocation) -> CLLocationDistance {
        return location.distance(from: self.location)
    }
}

struct coffeeShopDetails: Decodable {
    let url: String?
    let photo_url: String?
    let phone_number: String?
    let opening_hours: openingHours
}

struct openingHours: Decodable {
    let monday: String?
    let tuesday: String?
    let wednesday: String?
    let thursday: String?
    let friday: String?
}

class MyPointAnnotation : MKPointAnnotation {
    var id: String?
}

class ViewController: UIViewController, UISearchBarDelegate, UISearchResultsUpdating, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    // network reachability
    let reachability = SCNetworkReachabilityCreateWithName(nil, "https://dentistry.liverpool.ac.uk/_ajax/coffee/")
    
    // location manager
    let locationManager = CLLocationManager()
    var locationOfUser = CLLocation()
    
    // search bar
    let searchController = UISearchController(searchResultsController: nil)
    
    // core data
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    
    // arrays for coffee shops and coffee shops after filtration
    var coffeeShops = [coffeeShop]()
    var filteredCoffeeShops = [coffeeShop]()
    
    // coffee shop selected to view further details of
    var currentCell = -1
    var selectedCoffeeShopId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up the search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search for a coffee shop..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // populate coffee shops array and load the map
        context = appDelegate.persistentContainer.viewContext
        populateCoffeeShops() {
            self.loadMap()
        }
    }
    
    // reload the table and map when the view appears
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
        mapView.reloadInputViews()
    }
    
    // populate the coffee shops array
    func populateCoffeeShops(callback: @escaping () -> Void) {
        // check network reachability
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(self.reachability!, &flags)
        
        // retrieve coffee shops from URL if network is available
        if (isNetworkReachable(with: flags)) {
            if let url = URL(string: "https://dentistry.liverpool.ac.uk/_ajax/coffee/") {
                let session = URLSession.shared
                session.dataTask(with: url) { (data, response, err) in
                    guard let jsonData = data else {
                        return
                    }
                    do {
                        // decode JSON
                        let decoder = JSONDecoder()
                        let shops = try decoder.decode(coffeeOnCampus.self, from: jsonData)
                        
                        // check if coffee shops already exist within core data
                        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CoffeeShops")
                        let count = try self.context!.count(for: request)
                        
                        for aShop in shops.data {
                            // add coffee shops to array
                            self.coffeeShops.append(aShop)
                            
                            // add coffee shops to core data
                            if (count == 0) {
                                let entity = NSEntityDescription.entity(forEntityName: "CoffeeShops", in: self.context!)
                                let newItem = NSManagedObject(entity: entity!, insertInto: self.context)
                                newItem.setValue(aShop.id, forKey: "id")
                                newItem.setValue(aShop.name, forKey: "name")
                                newItem.setValue(aShop.latitude, forKey: "latitude")
                                newItem.setValue(aShop.longitude, forKey: "longitude")
                                do {
                                    try self.context!.save()
                                } catch {
                                    print("Error saving coffee shops to core data")
                                }
                            }
                        }
                        self.sortCoffeeShops()
                    } catch let jsonErr {
                        print("Error decoding JSON", jsonErr)
                    }
                    callback()
                }.resume()
            }
            
        // retrieve coffee shops from core data if network is unreachable
        } else if (!isNetworkReachable(with: flags)) {
            do {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CoffeeShops")
                fetchRequest.returnsObjectsAsFaults = false
                
                // add coffee shops to array
                let results = try self.context!.fetch(fetchRequest)
                for data in results as! [NSManagedObject] {
                    self.coffeeShops.append(coffeeShop(
                        id: data.value(forKey: "id") as! String,
                        name: data.value(forKey: "name") as! String,
                        latitude: data.value(forKey: "latitude") as! String,
                        longitude: data.value(forKey: "longitude") as! String))
                }
            } catch {
                print("Error retrieving coffee shops from core data")
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
    
    // segue to the details view, passing the coffee shop object as a parameter
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailView" {
            let secondViewController = segue.destination as! DetailViewController
            secondViewController.aShop = coffeeShops.first(where: { $0.id == selectedCoffeeShopId })
        }
    }
    
    // MARK: - Location
    
    // get the updated location of the user
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationOfUser = locations[0] // get the first location (ignore any others)
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.002
        let lonDelta: CLLocationDegrees = 0.002
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        self.mapView.setRegion(region, animated: true)
        sortCoffeeShops()
    }
    
    // sort coffee shops in order of proximity to the location of the user
    func sortCoffeeShops(){
        DispatchQueue.main.async {
            self.coffeeShops.sort(by: {
                $0.distance(to: self.locationOfUser) < $1.distance(to: self.locationOfUser)
            })
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Map View
    
    func loadMap() {
        // set up the map
        locationManager.delegate = self as CLLocationManagerDelegate // we want messages about location
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization() // ask the user for permission to get their location
        locationManager.startUpdatingLocation() // and start receiving those messages (if we’re allowed to)
       
        // add an annotation onto the map for each coffee shop
        for aShop in self.coffeeShops {
            guard let latitude = Double(aShop.latitude) else { return }
            guard let longitude = Double(aShop.longitude) else { return }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
            let annotation = MyPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = aShop.name
            annotation.id = aShop.id
            self.mapView.addAnnotation(annotation)
        }
    }
    
    // navigate to the details of the coffee shop selected in the map
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? MyPointAnnotation else { return }
        selectedCoffeeShopId = annotation.id!
        performSegue(withIdentifier: "toDetailView", sender: nil)
    }
    
    // MARK: - Table View
    
    // determine the number of rows in each table section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering() ? filteredCoffeeShops.count : coffeeShops.count
    }
    
    // determine the content of each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "myCell")
        cell.textLabel?.text = isFiltering() ? filteredCoffeeShops[indexPath.row].name : coffeeShops[indexPath.row].name
        let distance = isFiltering() ? filteredCoffeeShops[indexPath.row].distance(to: locationOfUser) : coffeeShops[indexPath.row].distance(to: locationOfUser)
        cell.detailTextLabel?.text = "\(String(format:"%.0f", distance)) metres away"
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        return cell
    }
    
    // navigate to the details of the coffee shop selected in the table
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentCell = indexPath.row
        selectedCoffeeShopId = coffeeShops[currentCell].id
        performSegue(withIdentifier: "toDetailView", sender: nil)
    }
    
    // MARK: - Searching
    
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
}
