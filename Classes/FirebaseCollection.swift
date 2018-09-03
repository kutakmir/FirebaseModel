//
//  FirebaseCollection.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 18/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseCollection<T : FirebaseModel> : Collection<T> {
    
    private var latestItemsHandle: DatabaseHandle?
    private var latestItemsQuery: DatabaseQuery?
    
    private var changeItemHandle: DatabaseHandle?
    private var deleteItemHandle: DatabaseHandle?
    
    private var nextPageQuery: DatabaseQuery?
    private var query: DatabaseQuery?
    var keepItemsAttached : Bool = false
    
    weak var delegate: CollectionDelegate?
    
    public private(set) var isLoadingNextPage : Bool = false
    public private(set) var hasLoadedAllOlderItems : Bool = false
    
    init(query: DatabaseQuery) {
        // QuerysetAttributes
        self.query = query
        
        super.init()
        
        startObserving()
    }
    
    deinit {
        // Stop observing
        stopObserving()
    }
    
    // ----------------------------------------------------
    // MARK: - Item Generation and Observation
    // ----------------------------------------------------
    
    private func item(snapshot: DataSnapshot) -> T? {
        if snapshot.exists(), let newObject = instantiateSwiftClassOfElementFromArray(any: self.items) as? T {
            newObject.id = snapshot.key
            newObject.reference = snapshot.ref
            //            newObject.fetchedReference = snapshot.ref
            
            if let attributes = snapshot.value as? [String : AnyObject] {
                newObject.setAttributes(attributes)
            } else if let attribute = snapshot.value {
                // Only a reference
                newObject.setAttribute(attribute)
                // We need to attach the item
                if !keepItemsAttached {
                    newObject.attachOnce { [weak self] in
                        // Update UI for this particular item
                        DispatchQueue.main.async {
                            if let index = self?.items.index(of: newObject) {
                                
                                if newObject.exists {
                                    self?.delegate?.didUpdateItem(atIndex: index, items: self!.items)
                                } else {
                                    self?.items.remove(at: index)
                                    self?.delegate?.didDeleteItem(atIndex: index, items: self!.items)
                                }
                            }
                        }
                    }// End of attach
                }
            }
            
            if keepItemsAttached {
                newObject.observeAndKeepAttached {
                    // Update UI for this particular item
                    DispatchQueue.main.async { [weak self] in
                        if let index = self?.items.index(of: newObject) {
                            
                            if newObject.exists {
                                self?.delegate?.didUpdateItem(atIndex: index, items: self!.items)
                            } else {
                                self?.items.remove(at: index)
                                self?.delegate?.didDeleteItem(atIndex: index, items: self!.items)
                            }
                        }
                    }
                }// End of attach
            }
            
            return newObject
        } else {
            return nil
        }
    }
    
    // ----------------------------------------------------
    // MARK: - Observation - dynamic
    // ----------------------------------------------------
    
    func startObserving() {
        stopObserving()
        
        latestItemsQuery = query
        
        // From that moment on, observe new incoming messages
        latestItemsHandle = latestItemsQuery?.observe(.childAdded, with: { [weak self] (snapshot) in
            // Validate the input
            if let item : T = self?.item(snapshot: snapshot) {
                
                DispatchQueue.main.async {
                    if let _self = self {
                        if let first = _self.items.first, first == item {
                            return
                        }
                        _self.items.insert(item, at: 0)
                        _self.delegate?.didAddItem(atIndex: 0, items: self!.items)
                    }
                }
            }
        })
        
        deleteItemHandle = query?.observe(.childRemoved, with: { [weak self] (snapshot) in
            guard let _self = self else { return }
            
            DispatchQueue.main.async {
                var index = 0
                for item in _self.items {
                    if item.id == snapshot.key {
                        
                        self?.items.remove(at: index)
                        self?.delegate?.didDeleteItem(atIndex: index, items: self!.items)
                        break
                    }
                    index += 1
                }
            }
        })
        
        changeItemHandle = query?.observe(.childChanged, with: { [weak self] (snapshot) in
            guard let _self = self else { return }
            
            DispatchQueue.main.async {
                var index = 0
                for item in _self.items {
                    if item.id == snapshot.key {
                        
                        let model = T(snapshot: snapshot)!
                        _self.items.remove(at: index)
                        _self.items.insert(model, at: index)
                        self?.delegate?.didUpdateItem(atIndex: index, items: _self.items)
                        break
                    }
                    index += 1
                }
            }
        })
    }
    
    func stopObserving() {
        if let latestItemsHandle = latestItemsHandle {
            latestItemsQuery?.removeObserver(withHandle: latestItemsHandle)
        }
        if let deleteItemHandle = deleteItemHandle {
            query?.removeObserver(withHandle: deleteItemHandle)
        }
    }
}


