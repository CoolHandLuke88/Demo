//
//  SearchMicroservice.swift
//  Demo
//
//  Created by Luke McDonald on 3/6/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import Foundation

// MARK: - Completion Handlers
typealias SearchCompletionHandler = (_ content: [[String : AnyObject]]?, _ error: NSError?) -> Void

protocol SearchMicroservice {
    func requestSearchPhotos(query: String,
                             page: Int?,
                             per_page: Int?,
                             completion: SearchCompletionHandler?)
    
    func requestSearchCollections(query: String,
                                  page: Int?,
                                  per_page: Int?,
                                  completion: SearchCompletionHandler?)
    
    func requestSearchUsers(query: String,
                            page: Int?,
                            per_page: Int?,
                            completion: SearchCompletionHandler?)
}

// Allow default arguments in protocol
extension SearchMicroservice {
    func requestSearchPhotos(query: String,
                             page: Int? = 1,
                             per_page: Int? = 20,
                             completion: SearchCompletionHandler?) {
        requestSearchPhotos(query: query, page: page, per_page: per_page, completion: completion)
    }
    
    func requestSearchCollections(query: String,
                                  page: Int? = 1,
                                  per_page: Int? = 20,
                                  completion: SearchCompletionHandler?) {
        requestSearchCollections(query: query, page: page, per_page: per_page, completion: completion)
    }
    
    func requestSearchUsers(query: String,
                            page: Int? = 1,
                            per_page: Int? = 20,
                            completion: SearchCompletionHandler?) {
        requestSearchUsers(query: query, page: page, per_page: per_page, completion: completion)
    }
}
