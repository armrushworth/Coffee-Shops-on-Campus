//
//  ViewController.swift
//  Coffee-Shops on Campus
//
//  Created by Rushworth, Ashley on 26/11/2019.
//  Copyright © 2019 Rushworth, Ashley. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UISearchBarDelegate, UISearchResultsUpdating, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    var selectedPerson = ("", "", "")
    var currentCell = -1
    
    struct staffObject: Decodable {
        let name: String
        let room: String
        let email: String
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    var staff = [staffObject(name: "Phil", room: "A1.20", email: "phil@liverpool.ac.uk"), staffObject(name: "Terry", room: "S2.18", email: "trp@liverpool.ac.uk"), staffObject(name: "Valli", room: "A2.12", email: "v.tamma@liverpool.ac.uk"), staffObject(name: "Boris", room: "A1.15", email: "knoev@liverpool.ac.uk")]
    var filteredStaff = [staffObject]()
    
    // location manager
    let locationManager = CLLocationManager()
    
    // search Bar
    let searchController = UISearchController(searchResultsController: nil)
    
    // determine the number of rows in each table section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering() ? filteredStaff.count : staff.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "myCell")
        cell.textLabel!.text = isFiltering() ? filteredStaff[indexPath.row].name : staff[indexPath.row].name
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentCell = indexPath.row
        selectedPerson = (staff[currentCell].name, staff[currentCell].room, staff[currentCell].email)
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
        filteredStaff = staff.filter({( staff : staffObject) -> Bool in
            return staff.name.lowercased().contains(searchController.searchBar.text!.lowercased())
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
