//
//  FirebaseCollectionViewDataSource.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 18/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseCollectionViewDataSource<T: FirebaseModel>: CollectionViewDataSource<T> {
    
    let collection : FirebaseCollection<T>
    
    init(query: DatabaseQuery, collectionView: UICollectionView, cellClass: AnyClass? = nil) {
        collection = FirebaseCollection<T>(query: query)
        super.init(collectionView: collectionView, cellClass: cellClass)
        
        collection.delegate = self
    }
}

