//
//  bench_decode_direct5.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

/*
private func fromByteArray<T : Scalar>(_ buffer : UnsafePointer<UInt8>, _ position : Int) -> T{
    return UnsafePointer<T>(buffer.advancedBy(position)).pointee
}

private func getPropertyOffset(_ buffer : UnsafePointer<UInt8>, _ objectOffset : Offset, propertyIndex : Int)->Int {
    let offset = Int(objectOffset)
    let localOffset : Int32 = fromByteArray(buffer, offset)
    let vTableOffset : Int = offset - Int(localOffset)
    let vTableLength : Int16 = fromByteArray(buffer, vTableOffset)
    if(vTableLength<=Int16(4 + propertyIndex * 2)) {
        return 0
    }
    let propertyStart = vTableOffset + 4 + (2 * propertyIndex)
    
    let propertyOffset : Int16 = fromByteArray(buffer, propertyStart)
    return Int(propertyOffset)
}

private func getOffset(_ buffer : UnsafePointer<UInt8>, _ objectOffset : Offset, propertyIndex : Int) -> Offset?{
    let propertyOffset = getPropertyOffset(buffer, objectOffset, propertyIndex: propertyIndex)
    if propertyOffset == 0 {
        return nil
    }
    let position = objectOffset + propertyOffset
    let localObjectOffset : Int32 = fromByteArray(buffer, Int(position))
    let offset = position + localObjectOffset
    
    if localObjectOffset == 0 {
        return nil
    }
    return offset
}

private func getVectorLength(_ buffer : UnsafePointer<UInt8>, _ vectorOffset : Offset?) -> Int {
    guard let vectorOffset = vectorOffset else {
        return 0
    }
    let vectorPosition = Int(vectorOffset)
    let length2 : Int32 = fromByteArray(buffer, vectorPosition)
    return Int(length2)
}

private func getVectorOffsetElement(_ buffer : UnsafePointer<UInt8>, _ vectorOffset : Offset, index : Int) -> Offset? {
    let valueStartPosition = Int(vectorOffset + MemoryLayout<Int32>.stride + (index * MemoryLayout<Int32>.stride))
    let localOffset : Int32 = fromByteArray(buffer, valueStartPosition)
    if(localOffset == 0){
        return nil
    }
    return localOffset + valueStartPosition
}

private func getVectorScalarElement<T : Scalar>(_ buffer : UnsafePointer<UInt8>, _ vectorOffset : Offset, index : Int) -> T {
    let valueStartPosition = Int(vectorOffset + MemoryLayout<Int32>.stride + (index * MemoryLayout<T>.stride))
    return UnsafePointer<T>(UnsafePointer<UInt8>(buffer).advancedBy(valueStartPosition)).pointee
}

private func get<T : Scalar>(_ buffer : UnsafePointer<UInt8>, _ objectOffset : Offset, propertyIndex : Int, defaultValue : T) -> T{
    let propertyOffset = getPropertyOffset(buffer, objectOffset, propertyIndex: propertyIndex)
    if propertyOffset == 0 {
        return defaultValue
    }
    let position = Int(objectOffset + propertyOffset)
    return fromByteArray(buffer, position)
}

private func get<T : Scalar>(_ buffer : UnsafePointer<UInt8>, _ objectOffset : Offset, propertyIndex : Int) -> T?{
    let propertyOffset = getPropertyOffset(buffer, objectOffset, propertyIndex: propertyIndex)
    if propertyOffset == 0 {
        return nil
    }
    let position = Int(objectOffset + propertyOffset)
    return fromByteArray(buffer, position) as T
}

private func getStringBuffer(_ buffer : UnsafePointer<UInt8>, _ stringOffset : Offset?) -> UnsafeBufferPointer<UInt8>? {
    guard let stringOffset = stringOffset else {
        return nil
    }
    let stringPosition = Int(stringOffset)
    let stringLength : Int32 = fromByteArray(buffer, stringPosition)
    let pointer = UnsafePointer<UInt8>(buffer).advancedBy((stringPosition + strideof(Int32)))
    return UnsafeBufferPointer<UInt8>.init(start: pointer, count: Int(stringLength))
}

private func getString(_ buffer : UnsafePointer<UInt8>, _ stringOffset : Offset?) -> String? {
    guard let stringOffset = stringOffset else {
        return nil
    }
    let stringPosition = Int(stringOffset)
    let stringLength : Int32 = fromByteArray(buffer, stringPosition)
    
    let pointer = UnsafeMutablePointer<UInt8>(mutating: buffer).advanced(by: (stringPosition + MemoryLayout<Int32>.stride))
    let result = String.init(bytesNoCopy: pointer, length: Int(stringLength), encoding: String.Encoding.utf8, freeWhenDone: false)
    
    return result
}


struct FooBarContainerStruct {
    var buffer : UnsafePointer<UInt8>? = nil
    var myOffset : Offset = 0
    
    init(_ data : UnsafePointer<UInt8>) {
        self.buffer = data
        self.myOffset = UnsafePointer<Offset>(buffer.advancedBy(0)).pointee
        self.list = ListStruct(buffer: buffer!, myOffset: myOffset) // set up vector
    }
    
    // table properties
    var list : ListStruct
    var location: UnsafeBufferPointer<UInt8> { get { return getStringBuffer(buffer!, getOffset(buffer!, myOffset, propertyIndex: 3))! } }
    var fruit: Enum {  get { return Enum(rawValue: get(buffer!, myOffset, propertyIndex: 2, defaultValue: Enum.apples.rawValue))! } }
    var initialized: Bool {  get { return get(buffer!, myOffset, propertyIndex: 1, defaultValue: false) } }
    
    // definition of table vector to provice nice subscripting etc
    struct ListStruct {
        var buffer : UnsafePointer<UInt8>? = nil
        var myOffset : Offset = 0
        let offsetList : Offset?
        init(buffer b: UnsafePointer<UInt8>, myOffset o: Offset )
        {
            buffer = b
            myOffset = o
            offsetList = getOffset(buffer!, myOffset, propertyIndex: 0) // cache to make subscript faster
        }
        var count : Int { get { return getVectorLength(buffer!, offsetList) } }
        subscript (index : Int) -> FooBarStruct {
            let ofs = getVectorOffsetElement(buffer!, offsetList!, index: index)!
            return FooBarStruct(buffer: buffer, myOffset: ofs)
        }
    }
}

struct FooBarStruct {
    var buffer : UnsafePointer<UInt8>? = nil
    var myOffset : Offset = 0
    var name: UnsafeBufferPointer<UInt8> { get { return getStringBuffer(buffer!, getOffset(buffer!, myOffset, propertyIndex: 1))! } }
    var rating: Float64 { get { return get(buffer!, myOffset, propertyIndex: 2)! } }
    var postfix: UInt8 {  get { return get(buffer!, myOffset, propertyIndex: 3)! } }
    var sibling: Bar {  get { return get(buffer!, myOffset, propertyIndex: 0)! } }
}*/
