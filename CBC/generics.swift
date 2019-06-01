//
//  generics.swift
//
//  Created by Steve Leeke on 9/22/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

/**
 Makes arrays comparable
 */
func == <T : Equatable>(lhs: [T]?, rhs: [T]?) -> Bool
{
    guard let lhs = lhs else {
        return false
    }
    
    guard let rhs = rhs else {
        return false
    }
    
    if lhs.count != rhs.count {
        return false
    } else {
        for index in 0..<lhs.count {
            if rhs[index] != lhs[index] {
                return false
            }
        }
    }

    return true
}

/**
 Extends comparable to less than between optionals
 */
func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool
{
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

/**
 Extends comparable to less than or equal between optionals
 */
func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool
{
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    case (nil, _?):
        return true
    default:
        return false
    }
}

/**
 Extends comparable to greater than or equal between optionals
 */
func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool
{
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}

/**
 Extends comparable to greater than between optionals
 */
func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool
{
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

/**

 Generic class that calls an optional method to set a default value if its value is nil.
 
 Can be a struct (w/o deinit) or class

 Alternative is a pattern:
 
     var _value : String?
     {
         didSet {
 
         }
     }
     var value : String?
     {
         get {
             return _value ?? <default_value>
         }
         set {
             _value = newValue
         }
     }
 
 */

class Default<T>
{
    deinit {
        debug(self)
    }
    
    private var _value : T?
    {
        didSet {

        }
    }
    
    var value : T?
    {
        get {
            // Calls defaultValue EVERY TIME _value is nil
            return _value ?? defaultValue?()
        }
        set {
            _value = newValue
        }
    }
    
    var defaultValue : (()->(T?))?
    
    init(_ defaultValue:(()->(T?))? = nil)
    {
        self.defaultValue = defaultValue
    }
}

/**
 
 Generic class intended to support lots of functionality
 
 - Properties:
     - Closures:
        - onGet
        - onSet
        - onNil
        - onDidSet
        - defaultValue
 
    - Methods:
        - clear()
 
 CAN LEAD TO BAD PERFORMANCE if used for large numbers of shadowed scalars.
 
 Very complicated and because of the performance problems, is not used.  It is better to just use the var _foo { didSet {} } and var foo { get set } pattern.
 
 It can be a struct if onNil is not used as shown below (mutating self in a var is not allowed).

 */

class Shadowed<T>
{
    deinit {
        debug(self)
    }
    
    private var _value : T?
    {
        didSet {
            onDidSet?(_value,oldValue)
        }
    }

    var value : T?
    {
        get {
            guard onGet == nil else {
                return onGet?(_value)
            }

            if _value == nil {
                _value = onNil?()
            }

            return _value ?? defaultValue?()
        }
        set {
            guard onSet == nil else {
                _value = onSet?(newValue)
                return
            }

            _value = newValue
        }
    }

    func clear()
    {
        _value = nil
    }

    var defaultValue : (()->T?)?

    var onGet : ((T?)->T?)?

    var onSet : ((T?)->T?)?

    var onNil : (()->T?)?

    var onDidSet : ((T?,T?)->())?

    init(_ defaultValue:(()->T?)? = nil,onGet:((T?)->T?)? = nil,onSet:((T?)->T?)? = nil,onNil:(()->T?)? = nil,onDidSet:((T?,T?)->())? = nil)
    {
        self.defaultValue = defaultValue
    }
}

/**

 Generic class to implement a very generic approach to thread safety.
 
 Nothing is assumed about T.
 
 */

class ThreadSafe<T>
{
    deinit {
        debug(self)
    }
    
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: UUID().uuidString)
    }()

    var _value : T?
    
    var value : T?
    {
        get {
            return queue.sync {
                return _value
            }
        }
        set {
            queue.sync {
                _value = newValue
            }
        }
    }
    
    // Because we can't initialize the value from a generic, e.g. T()
    // If the value is, for example, an array, the elements of which will
    // be modified, it needs to be initialized with a blank array.
    // This can by done by passing a T or a function that returns T
    // If T is passed/returned by value or by reference will depend upon T.
    
    init(_ initialValue:T? = nil)
    {
        self.value = initialValue
    }
    
    init(_ initialValue:(()->(T))? = nil)
    {
        self.value = initialValue?()
    }
}

/**
 
 Generic class to implement a thread safe array.
 
 Nothing is assumed about T.  Re-implements a lot of array methods so there is probably should be a super class or protocol.
 
 */

class ThreadSafeArray<T>
{
    deinit {
        debug(self)
    }
    
    var last : T?
    {
        get {
            return queue.sync {
                return storage.last
            }
        }
    }
    
    func removeLast() -> T?
    {
        return queue.sync {
            guard storage.count > 0 else {
                return nil
            }
            return storage.removeLast()
        }
    }
    
    func forEach(f:(T)->Void)
    {
        queue.sync {
            storage.forEach(f)
        }
    }
    
    func contains(element:T, compare:(T)->Bool) -> Bool
    {
        return queue.sync {
            return storage.contains(where: compare)
        }
    }
    
    var first : T?
    {
        get {
            return queue.sync {
                return storage.first
            }
        }
    }

    private var storage = [T]()
    
    func sorted(sort:((T,T)->Bool)) -> [T]
    {
        return queue.sync {
            return storage.sorted(by: sort)
        }
    }

    var copy : [T]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage : nil
            }
        }
    }
    
    var reversed : [T]?
    {
        get {
            return queue.sync {
                return storage.count > 0 ? storage.reversed() : nil
            }
        }
    }
    
    var count : Int
    {
        get {
            return queue.sync {
                return storage.count
            }
        }
    }
    
    var isEmpty : Bool
    {
        return queue.sync {
            return storage.isEmpty
        }
    }

    func clear()
    {
        queue.sync {
            self.storage = [T]()
        }
    }
    
    func append(_ item:T)
    {
        queue.sync {
            storage.append(item)
        }
    }
    
    func firstIndex(f:(T)->Bool) -> Array<T>.Index?
    {
        return queue.sync {
            return storage.firstIndex(where: f)
        }
    }
    
    func filter(_ f:(T)->Bool) -> Array<T>?
    {
        return queue.sync {
            return storage.filter(f)
        }
    }
    
    func remove(at index:Int)
    {
        queue.sync {
            if storage.count > index {
                storage.remove(at:index)
            }
        }
    }
    
    func update(storage:Any?)
    {
        queue.sync {
            guard let storage = storage as? [T] else {
                return
            }
            
            self.storage = storage
        }
    }

    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
    var name : String?
    
    init(name:String? = nil)
    {
        self.name = name
    }
    
    subscript(key:Int) -> T?
    {
        get {
            return queue.sync {
                if key >= 0,key < storage.count {
                    return storage[key]
                }
                
                return nil
            }
        }
        set {
            queue.sync {
                guard let newValue = newValue else {
                    if key >= 0,key < storage.count {
                        storage.remove(at: key)
                    }
                    return
                }
                
                if key >= 0,key < storage.count {
                    storage[key] = newValue
                }
                
                if key == storage.count {
                    storage.append(newValue)
                }
            }
        }
    }
}

/**
 
 Generic class that implements a thread safe nested heirarchy of any depth of dictionaries the keys of which are always strings.  The final value is not a dictionary of key:String but T.  I.e. the subscript's keys are a variadic parameter.
 
 This means that the basic dictionary is [String:Any] since we don't know if the Any will be another [String:Any] or T.
 
 When a set is made through the subscript, because we have a variable number of keys, we must keep track of where we are in the hierarchy, keeping track of the level in the hierarchy, which amounts to have a variable dict:[String:Any]? for the current level, and because dictionaries are value, not reference, objects, when that variables value is set, a copy is made, so by the time the "leaf" value is set, e.g. a T, and all the intermediate dictionaries for all the keys traversed, e.g. [String:Any]() is inserted where needed, the final dictionary hierarchy is NOT what is contained in the storage property, but is in a temporary variable which must be copied back into storage.
 
 */

class ThreadSafeDN<T>
{
    deinit {
        debug(self)
        
    }
    
    // Make it thread safe
    lazy var queue : DispatchQueue = { [weak self] in
        return DispatchQueue(label: self?.name ?? UUID().uuidString)
        }()
    
    internal var storage = [String:Any]()
    
    var name : String?
    
    init(name:String? = nil) // ,levels:Int
    {
        self.name = name
    }
    
    var count : Int
    {
        get {
            return queue.sync { [weak self] in
                return self?.storage.count ?? 0
            }
        }
    }
    
    var copy : [String:Any]?
    {
        get {
            return queue.sync { [weak self] in
                return self?.storage.count > 0 ? self?.storage : nil
            }
        }
    }
    
    func clear()
    {
        queue.sync { [weak self] in
            self?.storage = [String:Any]()
        }
    }
    
    func update(storage:[String:Any]?)
    {
        queue.sync { [weak self] in
            guard let storage = storage else {
                return
            }
            
            self?.storage = storage
        }
    }
    
    func keys(_ keys:String...) -> [String]?
    {
        // keys.count is the number of levels deep in the hierarchy of dictionaries we are to go
        // the array.last is key to the dictionary before last, it returns the last from which
        // keys are produced.
        
        // Doesn't work, will always return nil because self[] always returns T? which in this case is nil.
        //        return (self[keys.joined(separator: ",")] as? [String:Any])?.keys
        
        // This differs from the subscript algorithm in the return before return nil
        return queue.sync { [weak self] in
            guard keys.count > 0 else {
                if let keys = self?.storage.keys {
                    return keys.count > 0 ? Array(keys) : nil
                }
                return nil
            }
            
            // start with a copy of storage
            var dict:[String:Any]? = self?.storage
            
            for index in keys.indices {
                // go through all of the levels but the last
                guard index < keys.indices.last else {
                    break
                }
                // keep going deeper into the nested dictionaries
                dict = dict?[keys[index]] as? [String:Any]
            }
            
            if let index = keys.indices.last, let keys = (dict?[keys[index]] as? [String:Any])?.keys {
                // we've reached the last index, the value of which in the current dictionary (one before last)
                // is the last dictionary (of N hierarchical levels deep) from which we return the keys.
                return keys.count > 0 ? Array(keys) : nil
            } else {
                return nil
            }
        }
    }
    
    func values(_ keys:String...) -> [T]?
    {
        // keys.count is the number of levels deep in the hierarchy of dictionaries we are to go
        // the array.last is key to the dictionary before last, it returns the last from which
        // keys are produced.
        
        // Doesn't work, will always return nil because self[] always returns T? which in this case is nil.
        //        return (self[keys.joined(separator: ",")] as? [String:Any])?.keys
        
        // This differs from the subscript algorithm in the return before return nil
        return queue.sync { [weak self] in
            guard keys.count > 0 else {
                return Array(storage.values) as? [T]
            }
            
            // start with a copy of storage
            var dict:[String:Any]? = storage
            
            for index in keys.indices {
                // go through all of the levels but the last
                guard index < keys.indices.last else {
                    break
                }
                // keep going deeper into the nested dictionaries
                dict = dict?[keys[index]] as? [String:Any]
            }
            
            if let index = keys.indices.last, let values = (dict?[keys[index]] as? [String:T])?.values {
                // we've reached the last index, the value of which in the current dictionary (one before last)
                // is the last dictionary (of N hierarchical levels deep) from which we return the keys.
                return Array(values)
            } else {
                return nil
            }
        }
    }
    
    func get(_ keys:[String]) -> T?
    {
        guard keys.count > 0 else {
            return nil
        }
        
        guard keys.count > 1 else {
            return queue.sync { [weak self] in
                return self?.storage[keys[0]] as? T
            }
        }
        
        // keys.count is the number of levels deep in the hierarchy of dictionaries we are to go
        // the array.last is key to the last dictionary, it returns the value which is cast to T and returned
        
        // This differs from the keys algorithm in the return before return nil
        return queue.sync { [weak self] in
            // start with a copy of storage
            var dict:[String:Any]? = self?.storage
            
            for index in keys.indices {
                // go through all of the levels but the last
                guard index < keys.indices.last else {
                    break
                }
                
                // keep going deeper into the nested dictionaries
                dict = dict?[keys[index]] as? [String:Any]
            }
            
            if let index = keys.indices.last {
                // we've reached the last index, the value of which in the current dictionary (the last)
                // is the value we return as? T
                return dict?[keys[index]] as? T
            } else {
                return nil
            }
        }
    }
    
    func set(_ keys:[String],_ newValue:T?)
    {
        guard keys.count > 0 else {
            return
        }
        
        guard keys.count > 1 else {
            queue.sync { [weak self] in
                self?.storage[keys[0]] = newValue
            }
            return
        }
        
        //            print(keys)
        queue.sync { [weak self] in
            // start with a copy of storage
            var dict:[String:Any]? = storage
            
            // keey an array of all the dictionaries we traverse
            // since everytime we touch a new level we make a copy
            // since dictionaries are value, not reference, objects
            // in order to copy them back after we finally set the value
            var dicts = [[String:Any]]()
            
            // Go through the levels, turning the hierarchy into an array of dicts
            for index in 0..<keys.count {
                // Except the last since that's the dictionary in which we have to set the value
                guard index < (keys.count - 1) else {
                    break
                }
                
                guard dict != nil else {
                    // If this ever happens something is very wrong.
                    break
                }
                
                // keep a copy of each dict we touch
                dicts.append(dict!)
                
                // If this level's value is nil, set a blank dictionary in its place
                // as we'll need that in the next level, i.e. be self-assembling
                if dict?[keys[index]] == nil {
                    dict?[keys[index]] = [String:Any]()
                }
                
                // keep going deeper into the nested dictionaries
                dict = dict?[keys[index]] as? [String:Any]
            }
            
            // Don't append the last dict since we have it in hand (i.e. the var dict)
            //                dicts.append(dict!)
            
            // Set the new value at the deepest level, which is assumed to be the leaf level
            // i.e. no dictionaries as values at this level
            if let last = keys.last {
//                print(keys[index])
                dict?[last] = newValue
            }
            
            // Now we have to reconstruct the hierarchy
            // Start with the deepest level
            var newDict:[String:Any]? = dict
            
            // got through the other levels in the hierarchy
            for index in 0..<(keys.count - 1) {
                // In reverse order, of course
                let maxIndex = keys.count - 2 // since keys.count - 1 is one more than we'll ever go.
                let index = maxIndex - index // Do it in reverse order since the highest index in the array is the deepest level in the hierarchy other than the last, ie. the "leaf" where the Any is T.
                
                dicts[index][keys[index]] = newDict
                
                // Move to the next level higher up
                newDict = dicts[index]
            }
            
            // Reset storage to the modified dict hierarchy
            //                print(newDict!)
            
            guard newDict != nil else {
                return
            }
            
            self?.storage = newDict! // Yes, this could crash.  If it does, it probably should because something is very, very wrong, like the wrong number of keys is used to access T.
        }
    }
    
    subscript(keys:[String]) -> T?
    {
        get {
            return get(keys)
        }
        set {
            set(keys,newValue)
        }
    }
    
    subscript(keys:String...) -> T?
    {
        get {
            return get(keys)
        }
        set {
            set(keys,newValue)
        }
    }
}

/**
 
    Generic class to fetch content using a sync queue to serialize (i.e. block additional) access.  No assumptions are made about T.
 
    The content is cached and can optionally be stored to and retrieve from local storage.
 
    The content can be loaded in the background using an operationQueue and all subsequent accesses
    will block until it is loaded.
 
    - Properties
        - an operationQueue for background loading
        - fetch, a closure that returns a T (assumed to be from the network or similarly expensive/slow source, e.g. computation), fetch is called to get T is made when cache is nil
        - store, a closure to store T (assumed to be from local storage)
        - retrieve, a closure to retrieve T (assumed to be from local storage)
        - name for the queue (optional)
        - didSet, called with T after it is cache is set
        - cache - the T fetch'ed
 
    - Methods:
        - clear() - reset the cache to nil to cause a new fetch on next access.
 */

class Fetch<T>
{
    private lazy var operationQueue : OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "Fetch" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        debug(self)
        operationQueue.cancelAllOperations()
    }
    
    init(name:String? = nil,fetch:(()->(T?))? = nil)
    {
        self.name = name
        self.fetch = fetch
    }
    
    var interrupt : (()->Bool)?
    
    var fetch : (()->(T?))?
    
    var store : ((T?)->())?
    var retrieve : (()->(T?))?
    
    var name : String?
    
    var didSet : ((T?)->())?
    var cache : T?
    {
        didSet {
            didSet?(cache)
        }
    }
    
    func clear()
    {
        queue.sync {
            cache = nil
        }
    }
    
    lazy private var queue : DispatchQueue = {
        return DispatchQueue(label: name ?? UUID().uuidString)
    }()
    
    func load()
    {
        queue.sync {
            guard cache == nil else {
                return
            }
            
            cache = retrieve?()
            
            guard cache == nil else {
                return
            }
            
            self.cache = self.fetch?()
            
            store?(self.cache)
        }
    }
    
    func fill()
    {
        operationQueue.addOperation {
            self.load()
        }
    }
    
    var result:T?
    {
        get {
            load()
            
            return cache
        }
    }
}

/**

    Shadow pattern (protocols do not allow generic types) for tracking fileSize

 */

protocol Size
{
    var _fileSize : Int? { get set }
    var fileSize : Int? { get set }
}

/**
 
 A subclass of Fetch<T> that requires T to be Codable so it can be stored and retrieved in local storage.
 
 */

// It would nice if properties that were FetchCodable were kept track of so the class would know
// how to get the size of all the cache files or to delete them, or to clear all the cache properties to reduce memory usage
// without having to keep track of each individual proeprty, e.g. a FetchCodable index whenever a class (or struct)
// uses one(?) or more FetchCodable properties.

class FetchCodable<T:Codable> : Fetch<T>, Size
{
    deinit {
        debug(self)
    }
    
    var fileSystemURL : URL?
    {
        get {
            return name?.fileSystemURL
        }
    }
    
    internal var _fileSize : Int?
    var fileSize : Int?
    {
        get {
            guard let fileSize = _fileSize else {
                _fileSize = fileSystemURL?.fileSize
                return _fileSize
            }

            return fileSize
        }
        set {
            _fileSize = newValue
        }
    }
    
    func delete(block:Bool)
    {
        clear()
        fileSize = nil
        fileSystemURL?.delete(block:block)
    }
    
    // name MUST be unique to every INSTANCE, not just the class!
    override init(name: String?, fetch: (() -> (T?))? = nil)
    {
        super.init(name: name, fetch: fetch)

        store = { [weak self] (t:T?) in
            guard Globals.shared.cacheDownloads else {
                return
            }

            guard let t = t else {
                return
            }

            guard let fileSystemURL = self?.fileSystemURL else {
                return
            }

            let dict = ["value":t]
            
            do {
                let data = try JSONEncoder().encode(dict)
//                print("able to encode T: \(fileSystemURL.lastPathComponent)")

                do {
                    try data.write(to: fileSystemURL)
//                    print("able to write T to the file system: \(fileSystemURL.lastPathComponent)")
                    self?.fileSize = fileSystemURL.fileSize
                } catch let error {
//                    print("unable to write T to the file system: \(fileSystemURL.lastPathComponent)")
                    NSLog("unable to write T to the file system: \(fileSystemURL.lastPathComponent)", error.localizedDescription)
                }
            } catch let error {
//                print("unable to encode T: \(fileSystemURL.lastPathComponent)")
                NSLog("unable to encode T: \(fileSystemURL.lastPathComponent)", error.localizedDescription)
            }
        }

        retrieve = { [weak self] in
            guard Globals.shared.cacheDownloads else {
                return nil
            }

            guard let fileSystemURL = self?.fileSystemURL else {
                return nil
            }

            do {
                let data = try Data(contentsOf: fileSystemURL)
//                print("able to read T from storage: \(fileSystemURL.lastPathComponent)")

                do {
                    let dict = try JSONDecoder().decode([String:T].self, from: data)
//                    print("able to decode T from storage: \(fileSystemURL.lastPathComponent)")
                    return dict["value"]
                } catch let error {
//                    print("unable to decode T from storage: \(fileSystemURL.lastPathComponent)")
                    NSLog("unable to decode T from storage: \(fileSystemURL.lastPathComponent)", error.localizedDescription)
                }
            } catch let error {
//                print("unable to read T from storage: \(fileSystemURL.lastPathComponent)")
                NSLog("unable to read T from storage: \(fileSystemURL.lastPathComponent)", error.localizedDescription)
            }

            return nil
        }
    }
}
