//
//  WebserviceManager.swift
//  Demo
//
//  Created by Luke McDonald on 3/3/17.
//  Copyright © 2017 Demo. All rights reserved.
//
// See Unsplash API Documentation: https://unsplash.com/documentation

import UIKit
import Alamofire

// MARK: - URLSessionConfiguration
fileprivate let WebserviceManagerErrorDomain = "WebserviceManagerErrorDomain"
fileprivate let WebserviceManagerTimeoutIntervalForRequest: TimeInterval = 15
fileprivate let WebserviceManagerTimeoutIntervalForResource: TimeInterval = 15

// MARK: - Resources Completion
fileprivate typealias ResourcesCompletionHandler = (Any?, Data?, NSInteger?, NSError?) -> Void
typealias ResourcesUploadProgressCompletionHandler = (Progress) -> Void
typealias ResourcesDownloadProgressCompletionHandler = (Progress) -> Void

// MARK: - Routes
fileprivate struct Routes {
    // MARK: * Current User
    static let CurrentUserEndPoint = "/me"
    // MARK: * Users
    static let UsersProfileEndPoint = "/users/%@"
    static let UsersPortfolioEndPoint = "/users/%@/portfolio"
    static let UsersPhotosEndPoint = "/users/%@/photos"
    static let UsersLikedPhotosEndPoint = "/users/%@/likes"
    static let UsersCollectionsEndPoint = "/users/%@/collections"
    // MARK: * Photos
    static let PhotosEndPoint = "/photos"
    static let PhotosCuratedEndPoint = "/photos/curated"
    static let PhotoDetailsEndPoint = "/photos/%@"
    static let PhotosRandomEndPoint = "/photos/random"
    static let PhotoStatsEndPoint = "/photos/%@/stats"
    static let PhotoDownloadLinkEndPoint = "/photos/%@/download"
    static let PhotoFavoriteEndPoint = "/photos/%@/like"
    // MARK: * Search
    static let SearchPhotosEndPoint = "/search/photos"
    static let SearchCollectionsEndPoint = "/search/collections"
    static let SearchUsersEndPoint = "/search/users"
    // MARK: * Collections
    static let CollectionsEndPoint = "/collections"
    static let CollectionsFeaturedEndPoint = "/collections/featured"
    static let CollectionsCuratedEndPoint = "/collections/curated"
    static let CollectionDetailsEndPoint = "/collections/%@"
    static let CollectionCuratedDetailsEndPoint = "/collections/curated/%@"
    static let CollectionDetailsPhotosEndPoint = "/collections/%@/photos"
    static let CollectionCuratedPhotosDetailsEndPoint = "/collections/curated/%@/photos"
    static let CollectionRelatedEndPoint = "/collections/%@/related"
    static let CollectionAddPhotoEndPoint = "/collections/%@/add"
    static let CollectionRemovePhotoEndPoint = "/collections/%@/remove"
    // MARK: * Stats
    static let StatsTotalEndPoint = "/stats/total"
}

struct Access {
    var token: String?
}

enum Sort {
    case latest, oldest, popular
    
    var value: String {
        switch self {
        case .latest:
            return "latest"
        case .oldest:
            return "oldest"
        case .popular:
            return "popular"
        }
    }
}

class WebserviceManager: NSObject {
    // MARK: - Properties
    static let sharedManager = WebserviceManager()
    
    /// AlmofireManager instance
    fileprivate var alamoFireManager: Alamofire.SessionManager!
    
    /// configuration for unsplash
    fileprivate static let unsplashConfigurationInfo: NSDictionary = {
        let plistPath: String = Bundle.main.path(forResource: "Config", ofType: "plist")!
        let plistInfo: NSDictionary = NSDictionary(contentsOfFile: plistPath)!
        let info: NSDictionary = plistInfo["Unsplash"] as! NSDictionary
        return info
    }()
    
    /// unsplash public host
    fileprivate(set) lazy var host: String = {
        let host = unsplashConfigurationInfo["host"] as? String ?? ""
        return host
    }()
    
    /// unsplash api host
    fileprivate(set) lazy var apiHost: String = {
        let api =  unsplashConfigurationInfo["apiHost"] as? String ?? ""
        return api
    }()
    
    /// unsplash api version
    fileprivate(set) lazy var version: String = {
        let version = unsplashConfigurationInfo["version"] as? String ?? ""
        return version
    }()
    
    /// application id for unsplash
    fileprivate(set) lazy var appId: String = {
        let appID = unsplashConfigurationInfo["appID"] as? String ?? ""
        return appID
    }()
    
    /// unsplash secret
    fileprivate(set) lazy var secret: String = {
        let secret = unsplashConfigurationInfo["secret"] as? String ?? ""
        return secret
    }()
    
    /// stores accessToken related data.
    fileprivate var access: Access = Access()
    
    /// Access type for unsplash
    public static let publicScope = ["public"]
    
    /// Access Authorization for unsplash user
    public static let allScopes = [
        "public",
        "read_user",
        "write_user",
        "read_photos",
        "write_photos",
        "write_likes",
        "read_collections",
        "write_collections"
    ]
    
    fileprivate var reqLimit: Int = 50
    
    // MARK: - Initialization
    override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = WebserviceManagerTimeoutIntervalForRequest
        configuration.timeoutIntervalForResource = WebserviceManagerTimeoutIntervalForResource
        alamoFireManager = Alamofire.SessionManager(configuration: configuration)
    }
    
    // MARK: - Request Resources
    fileprivate func generateQueryParameters(page: Int?, per_page: Int?, order_by: Sort? = nil, size: CGSize? = nil, query: String? = nil) -> [String: AnyObject]? {
        var params: [String : AnyObject]? = [String : AnyObject]()
        
        if let page = page {
            params?["page"] = NSNumber(value: page)
        }
        
        if let per_page = per_page {
            params?["per_page"] = NSNumber(value: per_page)
        }
        
        if let order_by = order_by {
            params?["order_by"] = order_by.value as AnyObject?
        }
        
        if let size = size {
            params?["w"] = size.width as AnyObject?
            params?["h"] = size.height as AnyObject?
        }
        
        if let query = query {
            params?["query"] = query as AnyObject?
        }
        
        if params?.count == 0 {
            params = nil
        }
        
        return params
    }
    
    // TODO: Replace with Adaptor
    fileprivate func additionalHeaders(authNeeded: Bool) -> [String : String] {
        var headers = [
            "Accept-Version" : self.version,
            "Content-Type" : "application/json",
            ]
        if (authNeeded) {
            headers["Authorization"] = "Bearer \(self.access.token)"
        } else {
            headers["Authorization"] = "Client-ID \(self.appId)"
        }
        return headers
    }
    
    fileprivate func requestResourcesWithPath(authNeeded: Bool = false,
                                              path: String,
                                              method: HTTPMethod,
                                              params: [String : AnyObject]? = nil,
                                              encoding: ParameterEncoding = JSONEncoding.default,
                                              completionHandler: ResourcesCompletionHandler?)
    {
        let headers = additionalHeaders(authNeeded: authNeeded)
        alamoFireManager.request(path, method: method, parameters: params, encoding: encoding, headers: headers).responseJSON(completionHandler: { response in
            if let res = response.response {
                if let headers: NSDictionary = res.allHeaderFields as NSDictionary? {
                    if let reqLimit = headers["X-Ratelimit-Remaining"] as? String {
                        if let value = Int(reqLimit) {
                            // TODO: Add restriction in webservice once user has reached the request limit. 
                            // api only allows so many requests per hour. Exceed it so many times and unsplash will shut you down.
                            self.reqLimit = value
                        }
                    }
                }
            }
            
//            print("response: \(response.response)")
            
            var resError: NSError? = nil
            let errormessage: String = "Server Error"
            var resData: NSData? = nil
            var jsonObj: Any? = nil
            
            switch response.result {
            case .success(let JSON):
                
                if let responseDict = JSON as? [String: AnyObject] {
                    jsonObj = responseDict
                } else if let responseArray = JSON as? [[String: AnyObject]] {
                    jsonObj = responseArray
                }
                
                
                if let statusCode: NSInteger = response.response?.statusCode {
                    if statusCode < 200 || statusCode > 299 {
                        
                        var userInfo: [String : AnyObject] = [NSLocalizedDescriptionKey:errormessage as AnyObject]
                        
                        if let errorObject: NSDictionary = jsonObj as? NSDictionary {
                            userInfo["errorInfo"] = errorObject
                        } else if let errorObject: NSArray = jsonObj as? NSArray {
                            userInfo["errorInfo"] = errorObject
                        }
                        
                        resError = NSError(domain: WebserviceManagerErrorDomain,
                                           code: statusCode,
                                           userInfo: userInfo)
                    }
                }
                
                if let theData: NSData = response.data as NSData? {
                    resData = theData
                }
                break
                
            case .failure(let error):
                resError = error as NSError?
                break
            }
            
            var statusCode: NSInteger = 0
            
            if let code = response.response?.statusCode {
                statusCode = code
            }
            
            if let errorObject: NSDictionary = jsonObj as? NSDictionary {
                if let errorsArray: NSArray = errorObject["errors"] as? NSArray {
                    
                    if errorsArray.count > 0 {
                        let userInfo: [String : AnyObject] = [NSLocalizedDescriptionKey:errorsArray as AnyObject, "errorArray": errorsArray]
                        
                        resError = NSError(domain: WebserviceManagerErrorDomain,
                                           code: statusCode,
                                           userInfo: userInfo)
                    }
                }
            }
            
            
            if let theError = resError {
                if theError.code == NSURLErrorTimedOut {
                    let userInfo: [String : AnyObject] = [NSLocalizedDescriptionKey:"Your request can not be completed right now. Please try again later." as AnyObject]
                    resError = NSError(domain: WebserviceManagerErrorDomain, code: statusCode, userInfo: userInfo)
                }
            }
            
            if completionHandler != nil {
                completionHandler?(jsonObj, resData as Data?, response.response?.statusCode, resError)
            }
        })
    }
}

// MARK: - Current User Microservice
extension WebserviceManager: CurrentUserMicroservice {
    // MARK: * Get the user’s profile 
    // (https://unsplash.com/documentation#get-the-users-profile)
    
    func requestCurrentUser(completion: CurrentUserCompletionHandler?) {
        let endPoint = Routes.CurrentUserEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCurrentUser: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Update the current user’s profile 
    // (https://unsplash.com/documentation#update-the-current-users-profile)
    
    func requestCurrentUserUpdate(username: String?,
                                  firstName: String?,
                                  lastName: String?,
                                  email: String?,
                                  portfolioURL: String?,
                                  location: String?,
                                  bio: String?,
                                  instagramUsername: String?,
                                  completion: CurrentUserCompletionHandler?) {
        let endPoint = Routes.CurrentUserEndPoint
        let method = HTTPMethod.put
        let path = apiHost + endPoint
        var params = [String: AnyObject]()
        
        if let username = username {
            params["username"] = username as AnyObject?
        }
        
        if let firstName = firstName {
            params["first_name"] = firstName as AnyObject?
        }
        
        if let lastName = lastName {
            params["last_name"] = lastName as AnyObject?
        }
        
        if let email = email {
            params["email"] = email as AnyObject?
        }
        
        if let portfolioURL = portfolioURL {
            params["url"] = portfolioURL as AnyObject?
        }
        
        if let location = location {
            params["location"] = location as AnyObject?
        }
        
        if let bio = bio {
            params["bio"] = bio as AnyObject?
        }
        
        if let instagramUsername = instagramUsername {
            params["instagram_username"] = instagramUsername as AnyObject?
        }
        
        requestResourcesWithPath(path: path, method: method, params: params) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCurrentUserUpdate: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
}

// MARK: - User Microservice
extension WebserviceManager: UserMicroservice {
    // MARK: * Get a user’s public profile 
    // (https://unsplash.com/documentation#get-a-users-public-profile)
    
    func requestUserProfile(username: String,
                            profileImageSize: CGSize,
                            completion: UserCompletionHandler?) {
        let endPoint = String(format: Routes.UsersProfileEndPoint, username)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: nil,
                                                                    per_page: nil,
                                                                    order_by: nil,
                                                                    size: profileImageSize)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestUserProfile: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Get a user’s portfolio link 
    // (https://unsplash.com/documentation#get-a-users-portfolio-link)
    
    func requestUserPortfolioLink(username: String, completion: UserCompletionHandler?) {
        let endPoint = String(format: Routes.UsersPortfolioEndPoint, username)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestUserPortfolioLink: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * List a user’s photos 
    // (https://unsplash.com/documentation#list-a-users-photos)
    
    func requestUserPhotos(username: String,
                           page: Int?,
                           per_page: Int?,
                           order_by: Sort?,
                           completion: UserContentCompletionHandler?) {
        let endPoint = String(format: Routes.UsersPhotosEndPoint, username)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page,
                                                                    order_by: order_by)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestUserPhotos: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * List a user’s liked photos 
    // (https://unsplash.com/documentation#list-a-users-liked-photos)
    
    func requestUserLikedPhotos(username: String,
                                page: Int?,
                                per_page: Int?,
                                order_by: Sort?,
                                completion: UserContentCompletionHandler?) {
        let endPoint = String(format: Routes.UsersLikedPhotosEndPoint, username)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page,
                                                                    order_by: order_by)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestUserLikedPhotos: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * List a user’s collections 
    // (https://unsplash.com/documentation#list-a-users-collections)
    
    func requestUserCollections(username: String,
                                page: Int?,
                                per_page: Int?,
                                completion: UserContentCompletionHandler?) {
        let endPoint = String(format: Routes.UsersCollectionsEndPoint, username)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page,
                                                                    order_by: nil)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestUserCollections: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
}

// MARK: - Photo Microservice
extension WebserviceManager: PhotoMicroservice {
    // MARK: * List photos
    // (https://unsplash.com/documentation#list-photos)
    
    func requestPhotos(page: Int?,
                       per_page: Int?,
                       order_by: Sort?,
                       completion: PhotosCompletionHandler?) {
        let endPoint = Routes.PhotosEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page,
                                                                    order_by: order_by)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestPhotos: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * List curated photos
    // (https://unsplash.com/documentation#list-curated-photos)
    
    func requestCuratedPhotos(page: Int?,
                              per_page: Int?,
                              order_by: Sort?,
                              completion: PhotosCompletionHandler?) {
        let endPoint = Routes.PhotosCuratedEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page,
                                                                    order_by: order_by)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCuratedPhotos: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * Get a photo
    // (https://unsplash.com/documentation#get-a-photo)
    
    func requestPhoto(id: String, completion: PhotoCompletionHandler?) {
        let endPoint = String(format: Routes.PhotoDetailsEndPoint, id)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestPhoto: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Get a random photo
    // (https://unsplash.com/documentation#get-a-random-photo)
    
    func requestRandomPhoto(completion: PhotoCompletionHandler?) {
        let endPoint = Routes.PhotosRandomEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestPhoto: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Get a photo’s stats
    // (https://unsplash.com/documentation#get-a-photos-stats)
    
    func requestPhotoStats(id: String, completion: PhotoCompletionHandler?) {
        let endPoint = String(format: Routes.PhotoStatsEndPoint, id)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestPhotoStats: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Get a photo’s download link
    // (https://unsplash.com/documentation#get-a-photos-download-link)
    
    func requestPhotoDownloadLink(id: String, completion: PhotoCompletionHandler?) {
        let endPoint = String(format: Routes.PhotoDownloadLinkEndPoint, id)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestPhotoStats: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Update a photo
    // (https://unsplash.com/documentation#update-a-photo)
    
    func requestUpdatePhoto(id: String,
                            location: (latitude: Double?, longitude: Double?, name: String?, city: String?, country: String?, confidential: String?)?,
                            exif: (make: String?, model: String?, exposure_time: Double?, aperture_value: Double?, focal_length: Double?, iso_speed_ratings: Double?)?,
                            completion: PhotoCompletionHandler?) {
        let endPoint = String(format: Routes.PhotoDetailsEndPoint, id)
        let method = HTTPMethod.put
        let path = apiHost + endPoint
        var params = [String: AnyObject]()
        
        if let location = location {
            var locationInfo = [String: AnyObject]()
           
            if let latitude = location.latitude, let longitude = location.longitude  {
                locationInfo["latitude"] = latitude as AnyObject?
                locationInfo["longitude"] = longitude as AnyObject?
            }
            
            if let name = location.name {
                locationInfo["name"] = name as AnyObject?
            }
            
            if let city = location.city {
                locationInfo["city"] = city as AnyObject?
            }
            
            if let country = location.country {
                locationInfo["country"] = country as AnyObject?
            }
            
            if let confidential = location.confidential {
                locationInfo["confidential"] = confidential as AnyObject?
            }
            
            params["location"] = locationInfo as AnyObject?
        }
        
        if let exif = exif {
            var exifInfo = [String: AnyObject]()
            
            if let make = exif.make {
                exifInfo["make"] = make as AnyObject?
            }
            
            if let model = exif.model {
                exifInfo["model"] = model as AnyObject?
            }
            
            if let exposure_time = exif.exposure_time {
                exifInfo["exposure_time"] = exposure_time as AnyObject?
            }
            
            if let aperture_value = exif.aperture_value {
                exifInfo["aperture_value"] = aperture_value as AnyObject?
            }
            
            if let focal_length = exif.focal_length {
                exifInfo["focal_length"] = focal_length as AnyObject?
            }
            
            if let iso_speed_ratings = exif.iso_speed_ratings {
                exifInfo["iso_speed_ratings"] = iso_speed_ratings as AnyObject?
            }
            
            params["exif"] = exifInfo as AnyObject?
        }
        
        requestResourcesWithPath(path: path, method: method, params: params) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestUpdatePhoto: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Like a photo
    // (https://unsplash.com/documentation#like-a-photo)
    
    func requestPhotoLike(id: String, completion: PhotoCompletionHandler?) {
        let endPoint = String(format: Routes.PhotoFavoriteEndPoint, id)
        let method = HTTPMethod.post
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestPhotoLike: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Unlike a photo
    // (https://unsplash.com/documentation#unlike-a-photo)
    
    func requestPhotoUnlike(id: String, completion: PhotoCompletionHandler?) {
        let endPoint = String(format: Routes.PhotoFavoriteEndPoint, id)
        let method = HTTPMethod.delete
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestPhotoUnlike: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
}

// MARK: - Search Microservice
extension WebserviceManager: SearchMicroservice {
    // MARK: * Search photos
    // (https://unsplash.com/documentation#search-photos)
    
    func requestSearchPhotos(query: String,
                             page: Int?,
                             per_page: Int?,
                             completion: SearchCompletionHandler?) {
        let endPoint = Routes.SearchPhotosEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page,
                                                                    query: query)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestSearchPhotos: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * Search collections
    // (https://unsplash.com/documentation#search-collections)

    func requestSearchCollections(query: String,
                                  page: Int?,
                                  per_page: Int?,
                                  completion: SearchCompletionHandler?) {
        let endPoint = Routes.SearchCollectionsEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page,
                                                                    query: query)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestSearchCollections: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * Search users
    // (https://unsplash.com/documentation#search-users)

    func requestSearchUsers(query: String,
                            page: Int?,
                            per_page: Int?,
                            completion: SearchCompletionHandler?) {
        let endPoint = Routes.SearchUsersEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page,
                                                                    query: query)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestSearchUsers: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
}


// MARK: - Collections Microservice
extension WebserviceManager: CollectionsMicroservice {
    // MARK: * List collections
    // (https://unsplash.com/documentation#list-collections)
    
    func requestCollections(page: Int?,
                            per_page: Int?,
                            completion: CollectionsCompletionHandler?) {
        let endPoint = Routes.CollectionsEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCollections: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * List featured collections
    // (https://unsplash.com/documentation#list-featured-collections)

    func requestFeaturedCollections(page: Int?,
                                    per_page: Int?,
                                    completion: CollectionsCompletionHandler?) {
        let endPoint = Routes.CollectionsFeaturedEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestFeaturedCollections: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * List curated collections
    // (https://unsplash.com/documentation#list-curated-collections)

    func requestCuratedCollections(page: Int?,
                                   per_page: Int?,
                                   completion: CollectionsCompletionHandler?) {
        let endPoint = Routes.CollectionsCuratedEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCuratedCollections: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * Get a collection
    // (https://unsplash.com/documentation#get-a-collection)

    func requestCollection(collectionId: String,
                           completion: CollectionsCompletionHandler?) {
        let endPoint = String(format: Routes.CollectionDetailsEndPoint, collectionId)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCollection: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }

    func requestCuratedCollection(collectionId: String,
                                  completion: CollectionsCompletionHandler?) {
        let endPoint = String(format: Routes.CollectionsCuratedEndPoint, collectionId)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCuratedCollection: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * Get a collection’s photos
    // (https://unsplash.com/documentation#get-a-collections-photos)

    func requestCollectionPhotos(collectionId: String,
                                 page: Int?,
                                 per_page: Int?,
                                 completion: CollectionsCompletionHandler?) {
        let endPoint = String(format: Routes.CollectionDetailsPhotosEndPoint, collectionId)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCollectionPhotos: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }

    func requestCuratedCollectionPhotos(collectionId: String,
                                        page: Int?,
                                        per_page: Int?,
                                        completion: CollectionsCompletionHandler?) {
        let endPoint = String(format: Routes.CollectionCuratedPhotosDetailsEndPoint, collectionId)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        let encoding: ParameterEncoding = URLEncoding.default
        let params: [String : AnyObject]? = generateQueryParameters(page: page,
                                                                    per_page: per_page)
        
        requestResourcesWithPath(path: path, method: method, params: params, encoding: encoding) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCuratedCollectionPhotos: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * List a collection’s related collections
    // (https://unsplash.com/documentation#list-a-collections-related-collections)

    func requestRelatedCollections(collectionId: String,
                                   completion: CollectionsCompletionHandler?) {
        let endPoint = String(format: Routes.CollectionRelatedEndPoint, collectionId)
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestRelatedCollections: Error: \(error)")
            }
            
            completion?(resource as? [[String : AnyObject]], error)
        }
    }
    
    // MARK: * Create a new collection
    // (https://unsplash.com/documentation#create-a-new-collection)

    func requestCreateCollection(title: String,
                                 description: String?,
                                 isPrivate: Bool?,
                                 completion: CollectionCompletionHandler?) {
        let endPoint = Routes.CollectionsEndPoint
        let method = HTTPMethod.post
        let path = apiHost + endPoint
        var params: [String: AnyObject] = ["title": title as AnyObject]
        
        if let description = description {
            params["description"] = description as AnyObject?
        }
        
        if let isPrivate = isPrivate {
            params["private"] = isPrivate as AnyObject?
        }
        
        requestResourcesWithPath(path: path, method: method, params: params) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCreateCollection: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Update an existing collection
    // (https://unsplash.com/documentation#update-an-existing-collection)

    func requestUpdateCollection(title: String?,
                                 description: String?,
                                 isPrivate: Bool?,
                                 completion: CollectionCompletionHandler?) {
        let endPoint = Routes.CollectionsEndPoint
        let method = HTTPMethod.put
        let path = apiHost + endPoint
        var params = [String: AnyObject]()
        
        if let title = title {
            params["title"] = title as AnyObject?
        }
        
        if let description = description {
            params["description"] = description as AnyObject?
        }
        
        if let isPrivate = isPrivate {
            params["private"] = isPrivate as AnyObject?
        }
        
        requestResourcesWithPath(path: path, method: method, params: params) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestUpdateCollection: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Delete a collection
    // (https://unsplash.com/documentation#delete-a-collection)
    
    func requestCollectionRemoval(collectionId: String,
                                  completion: CollectionCompletionHandler?) {
        let endPoint = String(format: Routes.CollectionsEndPoint, collectionId)
        let method = HTTPMethod.delete
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCollectionRemoval: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Add a photo to a collection
    // (https://unsplash.com/documentation#add-a-photo-to-a-collection)
    
    func requestCollectionAddPhoto(collectionId: String,
                                   photoId: String,
                                   completion: CollectionCompletionHandler?) {
        let endPoint = String(format: Routes.CollectionAddPhotoEndPoint, collectionId)
        let method = HTTPMethod.post
        let path = apiHost + endPoint
        let params: [String: AnyObject] = ["photo_id": photoId as AnyObject]
        
        requestResourcesWithPath(path: path, method: method, params: params) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCreateCollection: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
    
    // MARK: * Remove a photo from a collection
    // (https://unsplash.com/documentation#remove-a-photo-from-a-collection)

    func requestCollectionRemovePhoto(collectionId: String,
                                      photoId: String,
                                      completion: CollectionCompletionHandler?) {
        let endPoint = String(format: Routes.CollectionRemovePhotoEndPoint, collectionId)
        let method = HTTPMethod.delete
        let path = apiHost + endPoint
        let params: [String: AnyObject] = ["photo_id": photoId as AnyObject]
        
        requestResourcesWithPath(path: path, method: method, params: params) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestCreateCollection: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
}

// MARK: - Stats Microservice
extension WebserviceManager: StatsMicroservice {
    // MARK: * Get total Photos and Downloads from unsplash api.
    // (https://unsplash.com/documentation#stats)

    func requestStats(completion: StatsCompletionHandler?) {
        let endPoint = Routes.StatsTotalEndPoint
        let method = HTTPMethod.get
        let path = apiHost + endPoint
        
        requestResourcesWithPath(path: path, method: method) { (resource, data, statusCode, error) -> Void in
            if  error != nil {
                print("WebserviceManager: requestStats: Error: \(error)")
            }
            
            completion?(resource as? [String : AnyObject], error)
        }
    }
}
