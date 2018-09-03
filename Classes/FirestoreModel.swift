//
//  FirestoreModel.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseFirestore


// MARK: - FirestoreModel ------------------------------------------------------------------------

class FirestoreModel: NSObject, Identifiable {
    // Properties
    var skipProperties : [String] {
        return ["id", "collectionName"]
    }
    // Document ID - Default id is random
    var id: String = NSUUID().uuidString {
        didSet {
            ref = type(of: self).collectionRef.document(id)
        }
    }
    
    var ref: DocumentReference?
    
    var reference: DocumentReference?
    var fetchedReference : DocumentReference?
    var exists : Bool = true
    
    /**
     Base Firebase Reference of the class
     */
    class var collectionName: String { return "" }
    class var collectionRef : CollectionReference {
        return Firebase.firestore().collection(self.collectionName)
    }
    
    // ----------------------------------------------------
    // MARK: - Methods
    // ----------------------------------------------------
    
    override required init() {
        
    }
    
    required init?(snapshot: DocumentSnapshot) {
        super.init()
        
        id = snapshot.documentID
        ref = snapshot.reference
        
        if snapshot.exists {
            if let data = snapshot.data() {
                let value = data as [String : AnyObject]
                setAttributes(value)
            }
            return
        }
        return nil
    }
    
    func configure(snapshot: DocumentSnapshot) {
        if snapshot.exists {
            if let data = snapshot.data() {
                let value = data as [String : AnyObject]
                setAttributes(value)
            }
        }
    }
    
    static func == (lhs: FirestoreModel, rhs: FirestoreModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Store Data -----------------------------------------------------
    @objc func attributesDictionary() -> [String: AnyObject] {  // attributesDictionary() returns all attributes even nil String? as <null>
        var result = [String: AnyObject]()
        let mirror = Mirror(reflecting: self)
        for (property, value) in mirror.children {
            if let property = property, skipProperties.index(of: property) == nil { // if it is an 'attribute' to store
                if let date = value as? Date {
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd"
                    result[property] = df.string(from: date) as AnyObject
                } else if let objArray = value as? [Identifiable] {
                    if String(property.suffix(6)) == "Nested" {
                        var objectsDict: [String: [String: AnyObject]] = Dictionary<String, Dictionary<String, AnyObject>>()
                        objArray.enumerated().forEach({ tuple in
                            let identifier = tuple.element.id
                            objectsDict[identifier] = tuple.element.attributesDictionary()
                        })
                        result[property] = objectsDict as AnyObject
                    } else {
                        var referencesDict: [String: Int] = [:]
                        objArray.enumerated().forEach({ tuple in
                            let id = tuple.element.id
                            referencesDict[id] = tuple.offset
                        })
                        result[property] = referencesDict as AnyObject
                    }
                } else if let object = value as? FirestoreModel {
                    result[property] = object.id as AnyObject
                } else {
                    result[property] = value as AnyObject
                }
            }
        }
        return result
    }
    
    
    
    // Reload Stored Data ------------------------------------------------
    @objc func setAttributes(_ dictionary: Dictionary<String, AnyObject>) {
        let mirror = Mirror(reflecting: self)
        for (property, currentValueOfProperty) in mirror.children {
            if let property = property, skipProperties.index(of: property) == nil {
                
                if !(currentValueOfProperty is [AnyObject]) { // if it is an 'attribute' to decode (references stored in override)
                    if String(property.suffix(4)) == "Date" {
                        if let dateString = dictionary[property] as? String {
                            let df = DateFormatter()
                            df.dateFormat = "yyyy-MM-dd"
                            self.setValue(df.date(from: dateString), forKey: property)
                        }
                        // Single custom class  
                    } else if let newObject = instantiateSwiftClass(ofAny: currentValueOfProperty) as? FirestoreModel {
                        // Single references
                        if let snapshotKey = dictionary[property] as? String {
                            newObject.id = snapshotKey
                            self.setValue(newObject, forKey: property)
                            // Single nested objects
                        } else if let newDictionary = dictionary[property] as? [String : AnyObject] {
                            newObject.setAttributes(newDictionary)
                            self.setValue(newObject, forKey: property)
                        }
                    } else {
                        
                        
                        // String values
                        let typeName = typeDescription(any: currentValueOfProperty)
                        if typeName == "Optional<String>" || typeName == "String" {
                            let value = dictionary[property]
                            self.setValue(value?.description, forKey: property)
                        } else {
                            self.setValue(dictionary[property], forKey: property)
                        }
                    }
                } else {
                    
                    
                    // An array of Custom classes
                    if isAnArray(any: currentValueOfProperty) {
                        
                        
                        // An Array of References
                        if let referencesDict = dictionary[property] as? [String: Int] {
                            let referencestuplesArray = referencesDict.sorted { $0.value < $1.value }
                            let array : [FirestoreModel] = referencestuplesArray.flatMap {
                                let newObject = instantiateSwiftClassOfElementFromArray(any: currentValueOfProperty) as? FirestoreModel
                                newObject?.id = $0.0
                                return newObject
                            }
                            self.setValue(array, forKey: property)
                        }
                            // Nested objects
                        else if let objectsArray = dictionary[property] as? [String : [String: AnyObject]] { // relies on undocumented firebase behavior
                            var array = [FirestoreModel]()
                            for (_, object) in objectsArray.enumerated() {
                                if let newObject = instantiateSwiftClassOfElementFromArray(any: currentValueOfProperty) as? FirestoreModel {
                                    newObject.setAttributes(object.value)
                                    newObject.id = object.key
                                    array.append(newObject)
                                }
                            }
                            setValue(array, forKey: property)
                        }
                    }
                }
            }
        }
    }
    
    // ----------------------------------------------------
    // MARK: - Firebase Operations
    // ----------------------------------------------------
    
    @objc func save() {   // save() won't persist nil String? shown as <null> in
        if let ref = ref {
            ref.setData(attributesDictionary())
        } else {
            ref = type(of: self).collectionRef.addDocument(data: attributesDictionary())
            id = ref!.documentID
        }
        
    }
    
    func delete() {
        ref?.delete()
    }
    
    @objc func attachOnce(with: @escaping () -> ()) {
        if id.isValidFirebaseKey(), let ref = ref {
            ref.getDocument(completion: { (snap : DocumentSnapshot?, error: Error?) in
                if let snap = snap {
                    if snap.exists, let data = snap.data() {
                        let foundAttributes = data as [String: AnyObject]
                        self.setAttributes(foundAttributes)
                    }
                }
                with()
            })
        } else {
            with()
        }
    }
    
    // To make index(of:) work
    override func isEqual(_ object: Any?) -> Bool {
        guard let obj = object as? FirestoreModel else {
            return false
        }
        return self.id == obj.id
    }
    
    override var description: String {
        return ("FirestoreModel from collection: \( type(of: self).collectionName )\n\(attributesDictionary())" as NSString).replacingOccurrences(of: ", ", with: ",\n ")
    }
}

// Override equivalence for optionals
func == (lhs: FirestoreModel?, rhs: FirestoreModel?) -> Bool {
    if let lid = lhs?.id, let rid = rhs?.id {
        return lid == rid
    } else if lhs?.id == nil && rhs?.id == nil {
        return true
    } else {
        return false
    }
}



