//
//  ManageGroupTableViewCell.swift
//  FamilyTracker
//
//  Created by Mahesh on 28/05/21.
//

import UIKit

class ManageGroupTableViewCell: UITableViewCell {
    @IBOutlet weak var memberNameLbl: UILabel!
    var removeMemberHandler: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func crossBtnAction(_ sender: Any) {
        removeMemberHandler?()
    }

}
