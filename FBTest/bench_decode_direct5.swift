//
//  bench_decode_direct5.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.01.17.
//  Copyright © 2017 maxim.zaks. All rights reserved.
//

import Foundation


import Foundation

public struct FooBarContainerDirect2<T : FBReader> : Hashable {
    private let reader : T
    private let myOffset : Offset
    private let localOffset: Int32
    private let vTableLength : Int16
    private let objectLength: Int16
    
    init?(reader: T, myOffset: Offset){
        self.reader = reader
        self.myOffset = myOffset
        do {
            (localOffset, vTableLength, objectLength) = try reader.vTableData(objectOffset: myOffset)
        } catch {
            return nil
        }
        
    }
    public init?(_ reader: T) {
        self.reader = reader
        guard let offest = reader.rootObjectOffset else {
            return nil
        }
        self.myOffset = offest
        do {
            (localOffset, vTableLength, objectLength) = try reader.vTableData(objectOffset: myOffset)
        } catch {
            return nil
        }
    }
    
    public var list : FBVector<FooBarDirect2<T>, T>? {
        if let offsetList = reader.getOffset(objectOffset: myOffset, propertyIndex: 0, localOffset:localOffset, vTableLength:vTableLength, objectLength:objectLength) {
            return FBVector(count: reader.getVectorLength(vectorOffset: offsetList), reader: self.reader, myOffset: offsetList)
        }
        return nil
    }
    public var initialized : Bool {
        get {
            guard let r : Bool = reader.get(objectOffset: myOffset, propertyIndex: 1, localOffset:localOffset, vTableLength:vTableLength, objectLength:objectLength) else {
                return false
            }
            return r
        }
    }
    public var fruit : Enum? {
        get {
            guard let r : Int16 = reader.get(objectOffset: myOffset, propertyIndex: 2, localOffset:localOffset, vTableLength:vTableLength, objectLength:objectLength) else {
                return Enum.apples
            }
            return Enum(rawValue: r )
        }
    }
    public var location : UnsafeBufferPointer<UInt8>? { get { return reader.getStringBuffer(stringOffset: reader.getOffset(objectOffset: myOffset, propertyIndex:3, localOffset:localOffset, vTableLength:vTableLength, objectLength:objectLength)) } }
    public var hashValue: Int { return Int(myOffset) }
    
    public static func ==<T>(t1: FooBarContainerDirect2<T>, t2: FooBarContainerDirect2<T>) -> Bool {
        return t1.reader.isEqual(other: t2.reader) && t1.myOffset == t2.myOffset
    }
}


public struct FooBarDirect2<T: FBReader> : Hashable, DirectAccess {
    private let reader : T
    private let myOffset : Offset
    private let localOffset: Int32
    private let vTableLength : Int16
    private let objectLength: Int16
    
    public init?<R : FBReader>(reader: R, myOffset: Offset?){
        guard let reader = reader as? T , let myOffset = myOffset else {
            return nil
        }
        do {
            (localOffset, vTableLength, objectLength) = try reader.vTableData(objectOffset: myOffset)
        } catch {
            return nil
        }
        self.reader = reader
        self.myOffset = myOffset
    }

    public var sibling : Bar? {
        get { return reader.get(objectOffset: myOffset, propertyIndex: 0, localOffset:localOffset, vTableLength:vTableLength, objectLength:objectLength)}
    }
    public var name : UnsafeBufferPointer<UInt8>? { get { return reader.getStringBuffer(stringOffset: reader.getOffset(objectOffset: myOffset, propertyIndex:1, localOffset:localOffset, vTableLength:vTableLength, objectLength:objectLength)) } }
    public var rating : Float64 {
        get {
            guard let r : Float64 = reader.get(objectOffset: myOffset, propertyIndex: 2, localOffset:localOffset, vTableLength:vTableLength, objectLength:objectLength) else{
                return 0
            }
            return r
        }
    }
    public var postfix : UInt8 {
        get {
            guard let r : UInt8 = reader.get(objectOffset: myOffset, propertyIndex: 3, localOffset:localOffset, vTableLength:vTableLength, objectLength:objectLength) else {
                return 0
            }
            return r
        }
    }
    public var hashValue: Int { return Int(myOffset) }
    
    public static func ==<T>(t1: FooBarDirect2<T>, t2: FooBarDirect2<T>) -> Bool {
        return t1.reader.isEqual(other: t2.reader) && t1.myOffset == t2.myOffset
    }
}

