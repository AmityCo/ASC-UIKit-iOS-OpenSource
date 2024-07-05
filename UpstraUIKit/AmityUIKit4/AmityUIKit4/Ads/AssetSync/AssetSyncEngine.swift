//
//  AssetSyncEngine.swift
//  AmityUIKit4
//
//  Created by Nishan on 13/6/2567 BE.
//

import Foundation

class AssetSyncEngine {
    
    // Keep track of file ids to be queried.
    // TODO:
    // When assets is fetched, we need to mark it as ready in db
    // So return something back after completion.
    func fetchAssets(urls: [String], completion: @escaping (_ downloadedAssetUrls: [String]) -> Void) {
        
        let downloadUrls = urls.compactMap { URL(string: $0) }
        
        let prefetcher = ImagePrefetcher(urls: downloadUrls, completionHandler:  { skippedResources, failedResources, completedResources in
            
            Log.adAssets.debug("Prefetched Assets, Skipped \(skippedResources.count), Failed: \(failedResources.count), Completed: \(completedResources.count)")
            
            var downloadedAssets = [String]()
            // Cached Images
            skippedResources.forEach {
                downloadedAssets.append($0.downloadURL.absoluteString)
            }
            
            completedResources.forEach {
                downloadedAssets.append($0.downloadURL.absoluteString)
            }
            
            completion(downloadedAssets)
        })
        
        prefetcher.start()
    }
        
    func cancelAllDownload() {
        // Cancel all download tasks used by Kingfisher
        ImageDownloader.default.cancelAll()
    }
    
    func removeAllAssets() {
        
    }
}
