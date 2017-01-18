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


enum FBReaderError : Error {
    case OutOfBufferBounds
    case CanNotSetProperty
}

public class FBReaderCache {
    var objectPool : [Offset : AnyObject] = [:]
    func reset(){
        objectPool.removeAll(keepingCapacity: true)
    }
}

public extension FBReader {
    
    private func getPropertyOffset(objectOffset : Offset, propertyIndex : Int) -> Int {
        guard propertyIndex >= 0 else {
            return 0
        }
        do {
            let offset = Int(objectOffset)
            let localOffset : Int32 = try fromByteArray(position: offset)
            let vTableOffset : Int = offset - Int(localOffset)
            let vTableLength : Int16 = try fromByteArray(position: vTableOffset)
            let objectLength : Int16 = try fromByteArray(position: vTableOffset + 2)
            let positionInVTable = 4 + propertyIndex * 2
            if(vTableLength<=Int16(positionInVTable)) {
                return 0
            }
            let propertyStart = vTableOffset + positionInVTable
            let propertyOffset : Int16 = try fromByteArray(position: propertyStart)
            if(objectLength<=propertyOffset) {
                return 0
            }
            return Int(propertyOffset)
        } catch {
            return 0 // Currently don't want to propagate the error
        }
    }
    
    public func getOffset(objectOffset : Offset, propertyIndex : Int) -> Offset? {
        
        let propertyOffset = getPropertyOffset(objectOffset: objectOffset, propertyIndex: propertyIndex)
        if propertyOffset == 0 {
            return nil
        }
        
        let position = objectOffset + propertyOffset
        do {
            let localObjectOffset : Int32 = try fromByteArray(position: Int(position))
            let offset = position + localObjectOffset
            
            if localObjectOffset == 0 {
                return nil
            }
            return offset
        } catch {
            return nil
        }
        
    }
    
    public func getVectorLength(vectorOffset : Offset?) -> Int {
        guard let vectorOffset = vectorOffset else {
            return 0
        }
        let vectorPosition = Int(vectorOffset)
        do {
            let length2 : Int32 = try fromByteArray(position: vectorPosition)
            return Int(length2)
        } catch {
            return 0
        }
    }
    
    public func getVectorOffsetElement(vectorOffset : Offset?, index : Int) -> Offset? {
        guard let vectorOffset = vectorOffset else {
            return nil
        }
        guard index >= 0 else{
            return nil
        }
        guard index < getVectorLength(vectorOffset: vectorOffset) else {
            return nil
        }
        let valueStartPosition = Int(vectorOffset + MemoryLayout<Int32>.stride + (index * MemoryLayout<Int32>.stride))
        do {
            let localOffset : Int32 = try fromByteArray(position: valueStartPosition)
            if(localOffset == 0){
                return nil
            }
            return localOffset + valueStartPosition
        } catch {
            return nil
        }
    }
    
    public func getVectorScalarElement<T : Scalar>(vectorOffset : Offset?, index : Int) -> T? {
        guard let vectorOffset = vectorOffset else {
            return nil
        }
        guard index >= 0 else{
            return nil
        }
        guard index < getVectorLength(vectorOffset: vectorOffset) else {
            return nil
        }
        
        let valueStartPosition = Int(vectorOffset + MemoryLayout<Int32>.stride + (index * MemoryLayout<T>.stride))
        
        do {
            return try fromByteArray(position: valueStartPosition) as T
        } catch {
            return nil
        }
    }
    
    public func get<T : Scalar>(objectOffset : Offset, propertyIndex : Int, defaultValue : T) -> T {
        let propertyOffset = getPropertyOffset(objectOffset: objectOffset, propertyIndex: propertyIndex)
        if propertyOffset == 0 {
            return defaultValue
        }
        let position = Int(objectOffset + propertyOffset)
        do {
            return try fromByteArray(position: position)
        } catch {
            return defaultValue
        }
    }
    
    public func get<T : Scalar>(objectOffset : Offset, propertyIndex : Int) -> T? {
        let propertyOffset = getPropertyOffset(objectOffset: objectOffset, propertyIndex: propertyIndex)
        if propertyOffset == 0 {
            return nil
        }
        let position = Int(objectOffset + propertyOffset)
        do {
            return try fromByteArray(position: position) as T
        } catch {
            return nil
        }
    }
    
    public func getStringBuffer(stringOffset : Offset?) -> UnsafeBufferPointer<UInt8>? {
        guard let stringOffset = stringOffset else {
            return nil
        }
        let stringPosition = Int(stringOffset)
        do {
            let stringLength : Int32 = try fromByteArray(position: stringPosition)
            let stringCharactersPosition = stringPosition + MemoryLayout<Int32>.stride
            
            return try buffer(position: stringCharactersPosition, length: Int(stringLength))
        } catch {
            return nil
        }
    }
    
    public var rootObjectOffset : Offset? {
        do {
            return try fromByteArray(position: 0) as Offset
        } catch {
            return nil
        }
    }
}


public protocol DirectAccess {
    init?<R : FBReader>(reader: R, myOffset: Offset?)
}
struct FBTableVector<T: DirectAccess, R : FBReader> : Sequence {
    fileprivate let reader : R
    fileprivate let myOffset : Offset
    fileprivate init(reader: R, myOffset: Offset){
        self.reader = reader
        self.myOffset = myOffset
    }
    public var count : Int { return reader.getVectorLength(vectorOffset: myOffset) }
    
    public subscript(i : Int) -> T? {
        let offset = reader.getVectorOffsetElement(vectorOffset: myOffset, index: i)
        return T(reader: reader, myOffset: offset)
    }
    
    public func makeIterator() -> AnyIterator<T> {
        var nextIndex = 0
        return AnyIterator<T> {
            if(self.count <= nextIndex){
                return nil
            }
            let value = self[nextIndex]
            nextIndex += 1
            return value
        }
    }
}

struct FBScalarVector<T: Scalar, R : FBReader> : Sequence {
    fileprivate let reader : R
    fileprivate let myOffset : Offset
    fileprivate init(reader: R, myOffset: Offset){
        self.reader = reader
        self.myOffset = myOffset
    }
    public var count : Int { return reader.getVectorLength(vectorOffset: myOffset) }
    
    public subscript(i : Int) -> T? {
        return reader.getVectorScalarElement(vectorOffset: myOffset, index: i)
    }
    
    public func makeIterator() -> AnyIterator<T> {
        var nextIndex = 0
        return AnyIterator<T> {
            if(self.count <= nextIndex){
                return nil
            }
            let value = self[nextIndex]
            nextIndex += 1
            return value
        }
    }
}

public struct FBVector<T> : Sequence {
    private let _generator : (Int)->T?
    private let _count : Int
    init(count : Int, generator : @escaping (Int)->T?) {
        _count = count
        _generator = generator
    }
    
    var count : Int { return _count }
    
    public subscript(i : Int) -> T? {
        return _generator(i)
    }
    
    public func makeIterator() -> AnyIterator<T> {
        var nextIndex = 0
        return AnyIterator<T> {
            if(self.count <= nextIndex){
                return nil
            }
            let value = self._generator(nextIndex)
            nextIndex += 1
            return value
        }
    }
}
