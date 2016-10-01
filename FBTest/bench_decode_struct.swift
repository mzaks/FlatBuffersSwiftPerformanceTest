//
//  bench_decode_direct5.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

struct FooBarContainerStruct {
    var buffer : UnsafePointer<UInt8> = nil
    var myOffset : Offset = 0
    
    init(_ data : UnsafePointer<UInt8>) {
        self.buffer = data
        self.myOffset = UnsafePointer<Offset>(buffer.advancedBy(0)).memory
        self.list = ListStruct(buffer: buffer, myOffset: myOffset) // set up vector
    }
    
    // table properties
    var list : ListStruct
    var location: UnsafeBufferPointer<UInt8> { get { return getStringBuffer(buffer, getOffset(buffer, myOffset, propertyIndex: 3))! } }
    var fruit: Enum {  get { return Enum(rawValue: get(buffer, myOffset, propertyIndex: 2, defaultValue: Enum.Apples.rawValue))! } }
    var initialized: Bool {  get { return get(buffer, myOffset, propertyIndex: 1, defaultValue: false) } }
    
    // definition of table vector to provice nice subscripting etc
    struct ListStruct {
        var buffer : UnsafePointer<UInt8> = nil
        var myOffset : Offset = 0
        let offsetList : Offset?
        init(buffer b: UnsafePointer<UInt8>, myOffset o: Offset )
        {
            buffer = b
            myOffset = o
            offsetList = getOffset(buffer, myOffset, propertyIndex: 0) // cache to make subscript faster
        }
        var count : Int { get { return getVectorLength(buffer, offsetList) } }
        subscript (index : Int) -> FooBarStruct {
            let ofs = getVectorOffsetElement(buffer, offsetList!, index: index)!
            return FooBarStruct(buffer: buffer, myOffset: ofs)
        }
    }
}

struct FooBarStruct {
    var buffer : UnsafePointer<UInt8> = nil
    var myOffset : Offset = 0
    var name: UnsafeBufferPointer<UInt8> { get { return getStringBuffer(buffer, getOffset(buffer, myOffset, propertyIndex: 1))! } }
    var rating: Float64 { get { return get(buffer, myOffset, propertyIndex: 2)! } }
    var postfix: UInt8 {  get { return get(buffer, myOffset, propertyIndex: 3)! } }
    var sibling: Bar {  get { return get(buffer, myOffset, propertyIndex: 0)! } }
}
