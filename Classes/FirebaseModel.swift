//
//  FirebaseModel.swift
//  FirebaseModel
//
//  Created by Miroslav Kutak on 16/08/2018.
//  Copyright © 2018 Curly Bracers. All rights reserved.
//

import Foundation
import FirebaseDatabase

// MARK: - FirebaseModel ------------------------------------------------------------------------

class FirebaseModel: NSObject, Identifiable {
    
    // Object database
    private static var allInstances = [String : [String : FirebaseModel]]()
    static func existingInstance<T>(type: T.Type, id: String) -> T? {
        return allInstances["\(type)"]?[id] as? T
    }
    func existingInstance() -> Self {
        if let instance = FirebaseModel.existingInstance(type: type(of: self), id: id) {
            return instance
        } else {
            addToDatabase()
            return self
        }
    }
    private func addToDatabase() {
        let type = typeDescription(any: self)
        if FirebaseModel.allInstances[type] == nil {
            FirebaseModel.allInstances[type] = [String : FirebaseModel]()
        }
        FirebaseModel.allInstances[type]![id] = self
    }
    
    struct Format {
        static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    }
    
    // Properties
    var skipProperties : [String] {
        return ["id", "basePath", "reference"]
    }
    
    var id: String = NSUUID().uuidString
    var reference : DatabaseReference?
    var fetchedReference : DatabaseReference?
    var exists : Bool = true
    
    private var handle : DatabaseHandle?
    private var propertyHandles = [String: DatabaseHandle]()
    
    deinit {
        // Stop the attachment
        stopObserving()
    }
    
    // TODO: observation should be on a different object, because this object can be shared with many others and by re-observing we are throwing away the previous call
    func stopObserving() {
        if let handle = handle {
            reference?.removeObserver(withHandle: handle)
        }
    }
    
    func stopObserving(property: String) {
        if let handle = propertyHandles[property] {
            ref.child(property).removeObserver(withHandle: handle)
        }
    }
    
    /**
     Firebase Reference
     */
    var ref : DatabaseReference {
        if let reference = reference {
            return reference
        }
        if type(of: self).basePath != "" {
            return type(of: self).baseRef.child(id)
        }
        if let fetchedReference = fetchedReference {
            return fetchedReference
        }
        
        return type(of: self).baseRef.childByAutoId()
    }
    
    /**
     Base Firebase Reference of the class
     */
    class var baseRef: DatabaseReference {
        get {
//            if let basePath = basePath {
                return Firebase.database().reference(withPath: basePath)
//            } else {
//                return nil
//            }
        }
    }
    class var basePath: String { return "" }
    
    // ----------------------------------------------------
    // MARK: - Methods
    // ----------------------------------------------------
    
    required override init() {
        super.init()
        // Initialize the identifier
        let r = Firebase.database().reference().childByAutoId()
        id = r.key
    }
    
    init(id: String) {
        super.init()
        self.id = id
    }
    
    required init?(snapshot: DataSnapshot) {
        if let value = snapshot.value as? [String : AnyObject] {
            super.init()
            id = snapshot.key
            setAttributes(value)
            reference = snapshot.ref
            return
        } else
        if let value = snapshot.value as? String {
            super.init()
            id = value
            reference = snapshot.ref
            return
        }
        return nil
    }
    
    static func == (lhs: FirebaseModel, rhs: FirebaseModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func dictionary() -> [String : AnyObject] {
        var dict = attributesDictionary()
        dict["id"] = id as AnyObject
        dict["reference"] = reference?.description() as AnyObject
        return dict
    }
    
    // Store Data -----------------------------------------------------
    @objc func attributesDictionary() -> [String: AnyObject] {  // attributesDictionary() returns all attributes even nil String? as <null>
        var result = [String: AnyObject]()
        let mirror = Mirror(reflecting: self)
        for (property, value) in mirror.children {
            if let property = property, shouldSkip(property: property) == false { // if it is an 'attribute' to store
                
                if let enumeration = value as? StringRawRepresentable {
                    result[property] = enumeration.stringRawValue as AnyObject
                } else
                if let reference = value as? DatabaseReference {
                    result[property] = reference.description() as AnyObject
                } else
                if let url = value as? URL {
                    result[property] = url.absoluteString as AnyObject
                } else
                if let date = value as? Date {
                    if property.hasSuffix("Timestamp") {
                        result[property] = date.inverseTimestamp as AnyObject
                    } else {
                        let df = DateFormatter()
                        df.dateFormat = Format.dateFormat
                        result[property] = df.string(from: date) as AnyObject
                    }
                } else if let objArray = value as? [Identifiable] {
                    if property.hasSuffix("Nested") {
                        var objectsDict: [String: [String: AnyObject]] = Dictionary<String, Dictionary<String, AnyObject>>()
                        objArray.enumerated().forEach({ tuple in
                            let identifier = tuple.element.id// ?? Firebase.database().reference().childByAutoId().key
                            objectsDict[identifier] = tuple.element.attributesDictionary()
                        })
                        result[property] = objectsDict as AnyObject
                    } else {
                        var referencesDict: [String: Int] = [:]
                        objArray.enumerated().forEach({ tuple in
//                            if let id = tuple.element.id {
                            let id = tuple.element.id
                                referencesDict[id] = tuple.offset
//                            }
                        })
                        result[property] = referencesDict as AnyObject
                    }
                } else if let object = value as? FirebaseModel {
                    if property.hasSuffix("Nested") {
                        result[property] = object.dictionary() as AnyObject
                    } else {
                        result[property] = object.id as AnyObject
                    }
                } else {
                    result[property] = value as AnyObject
                }
            }
        }
        return result
    }
    
    func notOverridingAttributesDictionary() -> [String : AnyObject] {
        var dict = attributesDictionary()
        for (_, element) in dict.enumerated() {
            if element.value is NSNull {
                dict.removeValue(forKey: element.key)
            }
        }
        return dict
    }
    
    @objc func save() {   // save() won't persist nil String? shown as <null> in attributesDictionary()
        let newRef = ref
        id = newRef.key
        newRef.updateChildValues(self.notOverridingAttributesDictionary())
        
        // Set id for nested references since we don't save those separately
        //        let mirror = Mirror(reflecting: self)
        //        for (property, value) in mirror.children {
        //            if let property = property, let objArray = value as? [FirebaseModel], String(property.suffix(6)) == "Nested" {
        //                objArray.forEach { $0.id = objArray.index(of: $0)!.description }
        //            }
        //        }
    }
    
    @objc func saveProperty(_ property: String) {
        if let value = value(forKeyPath: property) {
            ref.child(property).setValue(value)
        } else {
            ref.child(property).removeValue()
        }
    }
    
    // ----------------------------------------------------
    // MARK: - Firebase Operations
    // ----------------------------------------------------
    
    func saveAndOverride() {
        ref.setValue(attributesDictionary)
    }
    
    func delete() {
        ref.removeValue()
    }
    
    func shouldSkip(property: String) -> Bool {
        if skipProperties.index(of: property) != nil {
            return true
        }
        // Storage properties skipping
        let storageSuffix = ".storage"
        if property.hasSuffix(storageSuffix) {
            if skipProperties.index(of: (property as NSString).substring(to: property.count - storageSuffix.count)) != nil {
                return true
            }
        }
        
        return false
    }
    
    @objc func clearAllProperties() {
        
        let mirror = Mirror(reflecting: self)
        for (property, currentValueOfProperty) in mirror.children {
            
            if let property = property, shouldSkip(property: property) == false {
                
                // Empty optional ... nil
                let typeName = typeDescription(any: currentValueOfProperty)
                if typeName.hasPrefix("Optional<") {
                    self.setValue(nil, forKey: property)
                } else {
                    // Empty object
                    let newObject = instantiateSwiftClass(ofAny: currentValueOfProperty)
                    self.setValue(newObject, forKey: property)
                }
            }
        }// end property loop
    }
    
    @objc func clear(property: String) {
        
        if let currentValueOfProperty = value(forKey: property), shouldSkip(property: property) == false {
            
            // Empty optional ... nil
            let typeName = typeDescription(any: currentValueOfProperty)
            if typeName.hasPrefix("Optional<") {
                self.setValue(nil, forKey: property)
            } else {
                // Empty object
                let newObject = instantiateSwiftClass(ofAny: currentValueOfProperty)
                self.setValue(newObject, forKey: property)
            }
        }
    }
    
    // Designed for a specialized purposes when we have the value as a property of some sort instead of just a order number in an array (especially in a situation when we are ordering by a key)
    @objc func setAttribute(_ attribute: Any) {
        
    }
    
    func setSwiftValue(_ value: Any?, forKey key: String) {
        
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if self.responds(to: NSSelectorFromString(key)) {
            super.setValue(value, forKey: key)
        } else {
            setSwiftValue(value, forKey: key)
        }
    }
    
    // Reload Stored Data ------------------------------------------------
    // TODO: UIColor, Enums, UIImage, Protocols indicating ignoration, Object database, Sets (unique object arrays)
    @objc func setAttributes(_ dictionary: Dictionary<String, AnyObject>, clear: Bool = false) {
        
        if let identifier = dictionary["id"] as? String {
            id = identifier
        }
        if let reference = dictionary["reference"] as? String {
            self.reference = Firebase.database().reference(fromURL: reference)
        }
        
        let mirror = Mirror(reflecting: self)
        for (property, currentValueOfProperty) in mirror.children {
            
            if let property = property, shouldSkip(property: property) == false {
                
                if clear == false && dictionary[property] == nil {
                    continue
                }
                
                if !(currentValueOfProperty is [AnyObject]) { // if it is an 'attribute' to decode (references stored in override)
                    
                    let instance = instantiateSwiftClass(ofAny: currentValueOfProperty) ?? currentValueOfProperty
                    
                    switch instance {
                    case is StringRawRepresentable:
                        if let rawValue = dictionary[property] as? String, let instance = instance as? StringRawRepresentable {
                            let enumerationValue = type(of: instance).init(rawValue: rawValue)
                            self.setValue(enumerationValue, forKey: property)
                        }
                    case is DatabaseReference:
                        if let urlString = dictionary[property] as? String {
                            let reference = Firebase.database().reference(fromURL: urlString)
                            self.setValue(reference, forKey: property)
                        }
                    case is URL:
                        if let urlString = dictionary[property] as? String {
                            if let url = URL(string: urlString) {
                                self.setValue(url, forKey: property)
                            }
                        }
                    case is Date:
                        if let dateString = dictionary[property] as? String {
                            if property.hasSuffix("Timestamp") {
                                if let date = Date(currentInverseString: dateString) {
                                    self.setValue(date, forKey: property)
                                }
                            } else {
                                let df = DateFormatter()
                                df.dateFormat = Format.dateFormat
                                self.setValue(df.date(from: dateString), forKey: property)
                            }
                        }
                    case let value where value is FirebaseModel:
                        let newObject = value as! FirebaseModel
                        // Single references
                        if let snapshotKey = dictionary[property] as? String {
                            newObject.id = snapshotKey
                            newObject.fetchedReference = ref.child(property)
                            self.setValue(newObject, forKey: property)
                            // Single nested objects
                        } else if let newDictionary = dictionary[property] as? [String : AnyObject] {
                            newObject.fetchedReference = ref.child(property)
                            newObject.setAttributes(newDictionary)
                            self.setValue(newObject, forKey: property)
                        }
                        
                    default:
                        
                        // Check if the value exists
                        if let value = dictionary[property], value is NSNull == false {
                            
                            // String values
                            let typeName = typeDescription(any: currentValueOfProperty)
                            switch typeName {
                            case "Optional<String>", "String":
                                self.setValue(value.description, forKey: property)
                            case "Optional<URL>", "URL":
                                self.setValue(URL(string: value.description), forKey: property)
                            default:
                                self.setValue(dictionary[property], forKey: property)
                            }
                        }
                    }
                    
                } else {
                    
                    
                    // An array of Custom classes
                    if isAnArray(any: currentValueOfProperty) {
                        
                        
                        // An Array of References
                        if let referencesDict = dictionary[property] as? [String: Int] {
                            let referencestuplesArray = referencesDict.sorted { $0.value < $1.value }
                            let array : [FirebaseModel] = referencestuplesArray.compactMap {
                                let newObject = instantiateSwiftClassOfElementFromArray(any: currentValueOfProperty) as? FirebaseModel
                                let id = $0.0
                                newObject?.fetchedReference = ref.child(property).child(id)
                                newObject?.id = id
                                return newObject
                            }
                            self.setValue(array, forKey: property)
                        }
                            // Nested objects
                        else if let objectsArray = dictionary[property] as? [String : [String: AnyObject]] { // relies on undocumented firebase behavior
                            var array = [FirebaseModel]()
                            for (_, object) in objectsArray.enumerated() {
                                if let newObject = instantiateSwiftClassOfElementFromArray(any: currentValueOfProperty) as? FirebaseModel {
                                    newObject.setAttributes(object.value)
                                    newObject.fetchedReference = ref.child(property).child(object.key)
                                    newObject.id = object.key
                                    array.append(newObject)
                                }
                            }
                            setValue(array, forKey: property)
                        } else {
                            setValue(dictionary[property], forKey: property)
                            
                        }
                        
                        // Single custom class
                    } else if let newObject = instantiateSwiftClass(ofAny: currentValueOfProperty) as? FirebaseModel {
                        // Single references
                        if let snapshotKey = dictionary[property] as? String {
                            newObject.id = snapshotKey
                            newObject.fetchedReference = ref.child(property)
                            self.setValue(newObject, forKey: property)
                            // Single nested objects
                        } else if let newDictionary = dictionary[property] as? [String : AnyObject] {
                            newObject.setAttributes(newDictionary)
                            newObject.fetchedReference = ref.child(property)
                            self.setValue(newObject, forKey: property)
                        }
                    }
                }
            }
        }
        
        // Update the object in the local database
        addToDatabase()
    }
    
    @objc func attachOnce(_ clear: Bool = false, with: @escaping () -> ()) {
//        if let id = id {
            if id.isValidFirebaseKey() {
                ref.keepSynced(true)
                ref.observeSingleEvent(of: .value, with: { snap in
                    
                    if clear {
                        self.clearAllProperties()
                    }
                    if snap.exists() {
                        let foundAttributes = snap.value as? [String: AnyObject] ?? [:]
                        self.setAttributes(foundAttributes, clear:clear)
                        self.exists = true
                    } else {
                        self.exists = false
                    }
                    with()
                })
            }
//        }
    }
    
    @objc func observeAndKeepAttached(_ clear: Bool = false, with: @escaping () -> ()) {
        stopObserving()
        
//        if let id = id {
            if id.isValidFirebaseKey() {
                ref.keepSynced(true)
                handle = ref.observe(.value, with: { snap in
                    if clear {
                        self.clearAllProperties()
                    }
                    if snap.exists() {
                        let foundAttributes = snap.value as? [String: AnyObject] ?? [:]
                        self.setAttributes(foundAttributes, clear:clear)
                        self.exists = true
                    } else {
                        self.exists = false
                    }
                    with()
                })
            }
//        }
    }
    
    
    // ----------------------------------------------------
    // MARK: - Properties
    // ----------------------------------------------------
    
    @objc func attachPropertyOnce(property: String, with: @escaping () -> ()) {
//        if let id = id {
            if id.isValidFirebaseKey() {
                ref.child(property).keepSynced(true)
                ref.child(property).observeSingleEvent(of: .value, with: { snap in
                    if snap.exists() {
                        let foundAttributes = snap.value as? [String: AnyObject] ?? [:]
                        let updatingAttributes = [property : foundAttributes] as [String: AnyObject]
                        self.setAttributes(updatingAttributes, clear:false)
                    }
                    with()
                })
            }
//        }
    }
    
    @objc func observePropertyAndKeepAttached(property: String, with: @escaping () -> ()) {
        stopObserving(property: property)
        
//        if let id = id {
            if id.isValidFirebaseKey() {
                ref.child(property).keepSynced(true)
                propertyHandles[property] = ref.child(property).observe(.value, with: { snap in
                    if snap.exists() {
                        let foundAttributes = snap.value as? [String: AnyObject] ?? [:]
                        let updatingAttributes = [property : foundAttributes] as [String: AnyObject]
                        self.setAttributes(updatingAttributes, clear:false)
                    } else {
                        self.clear(property: property)
                    }
                    with()
                })
            }
//        }
    }
    
    
    
    // To make index(of:) work
    override func isEqual(_ object: Any?) -> Bool {
        guard let obj = object as? FirebaseModel else {
            return false
        }
        return self.id == obj.id
    }
    
    
    @objc func ifExists(perform: @escaping () -> () = {}, elsePerform: @escaping () -> () = {}) {
        ref.observeSingleEvent(of: .value, with: { snap in
            self.exists = snap.exists()
            if snap.exists() { perform() } else { elsePerform() }
        })
    }
    
    @objc class func ifExists(id: String, perform: @escaping () -> () = {}, elsePerform: @escaping () -> () = {}) {
        let ref = Firebase.database().reference(withPath: basePath).child(id)
        ref.observeSingleEvent(of: .value, with: { snap in
            if snap.exists() { perform() } else { elsePerform() }
        })
    }
    
    override var description: String {
        return ("\(type(of: self)) with id: \(id) from path: \( type(of: self).basePath )\n\(attributesDictionary())" as NSString).replacingOccurrences(of: ", ", with: ",\n ")
    }
    
    override func copy() -> Any {
        let dict = dictionary()
        let newObject = type(of: self).init()
        newObject.setAttributes(dict, clear: true)
        return newObject
    }
}

// Override equivalence for optionals
func == (lhs: FirebaseModel?, rhs: FirebaseModel?) -> Bool {
    if let lid = lhs?.id, let rid = rhs?.id {
        return lid == rid
    } else if lhs?.id == nil && rhs?.id == nil {
        return true
    } else {
        return false
    }
}

