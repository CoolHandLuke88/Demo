//
//  CurrentUserMicroservice.swift
//  Demo
//
//  Created by Luke McDonald on 3/6/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import Foundation

// MARK: - Completion Handlers
typealias CurrentUserCompletionHandler = (_ currentUser: [String : AnyObject]?, _ error: NSError?) -> Void

protocol CurrentUserMicroservice {
    func requestCurrentUser(completion: CurrentUserCompletionHandler?)
    
    func requestCurrentUserUpdate(username: String?,
                                  firstName: String?,
                                  lastName: String?,
                                  email: String?,
                                  portfolioURL: String?,
                                  location: String?,
                                  bio: String?,
                                  instagramUsername: String?,
                                  completion: CurrentUserCompletionHandler?)
}
