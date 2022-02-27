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
    @IBOutlet weak var lastUpdateCell: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avalibilityView.backgroundColor = .green
    }
    
    private var url: URL?
    
    func setupWith(model: AvalibilityViewModel) {
        self.nameLabel.text = model.name
        self.url = model.url
        self.avalibilityView.backgroundColor = model.avaliable ? UIColor.green : UIColor.red
    }
    
    @IBAction func copyAction(_ sender: Any) {
        UIPasteboard.general.string = url?.absoluteString
    }
    
}
