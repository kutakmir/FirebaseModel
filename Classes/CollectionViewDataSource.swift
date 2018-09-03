//
//  CollectionViewDataSource.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 24/07/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import UIKit

class CollectionViewDataSource<T : Any> : NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CollectionDelegate {
    
    var items = [T]()
    weak var collectionView : UICollectionView?
    var itemAnimation = true
    
    init(collectionView: UICollectionView, cellClass: AnyClass? = nil) {
        super.init()
        
        // Collection View
        self.collectionView = collectionView
        collectionView.dataSource = self
        
        if let cellClass = cellClass {
            collectionView.register(cellClass, forCellWithReuseIdentifier: "\(T.self)")
        }
    }
    
    // ----------------------------------------------------
    // MARK: - UICollectionViewDataSource
    // ----------------------------------------------------
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.row]
        let cellIdentifier = String(describing: type(of: item))
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        if let c = cell as? Configurable {
            c.configure(item: item)
        }
        return cell
    }
    
    // ----------------------------------------------------
    // MARK: - CollectionDelegate
    // ----------------------------------------------------
    
    func didUpdate(items: [Any]) {
        self.items = items as? [T] ?? [T]()
        collectionView?.reloadData()
    }
    
    func didDeleteItem(atIndex index: Int, items: [Any]) {
        if itemAnimation == false {
            didUpdate(items: items)
        } else {
            collectionView?.performBatchUpdates({ [weak self] in
                self?.items = items as? [T] ?? [T]()
                self?.collectionView?.deleteItems(at: [IndexPath(row: index, section: 0)])
            }, completion: nil)
        }
    }
    
    func didUpdateItem(atIndex index: Int, items: [Any]) {
        if itemAnimation == false {
            didUpdate(items: items)
        } else {
            collectionView?.performBatchUpdates({ [weak self] in
                self?.items = items as? [T] ?? [T]()
                self?.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
                }, completion: nil)
        }
    }
    
    func didAddItem(atIndex index: Int, items: [Any]) {
        if itemAnimation == false {
            didUpdate(items: items)
        } else {
            collectionView?.performBatchUpdates({ [weak self] in
                self?.items = items as? [T] ?? [T]()
                self?.collectionView?.insertItems(at: [IndexPath(row: index, section: 0)])
                }, completion: nil)
        }
    }
}
