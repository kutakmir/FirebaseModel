//
//  User.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore

class FirebaseUser: FirebaseModel {
    
    override class var basePath: String { return "users" }
    
    override var skipProperties: [String] {
        return super.skipProperties + ["isCurrent"]
    }
    
    // Ignored Properties
    
    // Mapped Properties
    @objc var oneSignalUIDs: [String : Bool]?
    
    @objc var name: String?
    @objc var imageURL: URL?
    @objc var fcmToken: String?
    
    // ----------------------------------------------------
    // MARK: - Initialization
    // ----------------------------------------------------
    
    // Creating a fake user for testing purposes
    init(name: String) {
        super.init()
        
        self.name = name
        id = NSUUID().uuidString
    }
    // We need to implement the required initializers because we are using a custom init(name:_)
    required init() { super.init() }
    required init?(snapshot: DataSnapshot) {
        super.init(snapshot: snapshot)
    }
    
    // ----------------------------------------------------
    // MARK: - Derived properties
    // ----------------------------------------------------
    
    var isCurrent: Bool {
        if let current = FirebaseUser.current, current == self {
            return true
        }
        return false
    }
    
    static var current : FirebaseUser?
    
    
}
