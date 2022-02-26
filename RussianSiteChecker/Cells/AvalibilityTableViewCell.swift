//
//  AvalibilityTableViewCell.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import UIKit

class AvalibilityTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avalibilityView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avalibilityView.backgroundColor = .green
    }
    
    func setupWith(model: AvalibilityViewModel) {
        self.nameLabel.text = model.name
        self.avalibilityView.backgroundColor = model.avaliable ? UIColor.green : UIColor.red
    }
}
