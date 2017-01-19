//
//  bench_decode_direct4.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

public struct FooBarContainerDirect<T : FBReader> : Hashable {
    fileprivate let reader : T
    fileprivate let myOffset : Offset
    init(reader: T, myOffset: Offset){
        self.reader = reader
        self.myOffset = myOffset
    }
    public init?(_ reader: T) {
        self.reader = reader
        guard let offest = reader.rootObjectOffset else {
            return nil
        }
        self.myOffset = offest
    }

    public var list : FBVector<FooBarDirect<T>, T>? {
        if let offsetList = reader.getOffset(objectOffset: myOffset, propertyIndex: 0) {
            return FBVector(count: reader.getVectorLength(vectorOffset: reader.getOffset(objectOffset: myOffset, propertyIndex: 0)), reader: self.reader, myOffset: offsetList)
        }
        return nil
   }
    public var listCount : Int {
        return reader.getVectorLength(vectorOffset: reader.getOffset(objectOffset: myOffset, propertyIndex: 0))
    }
    public func getListElement(atIndex index : Int) -> FooBarDirect<T>? {
        let offsetList = reader.getOffset(objectOffset: myOffset, propertyIndex: 0)
        if let ofs = reader.getVectorOffsetElement(vectorOffset: offsetList, index: index) {
            return FooBarDirect(reader: reader, myOffset: ofs)
        }
        return nil
    }
    public var initialized : Bool {
        get { return reader.get(objectOffset: myOffset, propertyIndex: 1, defaultValue: false) }
    }
    public var fruit : Enum? {
        get { return Enum(rawValue: reader.get(objectOffset: myOffset, propertyIndex: 2, defaultValue: Enum.apples.rawValue)) }
    }
    public var location : UnsafeBufferPointer<UInt8>? { get { return reader.getStringBuffer(stringOffset: reader.getOffset(objectOffset: myOffset, propertyIndex:3)) } }
    public var hashValue: Int { return Int(myOffset) }
}
public func ==<T>(t1: FooBarContainerDirect<T>, t2: FooBarContainerDirect<T>) -> Bool {
    return t1.reader.isEqual(other: t2.reader) && t1.myOffset == t2.myOffset
}

public struct FooBarDirect<T: FBReader> : Hashable, DirectAccess {
    fileprivate let reader : T
    fileprivate let myOffset : Offset
    public init?<R : FBReader>(reader: R, myOffset: Offset?){
        self.reader = reader as! T
        self.myOffset = myOffset!
    }
//    public init?(reader: T, myOffset: Offset?){
//        self.reader = reader
//        self.myOffset = myOffset!
//    }
    public var sibling : Bar? {
        get { return reader.get(objectOffset: myOffset, propertyIndex: 0)}
    }
    public var name : UnsafeBufferPointer<UInt8>? { get { return reader.getStringBuffer(stringOffset: reader.getOffset(objectOffset: myOffset, propertyIndex:1)) } }
    public var rating : Float64 {
        get { return reader.get(objectOffset: myOffset, propertyIndex: 2, defaultValue: 0) }
    }
    public var postfix : UInt8 {
        get { return reader.get(objectOffset: myOffset, propertyIndex: 3, defaultValue: 0) }
    }
    public var hashValue: Int { return Int(myOffset) }
}
public func ==<T>(t1: FooBarDirect<T>, t2: FooBarDirect<T>) -> Bool {
    return t1.reader.isEqual(other: t2.reader) && t1.myOffset == t2.myOffset
}
