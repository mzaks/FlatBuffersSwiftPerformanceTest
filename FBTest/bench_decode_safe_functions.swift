//
//  bench_decode_functions2.swift
//  FBTest
//
//  Created by Maxim Zaks on 02.10.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

public func fromByteArray<T : Scalar>(position : Int, buffer : UnsafePointer<UInt8>, count : Int) throws -> T {
    if position + strideof(T) >= count || position < 0 {
        throw FBReaderError.OutOfBufferBounds
    }
    return UnsafePointer<T>(buffer.advancedBy(position)).memory
}

public func getBuffer(position : Int, length : Int, buffer : UnsafePointer<UInt8>, count : Int) throws -> UnsafeBufferPointer<UInt8> {
    if Int(position + length) > count {
        throw FBReaderError.OutOfBufferBounds
    }
    let pointer = UnsafePointer<UInt8>(buffer).advancedBy(position)
    return UnsafeBufferPointer<UInt8>.init(start: pointer, count: Int(length))
}

func getPropertyOffset(objectOffset : Offset, propertyIndex : Int, buffer : UnsafePointer<UInt8>, count : Int) -> Int {
    
    do {
        let offset = Int(objectOffset)
        let localOffset : Int32 = try fromByteArray(offset, buffer: buffer, count: count)
        let vTableOffset : Int = offset - Int(localOffset)
        let vTableLength : Int16 = try fromByteArray(vTableOffset, buffer: buffer, count: count)
        if(vTableLength<=Int16(4 + propertyIndex * 2)) {
            return 0
        }
        let propertyStart = vTableOffset + 4 + (2 * propertyIndex)
        
        let propertyOffset : Int16 = try fromByteArray(propertyStart, buffer: buffer, count: count)
        return Int(propertyOffset)
    } catch {
        return 0 // Currently don't want to propagate the error
    }
}

func getOffset(objectOffset : Offset, propertyIndex : Int, buffer : UnsafePointer<UInt8>, count : Int) -> Offset? {
    
    let propertyOffset = getPropertyOffset(objectOffset, propertyIndex: propertyIndex, buffer: buffer, count: count)
    if propertyOffset == 0 {
        return nil
    }
    let position = objectOffset + propertyOffset
    do {
        let localObjectOffset : Int32 = try fromByteArray(Int(position), buffer: buffer, count: count)
        let offset = position + localObjectOffset
        
        if localObjectOffset == 0 {
            return nil
        }
        return offset
    } catch {
        return nil
    }
    
}

func getVectorLength(vectorOffset : Offset?, buffer : UnsafePointer<UInt8>, count : Int) -> Int {
    guard let vectorOffset = vectorOffset else {
        return 0
    }
    let vectorPosition = Int(vectorOffset)
    do {
        let length2 : Int32 = try fromByteArray(vectorPosition, buffer: buffer, count: count)
        return Int(length2)
    } catch {
        return 0
    }
}

func getVectorOffsetElement(vectorOffset : Offset?, index : Int, buffer : UnsafePointer<UInt8>, count : Int) -> Offset? {
    guard let vectorOffset = vectorOffset else {
        return nil
    }
    guard index >= 0 else{
        return nil
    }
    guard index < getVectorLength(vectorOffset, buffer: buffer, count: count) else {
        return nil
    }
    let valueStartPosition = Int(vectorOffset + strideof(Int32) + (index * strideof(Int32)))
    do {
        let localOffset : Int32 = try fromByteArray(valueStartPosition, buffer: buffer, count: count)
        if(localOffset == 0){
            return nil
        }
        return localOffset + valueStartPosition
    } catch {
        return nil
    }
}

func getVectorScalarElement<T : Scalar>(vectorOffset : Offset?, index : Int, buffer : UnsafePointer<UInt8>, count : Int) -> T? {
    guard let vectorOffset = vectorOffset else {
        return nil
    }
    guard index >= 0 else{
        return nil
    }
    guard index < getVectorLength(vectorOffset, buffer: buffer, count: count) else {
        return nil
    }
    
    let valueStartPosition = Int(vectorOffset + strideof(Int32) + (index * strideof(T)))
    
    do {
        return try fromByteArray(valueStartPosition, buffer: buffer, count: count) as T
    } catch {
        return nil
    }
}

func get<T : Scalar>(objectOffset : Offset, propertyIndex : Int, defaultValue : T, buffer : UnsafePointer<UInt8>, count : Int) -> T {
    let propertyOffset = getPropertyOffset(objectOffset, propertyIndex: propertyIndex, buffer: buffer, count: count)
    if propertyOffset == 0 {
        return defaultValue
    }
    let position = Int(objectOffset + propertyOffset)
    do {
        return try fromByteArray(position, buffer: buffer, count: count)
    } catch {
        return defaultValue
    }
}

func get<T : Scalar>(objectOffset : Offset, propertyIndex : Int, buffer : UnsafePointer<UInt8>, count : Int) -> T? {
    let propertyOffset = getPropertyOffset(objectOffset, propertyIndex: propertyIndex, buffer: buffer, count: count)
    if propertyOffset == 0 {
        return nil
    }
    let position = Int(objectOffset + propertyOffset)
    do {
        return try fromByteArray(position, buffer: buffer, count: count) as T
    } catch {
        return nil
    }
}

func getStringBuffer(stringOffset : Offset?, buffer : UnsafePointer<UInt8>, count : Int) -> UnsafeBufferPointer<UInt8>? {
    guard let stringOffset = stringOffset else {
        return nil
    }
    let stringPosition = Int(stringOffset)
    do {
        let stringLength : Int32 = try fromByteArray(stringPosition, buffer: buffer, count: count)
        let stringCharactersPosition = stringPosition + strideof(Int32)
        
        return try getBuffer(stringCharactersPosition, length: Int(stringLength), buffer: buffer, count: count)
    } catch {
        return nil
    }
}




func getFooBarContainerRootOffset(buffer : UnsafePointer<UInt8>) -> Offset {
    return UnsafePointer<Offset>(buffer.advancedBy(0)).memory
}

func getListCountFrom(buffer : UnsafePointer<UInt8>, fooBarContainerOffset : Offset, count : Int) -> Int {
    let offset_list : Offset? = getOffset(fooBarContainerOffset, propertyIndex: 0, buffer: buffer, count: count)
    return getVectorLength(offset_list, buffer: buffer, count: count)
}

func getFooBarOffsetFrom(buffer : UnsafePointer<UInt8>, fooBarContainerOffset : Offset, listIndex : Int, count : Int) -> Offset {
    let offset_list : Offset? = getOffset(fooBarContainerOffset, propertyIndex: 0, buffer: buffer, count: count)
    return getVectorOffsetElement(offset_list!, index: listIndex, buffer: buffer, count: count)!
}

func getInitializedFrom(buffer : UnsafePointer<UInt8>, fooBarContainerOffset : Offset, count : Int) -> Bool {
    return get(fooBarContainerOffset, propertyIndex: 1, defaultValue: false, buffer: buffer, count: count)
}
func getFrootFrom(buffer : UnsafePointer<UInt8>, fooBarContainerOffset : Offset, count : Int) -> Enum {
    return Enum(rawValue: get(fooBarContainerOffset, propertyIndex: 2, defaultValue: Enum.Apples.rawValue, buffer : buffer, count: count))!
}
func getLocationFrom(buffer : UnsafePointer<UInt8>, fooBarContainerOffset : Offset, count : Int) -> UnsafeBufferPointer<UInt8> {
    return getStringBuffer(getOffset(fooBarContainerOffset, propertyIndex: 3, buffer: buffer, count: count), buffer: buffer, count : count)!
}

func getSiblingFrom(buffer : UnsafePointer<UInt8>, fooBarOffset : Offset, count : Int) -> Bar {
    let result : Bar = get(fooBarOffset, propertyIndex: 0, buffer: buffer, count: count)!
    return result
}
func getNameFrom(buffer : UnsafePointer<UInt8>, fooBarOffset : Offset, count : Int) -> UnsafeBufferPointer<UInt8> {
    return getStringBuffer(getOffset(fooBarOffset, propertyIndex: 1, buffer: buffer, count: count), buffer: buffer, count: count)!
}
func getRatingFrom(buffer : UnsafePointer<UInt8>, fooBarOffset : Offset, count : Int) -> Float64 {
    let result : Float64 = get(fooBarOffset, propertyIndex: 2, buffer: buffer, count: count)!
    return result
}
func getPostfixFrom(buffer : UnsafePointer<UInt8>, fooBarOffset : Offset, count : Int) -> UInt8 {
    let result : UInt8 = get(fooBarOffset, propertyIndex: 3, buffer: buffer, count: count)!
    return result
}
