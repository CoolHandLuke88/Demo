//
//  LobbyRootViewController.swift
//  Demo
//
//  Created by Luke McDonald on 3/4/17.
//  Copyright © 2017 Demo. All rights reserved.
//

import UIKit
import AlamofireImage
import DZNEmptyDataSet
import PagedArray

// Tweak these values and see how the user experience is affected
let PreloadMargin = 10 /// How many rows "in front" should be loaded
let PageSize = 25 /// Paging size
let TotalCount = 200 /// Number of rows in table view

class LobbyRootViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    fileprivate var photos = [String]()
    
    fileprivate var pagedArray: PagedArray<String> = PagedArray<String>(count: 0, pageSize: PageSize)
    
    fileprivate var shouldPreload = true
    
    fileprivate let operationQueue = OperationQueue()
    
    fileprivate var dataLoadingOperations = [Int: Operation]()
    
    fileprivate(set) lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        refreshControl.shadowRadius = 5.0
        refreshControl.shadowOpacity = 0.7
        refreshControl.tintColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        refreshControl.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    fileprivate let imageCache = AutoPurgingImageCache(
        memoryCapacity: 100_000_000,
        preferredMemoryUsageAfterPurge: 60_000_000
    )
        
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.pagedArray.count == 0 {
            appDelegate.getStats { (totalPhotos) in
                if totalPhotos > 0 {
                    self.pagedArray.count = totalPhotos
                } else {
                    self.pagedArray = PagedArray<String>(count: TotalCount, pageSize: PageSize)
                }
                
                print("self.pagedArray.count: \(self.pagedArray.count)")
                self.performFetch(page: 1, per_page: PageSize, completion: { [weak self] (photos, error) in
                    if let err = error {
                        print("err: \(err)")
                    } else if let photos = photos {
                        let urlsInfo = photos.flatMap({ ($0["urls"] as? [String: AnyObject]) })
                        let urls = urlsInfo.flatMap({ ($0["small"] as? String)})
                        self?.pagedArray.set(urls, forPage: 0)
                        DispatchQueue.main.async {
                            self?.tableView.reloadData()
                        }
                    }
                    
                })
            }
        }
    }
}

// MARK: - Private
extension LobbyRootViewController {
    fileprivate func setup() {
        tableView.addSubview(refreshControl)
        tableView.register(PhotoTableViewCell.nib(), forCellReuseIdentifier: PhotoTableViewCell.identifier())
        tableView.emptyDataSetSource = self
    }
    
    fileprivate func configureCell(_ cell: PhotoTableViewCell, data: String?) {
        guard let data = data else {
            return
        }
        
        guard let url = URL(string: data) else {
            return
        }
        
        if let image = self.imageCache.image(withIdentifier: url.absoluteString) {
            cell.photoImageView.image = image
        } else {
            cell.photoImageView?.af_setImage(withURL: url,
                                             placeholderImage: PhotoTableViewCell.placeholder,
                                             imageTransition: .crossDissolve(0.2),
                                             runImageTransitionIfCached: false,
                                             completion:
                { [weak self] (response) in
                    if response.result.isSuccess {
                        if let value = response.value {
                            if let key = response.request?.url?.absoluteString {
                                self?.imageCache.add(value, withIdentifier: key)
                            }
                        }
                    }
            })
        }
    }
    
    fileprivate func performFetch(page: Int = 1, per_page: Int? = PageSize, completion: ((_ photos: [[String : AnyObject]]?, _ error: NSError?) -> Swift.Void)? = nil) {
        WebserviceManager.sharedManager.requestPhotos(page: page, per_page: per_page) { (photos, error) in
            completion?(photos, error)
        }
    }
    
    @objc fileprivate func refresh(refreshControl: UIRefreshControl) {
        dataLoadingOperations.removeAll(keepingCapacity: true)
        operationQueue.cancelAllOperations()
        pagedArray.removeAllPages()
        
        self.performFetch { [weak self] (photos, error) in
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
            }
            
            if let photos = photos {
                let urlsInfo = photos.flatMap({ ($0["urls"] as? [String: AnyObject]) })
                let urls = urlsInfo.flatMap({ ($0["regular"] as? String)})
                self?.photos = urls

                self?.pagedArray.set(urls, forPage: 0)
            } else if let err = error {
                print("err: \(err)")
                DispatchQueue.main.async {
                    self?.tableView.reloadEmptyDataSet()
                }
            }
        }
    }
    
    fileprivate func loadDataIfNeededForRow(_ row: Int) {
        
        let currentPage = pagedArray.page(for: row)
        if needsLoadDataForPage(currentPage) {
            loadDataForPage(currentPage)
        }
        
        let preloadIndex = row+PreloadMargin
        if preloadIndex < pagedArray.endIndex && shouldPreload {
            let preloadPage = pagedArray.page(for: preloadIndex)
            if preloadPage > currentPage && needsLoadDataForPage(preloadPage) {
                print("currentPage: \(currentPage)")
                print("preloadPage: \(preloadPage)")
                loadDataForPage(preloadPage)
            }
        }
    }
    
    private func needsLoadDataForPage(_ page: Int) -> Bool {
        return pagedArray.elements[page] == nil && dataLoadingOperations[page] == nil
    }
    
    private func loadDataForPage(_ page: Int) {
        let indexes = pagedArray.indexes(for: page)
        
        // Create loading operation
        let operation = DataLoadingOperation(page: page, indexesToLoad: indexes) { [weak self] indexes, data in
            if data.count > 0 {
                // Set elements on paged array
                self?.pagedArray.set(data, forPage: page)
                
                // Reload cells
                if let indexPathsToReload = self?.visibleIndexPathsForIndexes(indexes) {
                    self?.tableView.reloadRows(at: indexPathsToReload, with: .automatic)
                }
                
                // Cleanup
                self?.dataLoadingOperations[page] = nil
            }
        }
        
        // Add operation to queue and save it
        operationQueue.addOperation(operation)
        dataLoadingOperations[page] = operation
    }
    
    private func visibleIndexPathsForIndexes(_ indexes: CountableRange<Int>) -> [IndexPath]? {
        return tableView.indexPathsForVisibleRows?.filter { indexes.contains(($0 as NSIndexPath).row) }
    }
}

// MARK: - UITableViewDataSource
extension LobbyRootViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pagedArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        loadDataIfNeededForRow(indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotoTableViewCell.identifier(), for: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension LobbyRootViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? PhotoTableViewCell else {
            return
        }
        
        configureCell(cell, data: pagedArray[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

// MARK: - DZNEmptyDataSetSource
extension LobbyRootViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
        let view = EmptyDataSetView(frame: scrollView.bounds)
        return view
    }
}

/// Test operation that produces nonsense numbers as data
class DataLoadingOperation: BlockOperation {
    init(page: Int, indexesToLoad: CountableRange<Int>, completion: @escaping (CountableRange<Int>, [String]) -> Void) {
        super.init()
        
        print("Loading indexes: \(indexesToLoad)")
        print("PAGE: \(page)")
        var data = [String]()
        
        addExecutionBlock {
            WebserviceManager.sharedManager.requestPhotos(page: page+1, per_page: PageSize) { (photos, error) in
                if let photos = photos {
                    let urlsInfo = photos.flatMap({ ($0["urls"] as? [String: AnyObject]) })
                    let urls = urlsInfo.flatMap({ ($0["small"] as? String)})
                    data = urls
                }
                
                OperationQueue.main.addOperation {
                    completion(indexesToLoad, data)
                }
            }
        }
    }
    
}
