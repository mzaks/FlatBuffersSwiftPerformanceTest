//
//  bench_createDefinitions.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

public extension FooBar {
    private static func create(reader : FBReader, objectOffset : Offset?) -> FooBar? {
        guard let objectOffset = objectOffset else {
            return nil
        }
        if  let cache = reader.cache,
            let o = cache.objectPool[objectOffset] {
            return o as? FooBar
        }
        let _result = FooBar()
        _result.sibling = reader.get(objectOffset, propertyIndex: 0)
        _result.name = reader.getStringBuffer(reader.getOffset(objectOffset, propertyIndex: 1))?§
        _result.rating = reader.get(objectOffset, propertyIndex: 2, defaultValue: 0)
        _result.postfix = reader.get(objectOffset, propertyIndex: 3, defaultValue: 0)
        if let cache = reader.cache {
            cache.objectPool[objectOffset] = _result
        }
        return _result
    }
}

public extension FooBarContainer {
    private static func create(reader : FBReader, objectOffset : Offset?) -> FooBarContainer? {
        guard let objectOffset = objectOffset else {
            return nil
        }
        if  let cache = reader.cache,
            let o = cache.objectPool[objectOffset] {
            return o as? FooBarContainer
        }
        let _result = FooBarContainer()
        let offset_list : Offset? = reader.getOffset(objectOffset, propertyIndex: 0)
        let length_list = reader.getVectorLength(offset_list)
        if(length_list > 0){
            var index = 0
            _result.list.reserveCapacity(length_list)
            while index < length_list {
                let element = FooBar.create(reader, objectOffset: reader.getVectorOffsetElement(offset_list, index: index))
                _result.list.append(element)
                index += 1
            }
        }
        _result.initialized = reader.get(objectOffset, propertyIndex: 1, defaultValue: false)
        _result.fruit = Enum(rawValue: reader.get(objectOffset, propertyIndex: 2, defaultValue: Enum.Apples.rawValue))
        _result.location = reader.getStringBuffer(reader.getOffset(objectOffset, propertyIndex: 3))?§
        if let cache = reader.cache {
            cache.objectPool[objectOffset] = _result
        }
        return _result
    }
}

public extension FooBarContainer {
    public static func fromReader(reader : FBReader) -> FooBarContainer? {
        let objectOffset = reader.rootObjectOffset
        return create(reader, objectOffset : objectOffset)
    }
}
