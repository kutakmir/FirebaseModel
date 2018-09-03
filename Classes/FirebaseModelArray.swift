//
//  FirebaseModelArray.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

fileprivate var firebaseModelHandles = [DatabaseReference : DatabaseHandle]()

extension Array where Element:FirebaseModel {
    
    // TODO: create a nice, incrementally synced array
    
}
