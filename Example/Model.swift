//
//  Model.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 03/09/2018.
//

import UIKit

enum BodyCover : String {
    case skin, scales, feathers, fur, shell
}
extension BodyCover : DefaultStringRawRepresentable {
    static var defaultValue: String { return self.scales.rawValue }
}

enum Environment : String {
    case shallowSaltWater, deepSaltWater, shallowFreshWater, deepFreshWater, underground, land, lowAltitude, highAltitude, space, forrest
}
extension Environment : DefaultStringRawRepresentable {
    static var defaultValue: String { return self.land.rawValue }
}

class Animal: FirebaseModel {

    // Properties that cannot be expressed in Objective-C, we need to map them explicitly
    override func setSwiftValue(_ value: Any?, forKey key: String) {
        switch key {
        case "bodyCover":
            bodyCover = value as? BodyCover ?? bodyCover
        default: break
        }
    }
    
    // Example of Swift Enum automatically parsed and mapped
    var bodyCover : BodyCover = .defaultEnum
    // TODO: array of enums
//    var survivableEnvironments : [Environment] = [.shallowSaltWater]
    
    @objc var name : String = "Animal"
    
    @objc var length : Float = 1.0
    @objc var weight : Float = 25.0
    @objc var numberOfLegs : Int = 0
    @objc var breathsAir : Bool = true
    @objc var birthDate : Date?
    
    // References
    @objc var parents = [Animal]()
    
    // Nested Objects (saved nested in Firebase)
    @objc var carriedBabiesNested = [Animal]()
    
}
