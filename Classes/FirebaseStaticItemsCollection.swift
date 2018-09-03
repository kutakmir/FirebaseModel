//
//  FirebaseStaticItemsCollection.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 17/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation

class FirebaseStaticLiveItemsCollection <T: FirebaseModel> : Collection<T> {
    
    weak var delegate: CollectionDelegate?
    
    func configure(items: [T], keepItemsAttached : Bool = false) {
        self.items = items
        
        delegate?.didUpdate(items: items)
        
        if keepItemsAttached {
            for item in items {
                item.observeAndKeepAttached { [weak self] in
                    if let index = self?.items.index(of: item) {
                        if item.exists {
                            self?.delegate?.didUpdateItem(atIndex: index, items: self!.items)
                        } else {
                            self?.items.remove(at: index)
                            self?.delegate?.didDeleteItem(atIndex: index, items: self!.items)
                        }
                    }
                }// End of observe
            }
        }
    }
}


class FirebaseStaticItemsCollection <T: FirebaseModel> : Collection<T> {
    
    weak var delegate: CollectionDelegate?
    
    func configure(items: [T], keepItemsUpdated : Bool = false) {
        self.items = items
        
        delegate?.didUpdate(items: items)
        
        if keepItemsUpdated {
            for item in items {
                item.observeAndKeepAttached { [weak self] in
                    if let index = self?.items.index(of: item) {
                        self?.delegate?.didUpdateItem(atIndex: index, items: self!.items)
                    }
                }// End of observe
            }
        }
    }
}
