//
//  EmptyDataSetView.swift
//  Demo
//
//  Created by Luke McDonald on 3/5/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import UIKit

class EmptyDataSetView: UIView, NibContainment {
    // MARK: - Properties
    @IBOutlet weak var containerView: UIView?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
        activityIndicator.color = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
