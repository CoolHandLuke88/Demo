//
//  NSObject+Additions.swift
//  Demo
//
//  Created by Luke McDonald on 3/3/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import Foundation
import UIKit
import EZSwiftExtensions

extension NSObject {
    class func identifier() -> String {
        return self.className
    }
    
    class func identifierNAV() -> String {
        return self.className+"-NAV"
    }
}
