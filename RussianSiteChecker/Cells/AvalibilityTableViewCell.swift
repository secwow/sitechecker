//
//  AvalibilityTableViewCell.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import UIKit

class AvalibilityTableViewCell: UITableViewCell {
    
    @IBOutlet weak var backgroudView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avalibilityView: UIView!
    @IBOutlet weak var lastUpdateCell: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroudView.layer.cornerRadius = 4.0
        backgroudView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.06).cgColor
        backgroudView.layer.shadowRadius = 20
        backgroudView.layer.shadowOffset = .init(width: 0, height: 10)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopTimer()
    }
    
    private var url: URL?
    private var date = Date()
    
    func setupWith(model: AvalibilityViewModel) {
        self.nameLabel.text = model.name
        self.url = model.url
        self.avalibilityView.backgroundColor = model.avaliable ? UIColor.green : UIColor(red: 0.8, green: 0.173, blue: 0.149, alpha: 1)
        self.lastUpdateCell.text = NSLocalizedString("less.than.second.ago.text", comment: "")
        date = Date()
        startTimer()
    }
    
    private var timer: Timer?
    
    private func startTimer() {
        stopTimer()
        timer = .scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] timer in
            guard let self = self else { return }
            let calendar = Calendar.current
            let components = calendar.dateComponents([.minute, .second], from: self.date, to: Date())
            let second = components.second ?? 0
            
            let resultString: String

            if second > 1 {
                resultString = String(format: NSLocalizedString("update.n.seconds.ago.text", comment: ""), "\(second)")
            } else {
                resultString = NSLocalizedString("less.than.second.ago.text", comment: "")
            }
            
            self.lastUpdateCell.text = resultString
        })
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @IBAction func copyAction(_ sender: Any) {
        UIPasteboard.general.string = url?.absoluteString
    }
    
}
