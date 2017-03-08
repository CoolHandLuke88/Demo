//
//  CollectionsMicroservice.swift
//  Demo
//
//  Created by Luke McDonald on 3/6/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import Foundation

// MARK: - Completion Handlers
typealias CollectionsCompletionHandler = (_ collections: [[String : AnyObject]]?, _ error: NSError?) -> Void
typealias CollectionCompletionHandler = (_ collections: [String : AnyObject]?, _ error: NSError?) -> Void

protocol CollectionsMicroservice {
    func requestCollections(page: Int?,
                            per_page: Int?,
                            completion: CollectionsCompletionHandler?)
    
    func requestFeaturedCollections(page: Int?,
                                    per_page: Int?,
                                    completion: CollectionsCompletionHandler?)
    
    func requestCuratedCollections(page: Int?,
                                   per_page: Int?,
                                   completion: CollectionsCompletionHandler?)
    
    func requestCollection(collectionId: String,
                           completion: CollectionsCompletionHandler?)
    
    func requestCuratedCollection(collectionId: String,
                                  completion: CollectionsCompletionHandler?)
    
    func requestCollectionPhotos(collectionId: String,
                                 page: Int?,
                                 per_page: Int?,
                                 completion: CollectionsCompletionHandler?)
    
    func requestCuratedCollectionPhotos(collectionId: String,
                                        page: Int?,
                                        per_page: Int?,
                                        completion: CollectionsCompletionHandler?)
    
    func requestRelatedCollections(collectionId: String,
                                   completion: CollectionsCompletionHandler?)
    
    func requestCreateCollection(title: String,
                                 description: String?,
                                 isPrivate: Bool?,
                                 completion: CollectionCompletionHandler?)
    
    func requestUpdateCollection(title: String?,
                                 description: String?,
                                 isPrivate: Bool?,
                                 completion: CollectionCompletionHandler?)
    
    func requestCollectionRemoval(collectionId: String,
                                  completion: CollectionCompletionHandler?)
    
    func requestCollectionAddPhoto(collectionId: String,
                                   photoId: String,
                                   completion: CollectionCompletionHandler?)
    
    func requestCollectionRemovePhoto(collectionId: String,
                                      photoId: String,
                                      completion: CollectionCompletionHandler?)
}
