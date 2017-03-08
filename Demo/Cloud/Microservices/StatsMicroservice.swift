//
//  StatsMicroservice.swift
//  Demo
//
//  Created by Luke McDonald on 3/8/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import Foundation

// MARK: - Completion Handlers
typealias StatsCompletionHandler = (_ stats: [String : AnyObject]?, _ error: NSError?) -> Void

protocol StatsMicroservice {
    func requestStats(completion: StatsCompletionHandler?)
}
