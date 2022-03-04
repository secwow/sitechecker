//
//  StatisticsViewController.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 04.03.2022.
//

import Foundation
import UIKit

class StatisticsViewController: UITableViewController {
    var statistics: [(URL, Int)] = []
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statistics.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "\(statistics[indexPath.row].0.absoluteString) -- \(statistics[indexPath.row].1)"
        
        
        return cell
    }
}
