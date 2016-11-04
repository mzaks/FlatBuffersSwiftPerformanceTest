//
//  bench_decode_direct3.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

extension FooBarContainer {
    public struct Direct3 : Hashable {
        fileprivate let reader : FBMemoryReaderClass
        fileprivate let myOffset : Offset
        init(reader: FBMemoryReaderClass, myOffset: Offset){
            self.reader = reader
            self.myOffset = myOffset
        }
        public init?(_ reader: FBMemoryReaderClass) {
            self.reader = reader
            guard let offest = reader.rootObjectOffset else {
                return nil
            }
            self.myOffset = offest
        }
        public var listCount : Int {
            return reader.getVectorLength(vectorOffset: reader.getOffset(objectOffset: myOffset, propertyIndex: 0))
        }
        public func getListElement(atIndex index : Int) -> FooBar.Direct3? {
            let offsetList = reader.getOffset(objectOffset: myOffset, propertyIndex: 0)
            if let ofs = reader.getVectorOffsetElement(vectorOffset: offsetList, index: index) {
                return FooBar.Direct3(reader: reader, myOffset: ofs)
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
}

public func ==(t1 : FooBarContainer.Direct3, t2 : FooBarContainer.Direct3) -> Bool {
    return t1.reader === t2.reader && t1.myOffset == t2.myOffset
}

extension FooBar {
    public struct Direct3 : Hashable {
        fileprivate let reader : FBMemoryReaderClass
        fileprivate let myOffset : Offset
        init(reader: FBMemoryReaderClass, myOffset: Offset){
            self.reader = reader
            self.myOffset = myOffset
        }
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
}
public func ==(t1 : FooBar.Direct3, t2 : FooBar.Direct3) -> Bool {
    return t1.reader === t2.reader && t1.myOffset == t2.myOffset
}




/*
extension FooBarContainer {
    public struct Direct3 : Hashable {
        private let reader : Unmanaged<FBMemoryReaderClass>
        private let myOffset : Offset
        init(reader: FBMemoryReaderClass, myOffset: Offset){
            self.reader = Unmanaged.passUnretained(reader)
            self.myOffset = myOffset
        }
        public init?(_ reader: FBMemoryReaderClass) {
            self.reader = Unmanaged.passUnretained(reader)
            guard let offest = reader.rootObjectOffset else {
                return nil
            }
            self.myOffset = offest
        }
        public var listCount : Int {
            return reader.takeUnretainedValue().getVectorLength(reader.takeUnretainedValue().getOffset(myOffset, propertyIndex: 0))
        }
        public func getListElement(atIndex index : Int) -> FooBar.Direct3? {
            let offsetList = reader.takeUnretainedValue().getOffset(myOffset, propertyIndex: 0)
            if let ofs = reader.takeUnretainedValue().getVectorOffsetElement(offsetList, index: index) {
                return FooBar.Direct3(reader: reader.takeUnretainedValue(), myOffset: ofs)
            }
            return nil
        }
        public var initialized : Bool {
            get { return reader.takeUnretainedValue().get(myOffset, propertyIndex: 1, defaultValue: false) }
        }
        public var fruit : Enum? {
            get { return Enum(rawValue: reader.takeUnretainedValue().get(myOffset, propertyIndex: 2, defaultValue: Enum.Apples.rawValue)) }
        }
        public var location : UnsafeBufferPointer<UInt8>? { get { return reader.takeUnretainedValue().getStringBuffer(reader.takeUnretainedValue().getOffset(myOffset, propertyIndex:3)) } }
        public var hashValue: Int { return Int(myOffset) }
    }
}

public func ==(t1 : FooBarContainer.Direct3, t2 : FooBarContainer.Direct3) -> Bool {
    return t1.reader.takeUnretainedValue() === t2.reader.takeUnretainedValue() && t1.myOffset == t2.myOffset
}

extension FooBar {
    public struct Direct3 : Hashable {
        private let reader : Unmanaged<FBMemoryReaderClass>
        private let myOffset : Offset
        init(reader: FBMemoryReaderClass, myOffset: Offset){
            self.reader = Unmanaged.passUnretained(reader)
            self.myOffset = myOffset
        }
        public var sibling : Bar? {
            get { return reader.takeUnretainedValue().get(myOffset, propertyIndex: 0)}
        }
        public var name : UnsafeBufferPointer<UInt8>? { get { return reader.takeUnretainedValue().getStringBuffer(reader.takeUnretainedValue().getOffset(myOffset, propertyIndex:1)) } }
        public var rating : Float64 {
            get { return reader.takeUnretainedValue().get(myOffset, propertyIndex: 2, defaultValue: 0) }
        }
        public var postfix : UInt8 {
            get { return reader.takeUnretainedValue().get(myOffset, propertyIndex: 3, defaultValue: 0) }
        }
        public var hashValue: Int { return Int(myOffset) }
    }
}
public func ==(t1 : FooBar.Direct3, t2 : FooBar.Direct3) -> Bool {
    return t1.reader.takeUnretainedValue() === t2.reader.takeUnretainedValue() && t1.myOffset == t2.myOffset
}*/
