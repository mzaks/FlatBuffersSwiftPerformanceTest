//
//  FBReaderClass.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

public final class FBMemoryReaderClass : FBReader {
    
    public var count : Int
    public let cache : FBReaderCache?
    public var buffer : UnsafePointer<UInt8>
    
    init(buffer : UnsafePointer<UInt8>, count : Int, cache : FBReaderCache? = FBReaderCache()) {
        self.buffer = buffer
        self.count = count
        self.cache = cache
    }
    
    public func fromByteArray<T : Scalar>(position : Int) throws -> T {
        if position + strideof(T) >= count || position < 0 {
            throw FBReaderError.OutOfBufferBounds
        }
        return UnsafePointer<T>(buffer.advancedBy(position)).memory
    }
    
    public func buffer(position : Int, length : Int) throws -> UnsafeBufferPointer<UInt8> {
        if Int(position + length) > count {
            throw FBReaderError.OutOfBufferBounds
        }
        let pointer = UnsafePointer<UInt8>(buffer).advancedBy(position)
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
    private let fileHandle : NSFileHandle
    public let cache : FBReaderCache?
    
    init(fileHandle : NSFileHandle, cache : FBReaderCache? = FBReaderCache()){
        self.fileHandle = fileHandle
        fileSize = fileHandle.seekToEndOfFile()
        
        self.cache = cache
    }
    
    public func fromByteArray<T : Scalar>(position : Int) throws -> T {
        let seekPosition = UInt64(position)
        if seekPosition + UInt64(strideof(T)) >= fileSize {
            throw FBReaderError.OutOfBufferBounds
        }
        fileHandle.seekToFileOffset(seekPosition)
        return UnsafePointer<T>(fileHandle.readDataOfLength(strideof(T)).bytes).memory
    }
    
    public func buffer(position : Int, length : Int) throws -> UnsafeBufferPointer<UInt8> {
        if UInt64(position + length) >= fileSize {
            throw FBReaderError.OutOfBufferBounds
        }
        fileHandle.seekToFileOffset(UInt64(position))
        let pointer = UnsafeMutablePointer<UInt8>(fileHandle.readDataOfLength(Int(length)).bytes)
        return UnsafeBufferPointer<UInt8>.init(start: pointer, count: Int(length))
    }
    
    public func isEqual(other: FBReader) -> Bool{
        guard let other = other as? FBFileReaderClass else {
            return false
        }
        return self.fileHandle === other.fileHandle
    }
}
