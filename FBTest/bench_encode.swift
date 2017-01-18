//
//  bench_encode.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

public extension FooBarContainer {
    public func toFlatBufferBuilder (_ builder : FBBuilder) throws -> Void {
        let offset = try addToByteArray(builder)
        try builder.finish(offset: offset, fileIdentifier: nil)
    }
}

public extension FooBarContainer {
    fileprivate func addToByteArray(_ builder : FBBuilder) throws -> Offset {
        if builder.config.uniqueTables {
            if let myOffset = builder.cache[ObjectIdentifier(self)] {
                return myOffset
            }
        }
        let offset3 = try builder.createString(value: location)
        var offset0 = Offset(0)
        if list.count > 0{
            var offsets = [Offset?](repeating: nil, count: list.count)
            var index = list.count - 1
            while(index >= 0){
                offsets[index] = list[index]?.addToByteArray(builder)
                index -= 1
            }
            try! builder.startVector(count: list.count, elementSize: MemoryLayout<Offset>.stride)
            index = list.count - 1
            while(index >= 0){
                try! builder.putOffset(offset: offsets[index])
                index -= 1
            }
            offset0 = builder.endVector()
        }
        try! builder.openObject(numOfProperties: 4)
        try! builder.addPropertyOffsetToOpenObject(propertyIndex: 3, offset: offset3)
        try! builder.addPropertyToOpenObject(propertyIndex: 2, value : fruit!.rawValue, defaultValue : 0)
        try! builder.addPropertyToOpenObject(propertyIndex: 1, value : initialized, defaultValue : false)
        if list.count > 0 {
            try builder.addPropertyOffsetToOpenObject(propertyIndex: 0, offset: offset0)
        }
        let myOffset =  try builder.closeObject()
        if builder.config.uniqueTables {
            builder.cache[ObjectIdentifier(self)] = myOffset
        }
        return myOffset
    }
}

public extension FooBar {
    fileprivate func addToByteArray(_ builder : FBBuilder) -> Offset {
        if builder.config.uniqueTables {
            if let myOffset = builder.cache[ObjectIdentifier(self)] {
                return myOffset
            }
        }
        let offset1 = try! builder.createString(value: name)
        try! builder.openObject(numOfProperties: 4)
        try! builder.addPropertyToOpenObject(propertyIndex: 3, value : postfix, defaultValue : 0)
        try! builder.addPropertyToOpenObject(propertyIndex: 2, value : rating, defaultValue : 0)
        try! builder.addPropertyOffsetToOpenObject(propertyIndex: 1, offset: offset1)
        if let sibling = sibling {
            builder.put(value: sibling)
            try! builder.addCurrentOffsetAsPropertyToOpenObject(propertyIndex: 0)
        }
        let myOffset =  try! builder.closeObject()
        if builder.config.uniqueTables {
            builder.cache[ObjectIdentifier(self)] = myOffset
        }
        return myOffset
    }
}
