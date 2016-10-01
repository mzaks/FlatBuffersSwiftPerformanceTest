//
//  bench_encode.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

public extension FooBarContainer {
    public func toFlatBufferBuilder (builder : FlatBufferBuilder) throws -> Void {
        let offset = addToByteArray(builder)
        try builder.finish(offset, fileIdentifier: nil)
    }
}

public extension FooBarContainer {
    private func addToByteArray(builder : FlatBufferBuilder) -> Offset {
        if builder.config.uniqueTables {
            if let myOffset = builder.cache[ObjectIdentifier(self)] {
                return myOffset
            }
        }
        let offset3 = try! builder.createString(location)
        var offset0 = Offset(0)
        if list.count > 0{
            var offsets = [Offset?](count: list.count, repeatedValue: nil)
            var index = list.count - 1
            while(index >= 0){
                offsets[index] = list[index]?.addToByteArray(builder)
                index -= 1
            }
            try! builder.startVector(list.count, elementSize: strideof(Offset))
            index = list.count - 1
            while(index >= 0){
                try! builder.putOffset(offsets[index])
                index -= 1
            }
            offset0 = builder.endVector()
        }
        try! builder.openObject(4)
        try! builder.addPropertyOffsetToOpenObject(3, offset: offset3)
        try! builder.addPropertyToOpenObject(2, value : fruit!.rawValue, defaultValue : 0)
        try! builder.addPropertyToOpenObject(1, value : initialized, defaultValue : false)
        if list.count > 0 {
            try! builder.addPropertyOffsetToOpenObject(0, offset: offset0)
        }
        let myOffset =  try! builder.closeObject()
        if builder.config.uniqueTables {
            builder.cache[ObjectIdentifier(self)] = myOffset
        }
        return myOffset
    }
}

public extension FooBar {
    private func addToByteArray(builder : FlatBufferBuilder) -> Offset {
        if builder.config.uniqueTables {
            if let myOffset = builder.cache[ObjectIdentifier(self)] {
                return myOffset
            }
        }
        let offset1 = try! builder.createString(name)
        try! builder.openObject(4)
        try! builder.addPropertyToOpenObject(3, value : postfix, defaultValue : 0)
        try! builder.addPropertyToOpenObject(2, value : rating, defaultValue : 0)
        try! builder.addPropertyOffsetToOpenObject(1, offset: offset1)
        if let sibling = sibling {
            builder.put(sibling)
            try! builder.addCurrentOffsetAsPropertyToOpenObject(0)
        }
        let myOffset =  try! builder.closeObject()
        if builder.config.uniqueTables {
            builder.cache[ObjectIdentifier(self)] = myOffset
        }
        return myOffset
    }
}
