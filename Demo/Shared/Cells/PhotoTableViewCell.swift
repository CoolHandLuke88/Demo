//
//  PhotoTableViewCell.swift
//  Demo
//
//  Created by Luke McDonald on 3/4/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import UIKit

class PhotoTableViewCell: UITableViewCell {
    // MARK: - Propeties
    @IBOutlet weak var photoImageView: UIImageView!
    
    static let placeholder: UIImage = {
       return #imageLiteral(resourceName: "Placeholder")
    }()
    
    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = PhotoTableViewCell.placeholder
    }
}
