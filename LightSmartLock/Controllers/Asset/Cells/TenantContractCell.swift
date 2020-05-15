//
//  TenantContractCell.swift
//  LightSmartLock
//
//  Created by changjun on 2020/5/7.
//  Copyright © 2020 mugua. All rights reserved.
//

import UIKit
import GradientProgressBar

class TenantContractCell: UITableViewCell {
    
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    var model: TenantContractAndBillsDTO? {
        didSet {
            let houseName = model?.tenantContractDTO?.houseName ?? ""
            let tenantName = model?.tenantContractDTO?.tenantName ?? ""
            nameLabel.text = "\(houseName) \(tenantName)"
            
            let rental = model?.tenantContractDTO?.rental?.description ?? ""
            
            let payMethod = model?.tenantContractDTO?.payMethod?.description ?? ""
            let detail = "\(rental)元·\(payMethod)"
            detailBtn.setTitle(detail, for: .normal)
            
            startDateLabel.text = model?.tenantContractDTO?.startDate
            endDateLabel.text = model?.tenantContractDTO?.endDate
                        
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        
        guard let startDateStr = model?.tenantContractDTO?.startDate,
            let startDate = formatter.date(from: startDateStr),
            let endDateStr = model?.tenantContractDTO?.endDate,
            let endDate = formatter.date(from: endDateStr) else  {
                tipLabel.text = nil
                return
        }
        
        let comps1 = Calendar.current.dateComponents([.day], from: startDate, to: endDate)
        let comps2 = Calendar.current.dateComponents([.day], from: startDate, to: Date())
        
        if let days1 = comps1.day, let days2 = comps2.day {
            tipLabel.text = "还剩\(days1 - days2 - 1)天"
            let percent = CGFloat(days2) / CGFloat(days1)
            tipConstraint.constant = gradientProgressView.bounds.width * percent
            gradientProgressView.progress = Float(percent)
        }
        
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var detailBtn: UIButton!
    
    @IBOutlet weak var startDateLabel: UILabel!
    
    @IBOutlet weak var endDateLabel: UILabel!
    
    @IBOutlet weak var tipLabel: UILabel!
    
    @IBOutlet weak var tipConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var gradientProgressView: GradientProgressBar!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        gradientProgressView.gradientColors = [#colorLiteral(red: 1, green: 0.7921568627, blue: 0.3607843137, alpha: 1), #colorLiteral(red: 1, green: 0.568627451, blue: 0, alpha: 1)]
        gradientProgressView.gradientLayer.cornerRadius = 3
    }
    
    
}