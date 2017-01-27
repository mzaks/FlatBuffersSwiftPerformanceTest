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
    case DataNotAligned
    case CanNotSetProperty
}

public class FBReaderCache {
    var objectPool : [Offset : AnyObject] = [:]
    func reset(){
        objectPool.removeAll(keepingCapacity: true)
    }
}

public extension FBReader {
    
    
    public func vTableData(objectOffset : Offset) throws -> (localOffset: Int32, vTableLength : Int16, objectLength: Int16) {
        
        let localOffset : Int32 = try fromByteArray(position: Int(objectOffset))
        let vTableOffset : Int = Int(objectOffset - localOffset)
        let vTableLength : Int16 = try fromByteArray(position: vTableOffset)
        let objectLength : Int16 = try fromByteArray(position: vTableOffset + 2)
        
        return (localOffset, vTableLength, objectLength)
    }
    
    private func getPropertyOffset(objectOffset : Offset, propertyIndex : Int16, localOffset: Int32, vTableLength : Int16, objectLength: Int16) throws -> Int16 {
        guard propertyIndex >= 0 else {
            return 0
        }
        
            let vTableOffset = objectOffset - localOffset

            let positionInVTable = 4 + propertyIndex * 2
            if(vTableLength<=positionInVTable) {
                return 0
            }
            let propertyStart = Int(vTableOffset) + Int(positionInVTable)
            let propertyOffset : Int16 = try fromByteArray(position: propertyStart)
            if(objectLength <= propertyOffset) {
                return 0
            }
            return propertyOffset
        
    }
    
    public func getOffset(objectOffset : Offset, propertyIndex : Int16, localOffset: Int32, vTableLength : Int16, objectLength: Int16) -> Offset? {
        
        do {
            let propertyOffset = try getPropertyOffset(objectOffset: objectOffset, propertyIndex: propertyIndex, localOffset: localOffset, vTableLength : vTableLength, objectLength: objectLength)
            if propertyOffset == 0 {
                return nil
            }
            
            let position = Int(objectOffset) + Int(propertyOffset)
            
            let localObjectOffset : Offset = try fromByteArray(position: Int(position))
            let offset = position + localObjectOffset
            
            if localObjectOffset == 0 {
                return nil
            }
            return offset
        } catch {
            return nil
        }
        
    }
    
    public func get<T : Scalar>(objectOffset : Offset, propertyIndex : Int16, localOffset: Int32, vTableLength : Int16, objectLength: Int16) -> T? {
        do {
            let propertyOffset = try getPropertyOffset(objectOffset: objectOffset, propertyIndex: propertyIndex, localOffset: localOffset, vTableLength : vTableLength, objectLength: objectLength)
            if propertyOffset == 0 {
                return nil
            }
            let position = Int(objectOffset) + Int(propertyOffset)
            return try fromByteArray(position: position) as T
        } catch {
            return nil
        }
    }
    
    ///MARK: -
    
    
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
struct FBTableVector<T: DirectAccess, R : FBReader> : Collection {
    public let count : Int

    fileprivate let reader : R
    fileprivate let myOffset : Offset

    public init(reader: R, myOffset: Offset){
        self.reader = reader
        self.myOffset = myOffset
        self.count = reader.getVectorLength(vectorOffset: myOffset)
    }

    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return count
    }

    public func index(after i: Int) -> Int {
        return i+1
    }

    public subscript(i : Int) -> T? {
        let offset = reader.getVectorOffsetElement(vectorOffset: myOffset, index: i)
        return T(reader: reader, myOffset: offset)
    }
}

struct FBScalarVector<T: Scalar, R : FBReader> : Collection {
    public let count : Int

    fileprivate let reader : R
    fileprivate let myOffset : Offset
    fileprivate init(reader: R, myOffset: Offset){
        self.reader = reader
        self.myOffset = myOffset
        self.count = reader.getVectorLength(vectorOffset: myOffset)
    }

    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return count
    }
    
    public func index(after i: Int) -> Int {
        return i+1
    }

    public subscript(i : Int) -> T? {
        return reader.getVectorScalarElement(vectorOffset: myOffset, index: i)
    }
}

public struct FBVector<T: DirectAccess, R : FBReader> : Collection {
    public let count : Int
    
    fileprivate let reader : R
    fileprivate let myOffset : Offset
    
    public init(count c: Int, reader: R, myOffset: Offset){
        self.reader = reader
        self.myOffset = myOffset
        self.count = c
    }

    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return count
    }
    
    public func index(after i: Int) -> Int {
        return i+1
    }
    
    public subscript(i : Int) -> T? {
        if let offset = reader.getVectorOffsetElement(vectorOffset: myOffset, index: i) {
            return T(reader: reader, myOffset: offset)
        }
        return nil
    }
}
