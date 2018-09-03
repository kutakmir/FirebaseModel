//
//  Identifiable.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation

protocol Identifiable {
    var id: String {get set}
    func attributesDictionary() -> [String: AnyObject]
}
