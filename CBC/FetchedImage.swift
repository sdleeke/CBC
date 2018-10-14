//
//  FetchedImage.swift
//  TWU
//
//  Created by Steve Leeke on 10/5/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

class FetchImage
{
    var url : URL?
    
    init(url:URL?)
    {
        self.url = url
    }
    
    func fetchIt() -> UIImage?
    {
        return self.url?.image
    }
    
    func block(_ block:((UIImage?)->()))
    {
        if let image = image {
            block(image)
        }
    }
    
    var imageName : String?
    {
        return url?.lastPathComponent
    }
    
    var image : UIImage?
    {
        get {
            return fetch.result
        }
    }
    
    func load()
    {
        fetch.load()
    }
    
    lazy var fetch:Fetch<UIImage> = {
        let fetch = Fetch<UIImage>(name:imageName)
        
        fetch.fetch = {
            self.fetchIt()
        }
        
        return fetch
    }()
}

class FetchCachedImage : FetchImage
{
    private static var cache : ThreadSafeDictionary<UIImage>! = {
        return ThreadSafeDictionary<UIImage>(name:"FetchImageCache")
    }()

    override func fetchIt() -> UIImage?
    {
        if let image = self.cachedImage {
            return image
        }
        
        guard let image = self.url?.image else {
            return nil
        }
        
        self.cachedImage = image
        
        return image
    }

    func clearCache()
    {
        FetchCachedImage.cache.clear()
    }
    
    var cachedImage : UIImage?
    {
        get {
            return FetchCachedImage.cache[self.imageName]
        }
        set {
            FetchCachedImage.cache[self.imageName] = newValue
        }
    }
}
