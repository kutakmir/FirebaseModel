//
//  Firebase.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseDatabase
import FirebaseFirestore
import FirebaseAuth

@objc public class Firebase : NSObject {
    
    enum Environment : String {
        case Development, Production
    }
    
    // Change this to change the database
    // DON'T FORGET TO SET THIS TO PRODUCTION WHEN DEPLOYING TO THE APP STORE!!!
    static var environment: Environment {
        #if DEBUG
            return .Development
        #else
            return .Production
        #endif
    }
    
    @objc static func database() -> Database {
        return Database.database(app: app())
    }
    
    @objc static func firestore() -> Firestore {
        return Firestore.firestore(app: app())
    }
    
    @objc static func app() -> FirebaseApp {
        return FirebaseApp.app(name: environment.rawValue)!
    }
    
    @objc static func auth() -> Auth {
        return Auth.auth(app: app())
    }
    
    @objc static func configure() {
        
        let firebaseEnvironment = environment.rawValue
        let options = FirebaseOptions(contentsOfFile: Bundle.main
            .path(forResource: "GoogleService-Info-\(firebaseEnvironment)", ofType: "plist")!)!
        
        FirebaseApp.configure(name: firebaseEnvironment, options: options)
    }
    
//    func reference<T : FirebaseModel>() 
}
