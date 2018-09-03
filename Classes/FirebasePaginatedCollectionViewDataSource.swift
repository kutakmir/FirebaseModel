//
//  FirebasePaginatedCollectionViewDataSource.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 17/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebasePaginatedCollectionViewDataSource<T: FirebaseModel>: CollectionViewDataSource<T> {
    
    let collection : FirebasePaginatedCollection<T>
    
    init(query: DatabaseQuery, collectionView: UICollectionView, cellClass: AnyClass? = nil) {
        collection = FirebasePaginatedCollection<T>(query: query)
        super.init(collectionView: collectionView, cellClass: cellClass)
        
        collection.delegate = self
    }
    
    // ----------------------------------------------------
    // MARK: - UI
    // ----------------------------------------------------
    
    var isCloseToTheEndOfScrolling : Bool {
        guard let collectionView = collectionView else { return false }
        if collectionView.scrollDirection() == .vertical {
            return collectionView.contentSize.height - collectionView.contentOffset.y < 100.0
        } else {
            return collectionView.contentSize.width  - collectionView.contentOffset.x < 100.0
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isCloseToTheEndOfScrolling && collection.isLoadingNextPage == false && collection.hasLoadedAllOlderItems == false {
            collection.loadNextPage()
        }
    }
}
