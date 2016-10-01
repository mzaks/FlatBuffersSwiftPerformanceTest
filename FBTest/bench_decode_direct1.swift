//
//  bench_decode_direct1.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

extension FooBarContainer {
    public struct Direct1 : Hashable {
        private let reader : FBReader
        private let myOffset : Offset
        init(reader: FBReader, myOffset: Offset){
            self.reader = reader
            self.myOffset = myOffset
        }
        public init?(_ reader: FBReader) {
            self.reader = reader
            guard let offest = reader.rootObjectOffset else {
                return nil
            }
            self.myOffset = offest
        }
        public var listCount : Int {
            return reader.getVectorLength(reader.getOffset(myOffset, propertyIndex: 0))
        }
        public func getListElement(atIndex index : Int) -> FooBar.Direct1? {
            let offsetList = reader.getOffset(myOffset, propertyIndex: 0)
            if let ofs = reader.getVectorOffsetElement(offsetList, index: index) {
                return FooBar.Direct1(reader: reader, myOffset: ofs)
            }
            return nil
        }
        public var initialized : Bool {
            get { return reader.get(myOffset, propertyIndex: 1, defaultValue: false) }
        }
        public var fruit : Enum? {
            get { return Enum(rawValue: reader.get(myOffset, propertyIndex: 2, defaultValue: Enum.Apples.rawValue)) }
        }
        public var location : UnsafeBufferPointer<UInt8>? { get { return reader.getStringBuffer(reader.getOffset(myOffset, propertyIndex:3)) } }
        public var hashValue: Int { return Int(myOffset) }
    }
}

public func ==(t1 : FooBarContainer.Direct1, t2 : FooBarContainer.Direct1) -> Bool {
    return t1.reader.isEqual(t2.reader) && t1.myOffset == t2.myOffset
}

extension FooBar {
    public struct Direct1 : Hashable {
        private let reader : FBReader
        private let myOffset : Offset
        init(reader: FBReader, myOffset: Offset){
            self.reader = reader
            self.myOffset = myOffset
        }
        public var sibling : Bar? {
            get { return reader.get(myOffset, propertyIndex: 0)}
        }
        public var name : UnsafeBufferPointer<UInt8>? { get { return reader.getStringBuffer(reader.getOffset(myOffset, propertyIndex:1)) } }
        public var rating : Float64 {
            get { return reader.get(myOffset, propertyIndex: 2, defaultValue: 0) }
        }
        public var postfix : UInt8 {
            get { return reader.get(myOffset, propertyIndex: 3, defaultValue: 0) }
        }
        public var hashValue: Int { return Int(myOffset) }
    }
}
public func ==(t1 : FooBar.Direct1, t2 : FooBar.Direct1) -> Bool {
    return t1.reader.isEqual(t2.reader) && t1.myOffset == t2.myOffset
}

