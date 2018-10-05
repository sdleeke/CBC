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

        guard let url = url else {
            return
        }
        
        fetch = Fetch<UIImage>(name:url.lastPathComponent)
            
        fetch?.fetch = {
            return self.url?.image
        }
    }
    
    func block(_ block:((UIImage?)->()))
    {
        if let image = image {
            block(image)
        }
    }
    
    var image : UIImage?
    {
        get {
            return fetch?.result
        }
    }
    
    func load()
    {
        fetch?.load()
    }
    
    var fetch : Fetch<UIImage>?
}

class FetchCachedImage : FetchImage
{
    private static var cache : ThreadSafeDictionary<UIImage>! = {
        return ThreadSafeDictionary<UIImage>(name:"FetchImageCache")
    }()

    override init(url: URL?)
    {
        super.init(url: url)
            
        fetch?.fetch = {
            if let image = self.cachedImage {
                return image
            }
            
            guard let image = self.url?.image else {
                return nil
            }
            
            self.cachedImage = image
            
            return image
        }
    }
    
    func clearCache()
    {
        FetchCachedImage.cache.clear()
    }
    
    var cachedImage : UIImage?
    {
        get {
            return FetchCachedImage.cache[self.url?.lastPathComponent]
        }
        set {
            FetchCachedImage.cache[self.url?.lastPathComponent] = newValue
        }
    }
}

