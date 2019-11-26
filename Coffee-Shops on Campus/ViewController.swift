//
//  ViewController.swift
//  Coffee-Shops on Campus
//
//  Created by Rushworth, Ashley on 26/11/2019.
//  Copyright © 2019 Rushworth, Ashley. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var selectedPerson = ("", "", "")
    var currentCell = -1
    
    var staff = [("Phil", "A1.20", "phil@liverpool.ac.uk"), ("Terry", "S2.18", "trp@liverpool.ac.uk"), ("Valli", "A2.12", "v.tamma@liverpool.ac.uk"), ("Boris", "A1.15", "knoev@liverpool.ac.uk")]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return staff.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "myCell")
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        cell.textLabel!.text = staff[indexPath.row].0
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentCell = indexPath.row
        selectedPerson = staff[currentCell]
        performSegue(withIdentifier: "toDetailView", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailView" {
            let secondViewController = segue.destination as! DetailViewController
            secondViewController.selectedPerson = selectedPerson
        }
    }
}
