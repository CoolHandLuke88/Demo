//
//  NibContainment.swift
//  Demo
//
//  Created by Luke McDonald on 3/5/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import Foundation
import UIKit

protocol NibContainment: class {
    weak var containerView: UIView? { get set }
    func xibSetup()
}

extension NibContainment {
    func xibSetup() {
        guard let view = self as? UIView else {
            return
        }
        
        if let container = loadViewFromNib() {
            self.containerView = container
            self.containerView?.translatesAutoresizingMaskIntoConstraints = true
            self.containerView?.frame = view.bounds
            self.containerView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(self.containerView!)
            view.setNeedsLayout()
        }
    }
    
    private func loadViewFromNib() -> UIView? {
        if let view: UIView = self as? UIView {
            let bundle = Bundle(for: type(of: view))
            let nib = UINib(nibName: view.className, bundle: bundle)
            // Assumes UIView is top level and only object in your xib file
            let view = nib.instantiate(withOwner: view, options: nil)[0] as! UIView
            return view
        }

        return nil
    }
}
