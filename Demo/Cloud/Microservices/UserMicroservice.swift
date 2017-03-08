//
//  UserMicroservice.swift
//  Demo
//
//  Created by Luke McDonald on 3/3/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Completion Handlers
typealias UserCompletionHandler = (_ user: [String : AnyObject]?, _ error: NSError?) -> Void
typealias UserContentCompletionHandler = (_ content: [[String : AnyObject]]?, _ error: NSError?) -> Void

protocol UserMicroservice {
    func requestUserProfile(username: String,
                            profileImageSize: CGSize,
                            completion: UserCompletionHandler?)
    
    func requestUserPortfolioLink(username: String, completion: UserCompletionHandler?)
    
    func requestUserPhotos(username: String,
                           page: Int?,
                           per_page: Int?,
                           order_by: Sort?,
                           completion: UserContentCompletionHandler?)
    
    func requestUserLikedPhotos(username: String,
                                page: Int?,
                                per_page: Int?,
                                order_by: Sort?,
                                completion: UserContentCompletionHandler?)
    
    func requestUserCollections(username: String,
                                page: Int?,
                                per_page: Int?,
                                completion: UserContentCompletionHandler?)
}

// Allow default arguments in protocol
extension UserMicroservice {
    func requestUserProfile(username: String,
                            profileImageSize: CGSize = CGSize(width: 60.0, height: 60.0),
                            completion: UserCompletionHandler?) {
        requestUserProfile(username: username, profileImageSize: profileImageSize, completion: completion)
    }
    
    func requestUserPhotos(username: String,
                           page: Int? = 1,
                           per_page: Int? = 20,
                           order_by: Sort? = .latest,
                           completion: UserContentCompletionHandler?) {
        requestUserPhotos(username: username, page: page, per_page: per_page, order_by: order_by, completion: completion)
    }
    
    func requestUserLikedPhotos(username: String,
                                page: Int? = 1,
                                per_page: Int? = 20,
                                order_by: Sort? = .latest,
                                completion: UserContentCompletionHandler?) {
        requestUserLikedPhotos(username: username, page: page, per_page: per_page, order_by: order_by, completion: completion)
    }
    
    func requestUserCollections(username: String,
                                page: Int? = 1,
                                per_page: Int? = 20,
                                completion: UserContentCompletionHandler?) {
        requestUserCollections(username: username, page: page, per_page: per_page, completion: completion)
    }
}
