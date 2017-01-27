//
//  FBReaderClass.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

public final class FBMemoryReaderClass : FBReader {
    
    private let count : Int
    public let cache : FBReaderCache?
    private let buffer : UnsafeRawPointer
    
    public init(buffer : UnsafeRawPointer, count : Int, cache : FBReaderCache? = FBReaderCache()) {
        self.buffer = buffer
        self.count = count
        self.cache = cache
    }
    
    public init(data : Data, cache : FBReaderCache? = FBReaderCache()) {
        self.count = data.count
        self.cache = cache
        var pointer : UnsafePointer<UInt8>! = nil
        data.withUnsafeBytes { (u8Ptr: UnsafePointer<UInt8>) in
            pointer = u8Ptr
        }
        self.buffer = UnsafeRawPointer(pointer)
    }
    
    public func fromByteArray<T : Scalar>(position : Int) throws -> T {
        if position + MemoryLayout<T>.stride >= count || position < 0 {
            throw FBReaderError.OutOfBufferBounds
        }
        guard 0 == (UInt(bitPattern: buffer + position)
            & (UInt(MemoryLayout<T>.alignment) - 1)) else {
                throw FBReaderError.DataNotAligned
        }
        
        return buffer.advanced(by: position).assumingMemoryBound(to: T.self).pointee
    }
    
    public func buffer(position : Int, length : Int) throws -> UnsafeBufferPointer<UInt8> {
        if Int(position + length) > count {
            throw FBReaderError.OutOfBufferBounds
        }
        let pointer = buffer.advanced(by:position).bindMemory(to: UInt8.self, capacity: length)
        return UnsafeBufferPointer<UInt8>.init(start: pointer, count: Int(length))
    }
    
    public func isEqual(other: FBReader) -> Bool{
        guard let other = other as? FBMemoryReaderClass else {
            return false
        }
        return self.buffer == other.buffer
    }
}

public final class FBFileReaderClass : FBReader {
    
    private let fileSize : UInt64
    private let fileHandle : FileHandle
    public let cache : FBReaderCache?
    
    public init(fileHandle : FileHandle, cache : FBReaderCache? = FBReaderCache()){
        self.fileHandle = fileHandle
        fileSize = fileHandle.seekToEndOfFile()
        
        self.cache = cache
    }
    
    public func fromByteArray<T : Scalar>(position : Int) throws -> T {
        let seekPosition = UInt64(position)
        if seekPosition + UInt64(MemoryLayout<T>.stride) >= fileSize {
            throw FBReaderError.OutOfBufferBounds
        }
        fileHandle.seek(toFileOffset: seekPosition)
        let data = fileHandle.readData(ofLength:MemoryLayout<T>.stride)
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: MemoryLayout<T>.stride)
        let t : UnsafeMutableBufferPointer<T> = UnsafeMutableBufferPointer(start: pointer, count: 1)
        _ = data.copyBytes(to: t)
        if let result = t.baseAddress?.pointee {
            pointer.deinitialize()
            return result
        }
        throw FBReaderError.OutOfBufferBounds
    }
    
    public func buffer(position : Int, length : Int) throws -> UnsafeBufferPointer<UInt8> {
        if UInt64(position + length) > fileSize {
            throw FBReaderError.OutOfBufferBounds
        }
        fileHandle.seek(toFileOffset: UInt64(position))
        let data = fileHandle.readData(ofLength:Int(length))
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        let t : UnsafeMutableBufferPointer<UInt8> = UnsafeMutableBufferPointer(start: pointer, count: length)
        _ = data.copyBytes(to: t)
        pointer.deinitialize()
        return UnsafeBufferPointer<UInt8>(start: t.baseAddress, count: length)
    }
    
    public func isEqual(other: FBReader) -> Bool{
        guard let other = other as? FBFileReaderClass else {
            return false
        }
        return self.fileHandle === other.fileHandle
    }
}
