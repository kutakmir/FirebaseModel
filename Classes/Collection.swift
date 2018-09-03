//
//  Collection.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation


protocol CollectionDelegate : class {
    func didDeleteItem(atIndex index: Int, items: [Any])
    func didUpdateItem(atIndex index: Int, items: [Any])
    func didAddItem(atIndex index: Int, items: [Any])
    func didUpdate(items: [Any])
}

extension CollectionDelegate {
    func didDeleteItem(atIndex index: Int, items: [Any]) {
        didUpdate(items: items)
    }
    func didUpdateItem(atIndex index: Int, items: [Any]) {
        didUpdate(items: items)
    }
    func didAddItem(atIndex index: Int, items: [Any]) {
        didUpdate(items: items)
    }
}


class Collection <T : Any> {
    var items = [T]()
}
