//
//  PhotoMicroservice.swift
//  Demo
//
//  Created by Luke McDonald on 3/4/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import Foundation

// MARK: - Completion Handlers
typealias PhotosCompletionHandler = (_ photos: [[String : AnyObject]]?, _ error: NSError?) -> Void
typealias PhotoCompletionHandler = (_ photo: [String : AnyObject]?, _ error: NSError?) -> Void

protocol PhotoMicroservice {
    func requestPhotos(page: Int?,
                       per_page: Int?,
                       order_by: Sort?,
                       completion: PhotosCompletionHandler?)
    
    func requestCuratedPhotos(page: Int?,
                              per_page: Int?,
                              order_by: Sort?,
                              completion: PhotosCompletionHandler?)
    
    func requestPhoto(id: String, completion: PhotoCompletionHandler?)
    
    func requestRandomPhoto(completion: PhotoCompletionHandler?)
    
    func requestPhotoStats(id: String, completion: PhotoCompletionHandler?)
    
    func requestPhotoDownloadLink(id: String, completion: PhotoCompletionHandler?)
    
    func requestUpdatePhoto(id: String,
                            location: (latitude: Double?, longitude: Double?, name: String?, city: String?, country: String?, confidential: String?)?,
                            exif: (make: String?, model: String?, exposure_time: Double?, aperture_value: Double?, focal_length: Double?, iso_speed_ratings: Double?)?,
                            completion: PhotoCompletionHandler?)

    func requestPhotoLike(id: String, completion: PhotoCompletionHandler?)
    
    func requestPhotoUnlike(id: String, completion: PhotoCompletionHandler?)
}

// Allow default arguments in protocol
extension PhotoMicroservice {
    func requestPhotos(page: Int? = 1,
                       per_page: Int? = 20,
                       order_by: Sort? = .latest,
                       completion: PhotosCompletionHandler?) {
        requestPhotos(page: page, per_page: per_page, order_by: order_by, completion: completion)
    }
    
    func requestCuratedPhotos(page: Int? = 1,
                              per_page: Int? = 20,
                              order_by: Sort? = .latest,
                              completion: PhotosCompletionHandler?) {
        requestCuratedPhotos(page: page, per_page: per_page, order_by: order_by, completion: completion)
    }
}
