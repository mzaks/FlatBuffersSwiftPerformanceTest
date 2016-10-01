//
//  FBReaderCommon.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

public protocol FBReader {
    func fromByteArray<T : Scalar>(position : Int) throws -> T
    func buffer(position : Int, length : Int) throws -> UnsafeBufferPointer<UInt8>
    var cache : FBReaderCache? {get}
    func isEqual(other : FBReader) -> Bool
}


enum FBReaderError : ErrorType {
    case OutOfBufferBounds
    case CanNotSetProperty
}

public class FBReaderCache {
    var objectPool : [Offset : AnyObject] = [:]
    func reset(){
        objectPool.removeAll(keepCapacity: true)
    }
}

public extension FBReader {
    
    func getPropertyOffset(objectOffset : Offset, propertyIndex : Int) -> Int {
        
        do {
            let offset = Int(objectOffset)
            let localOffset : Int32 = try fromByteArray(offset)
            let vTableOffset : Int = offset - Int(localOffset)
            let vTableLength : Int16 = try fromByteArray(vTableOffset)
            if(vTableLength<=Int16(4 + propertyIndex * 2)) {
                return 0
            }
            let propertyStart = vTableOffset + 4 + (2 * propertyIndex)
            
            let propertyOffset : Int16 = try fromByteArray(propertyStart)
            return Int(propertyOffset)
        } catch {
            return 0 // Currently don't want to propagate the error
        }
    }
    
    func getOffset(objectOffset : Offset, propertyIndex : Int) -> Offset? {
        
        let propertyOffset = getPropertyOffset(objectOffset, propertyIndex: propertyIndex)
        if propertyOffset == 0 {
            return nil
        }
        let position = objectOffset + propertyOffset
        do {
            let localObjectOffset : Int32 = try fromByteArray(Int(position))
            let offset = position + localObjectOffset
            
            if localObjectOffset == 0 {
                return nil
            }
            return offset
        } catch {
            return nil
        }
        
    }
    
    func getVectorLength(vectorOffset : Offset?) -> Int {
        guard let vectorOffset = vectorOffset else {
            return 0
        }
        let vectorPosition = Int(vectorOffset)
        do {
            let length2 : Int32 = try fromByteArray(vectorPosition)
            return Int(length2)
        } catch {
            return 0
        }
    }
    
    func getVectorOffsetElement(vectorOffset : Offset?, index : Int) -> Offset? {
        guard let vectorOffset = vectorOffset else {
            return nil
        }
        guard index >= 0 else{
            return nil
        }
        guard index < getVectorLength(vectorOffset) else {
            return nil
        }
        let valueStartPosition = Int(vectorOffset + strideof(Int32) + (index * strideof(Int32)))
        do {
            let localOffset : Int32 = try fromByteArray(valueStartPosition)
            if(localOffset == 0){
                return nil
            }
            return localOffset + valueStartPosition
        } catch {
            return nil
        }
    }
    
    func getVectorScalarElement<T : Scalar>(vectorOffset : Offset?, index : Int) -> T? {
        guard let vectorOffset = vectorOffset else {
            return nil
        }
        guard index >= 0 else{
            return nil
        }
        guard index < getVectorLength(vectorOffset) else {
            return nil
        }
        
        let valueStartPosition = Int(vectorOffset + strideof(Int32) + (index * strideof(T)))
        
        do {
            return try fromByteArray(valueStartPosition) as T
        } catch {
            return nil
        }
    }
    
    func get<T : Scalar>(objectOffset : Offset, propertyIndex : Int, defaultValue : T) -> T {
        let propertyOffset = getPropertyOffset(objectOffset, propertyIndex: propertyIndex)
        if propertyOffset == 0 {
            return defaultValue
        }
        let position = Int(objectOffset + propertyOffset)
        do {
            return try fromByteArray(position)
        } catch {
            return defaultValue
        }
    }
    
    func get<T : Scalar>(objectOffset : Offset, propertyIndex : Int) -> T? {
        let propertyOffset = getPropertyOffset(objectOffset, propertyIndex: propertyIndex)
        if propertyOffset == 0 {
            return nil
        }
        let position = Int(objectOffset + propertyOffset)
        do {
            return try fromByteArray(position) as T
        } catch {
            return nil
        }
    }
    
    func getStringBuffer(stringOffset : Offset?) -> UnsafeBufferPointer<UInt8>? {
        guard let stringOffset = stringOffset else {
            return nil
        }
        let stringPosition = Int(stringOffset)
        do {
            let stringLength : Int32 = try fromByteArray(stringPosition)
            let stringCharactersPosition = stringPosition + strideof(Int32)
            
            return try buffer(stringCharactersPosition, length: Int(stringLength))
        } catch {
            return nil
        }
    }
    
    var rootObjectOffset : Offset? {
        do {
            return try fromByteArray(0) as Offset
        } catch {
            return nil
        }
    }
}
