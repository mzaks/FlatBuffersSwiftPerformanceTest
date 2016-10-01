//
//  main.swift
//  FBTest
//
//  Created by Maxim Zaks on 23.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation


//
//  flatbench.swift
//  FlatBuffersSwift
//
//  Created by Joakim Hassila on 2016-04-27.
//
//  Reimplementation of parts of the Flatbuffers C++ Benchmark in Swift
//  to get somewhat comparable performance numbers for both eager and lazy variants
//  based on the implementation from https://github.com/google/flatbuffers/tree/benchmarks/benchmarks/cpp

import Foundation

private let iterations : Int = 1000
private let inner_loop_iterations : Int = 1000
private let bufsize = 2048 * 2
private var encodedsize = 0


private func createContainer() -> FooBarContainer
{
    let veclen = 3
    var foobars = ContiguousArray<FooBar?>.init(count: veclen, repeatedValue:nil)
    
    for i in 0..<veclen { // 0xABADCAFEABADCAFE will overflow in usage
        let ident : UInt64 = 0xABADCAFE + UInt64(i)
        let foo = Foo(id: ident, count: 10000 + i, prefix: 64 + i, length: UInt32(1000000 + i))
        let bar = Bar(parent: foo, time: 123456 + i, ratio: 3.14159 + Float(i), size: UInt16(10000 + i))
        let name = "Hello, World!"
        let foobar = FooBar(sibling: bar, name: name, rating: 3.1415432432445543543+Double(i), postfix: UInt8(33 + i))
        foobars[i] = foobar
    }
    
    let location = "http://google.com/flatbuffers/"
    let foobarcontainer = FooBarContainer(list: foobars, initialized: true, fruit: Enum.Bananas, location: location)
    
    return foobarcontainer
}

var reader_struct : FBMemoryReaderStruct!
private func decode_eager_struct(buffer : UnsafeBufferPointer<UInt8>) -> FooBarContainer
{
    //if reader_struct == nil {
        reader_struct = FBMemoryReaderStruct(buffer: buffer.baseAddress, count: buffer.count, cache: nil)
    //}
    return FooBarContainer.fromReader(reader_struct)!
}

var reader_class : FBMemoryReaderClass!
private func decode_eager_class(buffer : UnsafeBufferPointer<UInt8>) -> FooBarContainer
{
    if reader_class == nil {
        reader_class = FBMemoryReaderClass(buffer: buffer.baseAddress, count: buffer.count, cache: nil)
    } else {
        reader_class.buffer = buffer.baseAddress
        reader_class.count = buffer.count
    }
    
    return FooBarContainer.fromReader(reader_class)!
}

private func flatuse(foobarcontainer : FooBarContainer, start : Int) -> Int
{
    var sum:Int = Int(start)
    sum = sum &+ Int(foobarcontainer.location!.utf8.count)
    sum = sum &+ Int(foobarcontainer.fruit!.rawValue)
    sum = sum &+ (foobarcontainer.initialized ? 1 : 0)
    
    for i in 0..<foobarcontainer.list.count {
        let foobar = foobarcontainer.list[i]!
        sum = sum &+ Int(foobar.name!.utf8.count)
        sum = sum &+ Int(foobar.postfix)
        sum = sum &+ Int(foobar.rating)
        
        let bar = foobar.sibling!
        
        sum = sum &+ Int(bar.ratio)
        sum = sum &+ Int(bar.size)
        sum = sum &+ Int(bar.time)
        
        let foo = bar.parent
        sum = sum &+ Int(foo.count)
        sum = sum &+ Int(foo.id)
        sum = sum &+ Int(foo.length)
        sum = sum &+ Int(foo.prefix)
    }
    return sum
}

private func decode_direct1(buffer : UnsafePointer<UInt8>, count : Int, start : Int, withStruct : Bool) -> Int
{
    let reader : FBReader
    if withStruct {
        reader = FBMemoryReaderStruct(buffer: buffer, count: count, cache: nil)
    } else {
        reader = FBMemoryReaderClass(buffer: buffer, count: count, cache: nil)
    }
    var sum:Int = Int(start)
    let foobarcontainer = FooBarContainer.Direct1(reader)!
    sum = sum &+ Int(foobarcontainer.location!.count)
    sum = sum &+ Int(foobarcontainer.fruit!.rawValue)
    sum = sum &+ (foobarcontainer.initialized ? 1 : 0)
    
    for i in 0..<foobarcontainer.listCount {
        let foobar = foobarcontainer.getListElement(atIndex: i)!
        sum = sum &+ Int(foobar.name!.count)
        sum = sum &+ Int(foobar.postfix)
        sum = sum &+ Int(foobar.rating)
        
        let bar = foobar.sibling!
        
        sum = sum &+ Int(bar.ratio)
        sum = sum &+ Int(bar.size)
        sum = sum &+ Int(bar.time)
        
        let foo = bar.parent
        sum = sum &+ Int(foo.count)
        sum = sum &+ Int(foo.id)
        sum = sum &+ Int(foo.length)
        sum = sum &+ Int(foo.prefix)
    }
    return sum
}

private func decode_direct2(buffer : UnsafePointer<UInt8>, count : Int, start : Int) -> Int
{
    let reader = FBMemoryReaderStruct(buffer: buffer, count: count, cache: nil)
    
    var sum:Int = Int(start)
    let foobarcontainer = FooBarContainer.Direct2(reader)!
    sum = sum &+ Int(foobarcontainer.location!.count)
    sum = sum &+ Int(foobarcontainer.fruit!.rawValue)
    sum = sum &+ (foobarcontainer.initialized ? 1 : 0)
    
    for i in 0..<foobarcontainer.listCount {
        let foobar = foobarcontainer.getListElement(atIndex: i)!
        sum = sum &+ Int(foobar.name!.count)
        sum = sum &+ Int(foobar.postfix)
        sum = sum &+ Int(foobar.rating)
        
        let bar = foobar.sibling!
        
        sum = sum &+ Int(bar.ratio)
        sum = sum &+ Int(bar.size)
        sum = sum &+ Int(bar.time)
        
        let foo = bar.parent
        sum = sum &+ Int(foo.count)
        sum = sum &+ Int(foo.id)
        sum = sum &+ Int(foo.length)
        sum = sum &+ Int(foo.prefix)
    }
    return sum
}

private func decode_direct3(start : Int) -> Int
{
    var sum:Int = Int(start)
    let foobarcontainer = FooBarContainer.Direct3(reader_class)!
    sum = sum &+ Int(foobarcontainer.location!.count)
    sum = sum &+ Int(foobarcontainer.fruit!.rawValue)
    sum = sum &+ (foobarcontainer.initialized ? 1 : 0)
    
    for i in 0..<foobarcontainer.listCount {
        let foobar = foobarcontainer.getListElement(atIndex: i)!
        sum = sum &+ Int(foobar.name!.count)
        sum = sum &+ Int(foobar.postfix)
        sum = sum &+ Int(foobar.rating)
        
        let bar = foobar.sibling!
        
        sum = sum &+ Int(bar.ratio)
        sum = sum &+ Int(bar.size)
        sum = sum &+ Int(bar.time)
        
        let foo = bar.parent
        sum = sum &+ Int(foo.count)
        sum = sum &+ Int(foo.id)
        sum = sum &+ Int(foo.length)
        sum = sum &+ Int(foo.prefix)
    }
    return sum
}

//private func decode_direct4_struct(start : Int) -> Int
private func decode_direct4_struct(buffer : UnsafePointer<UInt8>, count : Int, start : Int) -> Int
{
    var sum:Int = Int(start)
    let reader = FBMemoryReaderStruct(buffer: buffer, count: count, cache: nil)
    let foobarcontainer = FooBarContainerDirect(reader)!
    
    sum = sum &+ Int(foobarcontainer.location!.count)
    sum = sum &+ Int(foobarcontainer.fruit!.rawValue)
    sum = sum &+ (foobarcontainer.initialized ? 1 : 0)
    
    for i in 0..<foobarcontainer.listCount {
        let foobar = foobarcontainer.getListElement(atIndex: i)!
        sum = sum &+ Int(foobar.name!.count)
        sum = sum &+ Int(foobar.postfix)
        sum = sum &+ Int(foobar.rating)
        
        let bar = foobar.sibling!
        
        sum = sum &+ Int(bar.ratio)
        sum = sum &+ Int(bar.size)
        sum = sum &+ Int(bar.time)
        
        let foo = bar.parent
        sum = sum &+ Int(foo.count)
        sum = sum &+ Int(foo.id)
        sum = sum &+ Int(foo.length)
        sum = sum &+ Int(foo.prefix)
    }
    return sum
}

private func decode_direct4_class(start : Int) -> Int
{
    var sum:Int = Int(start)
    let foobarcontainer = FooBarContainerDirect(reader_class)!
    
    sum = sum &+ Int(foobarcontainer.location!.count)
    sum = sum &+ Int(foobarcontainer.fruit!.rawValue)
    sum = sum &+ (foobarcontainer.initialized ? 1 : 0)
    
    for i in 0..<foobarcontainer.listCount {
        let foobar = foobarcontainer.getListElement(atIndex: i)!
        sum = sum &+ Int(foobar.name!.count)
        sum = sum &+ Int(foobar.postfix)
        sum = sum &+ Int(foobar.rating)
        
        let bar = foobar.sibling!
        
        sum = sum &+ Int(bar.ratio)
        sum = sum &+ Int(bar.size)
        sum = sum &+ Int(bar.time)
        
        let foo = bar.parent
        sum = sum &+ Int(foo.count)
        sum = sum &+ Int(foo.id)
        sum = sum &+ Int(foo.length)
        sum = sum &+ Int(foo.prefix)
    }
    return sum
}

private func decode_from_file(reader : FBFileReaderStruct, start : Int) -> Int
{
    var sum:Int = Int(start)
    let foobarcontainer = FooBarContainerDirect(reader)!
    
    sum = sum &+ Int(foobarcontainer.location!.count)
    sum = sum &+ Int(foobarcontainer.fruit!.rawValue)
    sum = sum &+ (foobarcontainer.initialized ? 1 : 0)
    
    for i in 0..<foobarcontainer.listCount {
        let foobar = foobarcontainer.getListElement(atIndex: i)!
        sum = sum &+ Int(foobar.name!.count)
        sum = sum &+ Int(foobar.postfix)
        sum = sum &+ Int(foobar.rating)
        
        let bar = foobar.sibling!
        
        sum = sum &+ Int(bar.ratio)
        sum = sum &+ Int(bar.size)
        sum = sum &+ Int(bar.time)
        
        let foo = bar.parent
        sum = sum &+ Int(foo.count)
        sum = sum &+ Int(foo.id)
        sum = sum &+ Int(foo.length)
        sum = sum &+ Int(foo.prefix)
    }
    return sum
}



private func functionalDecode(buffer : UnsafePointer<UInt8>, start : Int) -> Int{
    
    let fooBarContainerOffset = getFooBarContainerRootOffset(buffer)
    
    var sum:Int = start
    
    sum = sum &+ Int(getLocationFrom(buffer, fooBarContainerOffset: fooBarContainerOffset).count)
    
    sum = sum &+ Int(getFrootFrom(buffer, fooBarContainerOffset: fooBarContainerOffset).rawValue)
    sum = sum &+ (getInitializedFrom(buffer, fooBarContainerOffset: fooBarContainerOffset) ? 1 : 0)
    
    for i in 0..<getListCountFrom(buffer, fooBarContainerOffset: fooBarContainerOffset) {
        let foobarOffset = getFooBarOffsetFrom(buffer, fooBarContainerOffset: fooBarContainerOffset, listIndex: i)
        sum = sum &+ Int(getNameFrom(buffer, fooBarOffset: foobarOffset).count)
        sum = sum &+ Int(getPostfixFrom(buffer, fooBarOffset: foobarOffset))
        sum = sum &+ Int(getRatingFrom(buffer, fooBarOffset: foobarOffset))
        
        let bar = getSiblingFrom(buffer, fooBarOffset: foobarOffset)
        
        sum = sum &+ Int(bar.ratio)
        sum = sum &+ Int(bar.size)
        sum = sum &+ Int(bar.time)
        
        let foo = bar.parent
        sum = sum &+ Int(foo.count)
        sum = sum &+ Int(foo.id)
        sum = sum &+ Int(foo.length)
        sum = sum &+ Int(foo.prefix)
    }
    
    return sum
}

private func decode_struct(buffer : UnsafePointer<UInt8>, start : Int) -> Int
{
    var sum:Int = Int(start)
    let foobarcontainer = FooBarContainerStruct(buffer)
    
    sum = sum &+ Int(foobarcontainer.location.count)
    sum = sum &+ Int(foobarcontainer.fruit.rawValue)
    sum = sum &+ (foobarcontainer.initialized ? 1 : 0)
    
    for i in 0..<foobarcontainer.list.count {
        let foobar = foobarcontainer.list[i]
        sum = sum &+ Int(foobar.name.count)
        sum = sum &+ Int(foobar.postfix)
        sum = sum &+ Int(foobar.rating)
        
        let bar = foobar.sibling
        
        sum = sum &+ Int(bar.ratio)
        sum = sum &+ Int(bar.size)
        sum = sum &+ Int(bar.time)
        
        let foo = bar.parent
        sum = sum &+ Int(foo.count)
        sum = sum &+ Int(foo.id)
        sum = sum &+ Int(foo.length)
        sum = sum &+ Int(foo.prefix)
    }
    return sum
}


// convenience formatter
extension Double {
    func string(fractionDigits:Int) -> String {
        let formatter = NSNumberFormatter()
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumIntegerDigits = 1
        return formatter.stringFromNumber(self) ?? "\(self)"
    }
}

enum BenchmarkRunType {
    case decode_eager_class
    case decode_eager_struct
    case decode_direct1_class
    case decode_direct1_struct
    case decode_direct2
    case decode_direct3
    case decode_direct4_class
    case decode_direct4_struct
    case decode_functions
    case decode_struct
    case decode_from_file
}

private func runbench(runType: BenchmarkRunType) -> (Int, Int)
{
    var encode = 0.0
    var decode = 0.0
    var use = 0.0
    var total:UInt64 = 0
    var results : ContiguousArray<FooBarContainer> = []
    let builder = FlatBufferBuilder(config: BinaryBuildConfig(initialCapacity: bufsize, uniqueStrings: false, uniqueTables: false, uniqueVTables: false, forceDefaults: false, fullMemoryAlignment: true))
    
    results.reserveCapacity(Int(iterations))
    FlatBufferBuilder.maxInstanceCacheSize = 10
    
    print("\(runType)")
    let container = createContainer()
    for _ in 0..<inner_loop_iterations {
        
        // Build buffers
        let time1 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations-1 {
            builder.reset()
            try!container.toFlatBufferBuilder(builder)
        }
        encodedsize = builder._dataCount
        let time2 = CFAbsoluteTimeGetCurrent()
        
        let p = builder._dataStart
        let b = UnsafeBufferPointer(start: p, count: builder._dataCount)
        var fileHandle : NSFileHandle? = nil
        var fileUrl : NSURL? = nil
        // Write to file
        if runType == .decode_from_file {
            let (fh, fu) = createTempFileHandle()
            fh.writeData(NSData(bytes: b.baseAddress, length: b.count))
            
            fileHandle = fh
            fileUrl = fu
        }
        
        // Decode
        let time3 = CFAbsoluteTimeGetCurrent()
        
        switch runType {
        case .decode_eager_class:
            for _ in 0..<iterations {
                results.append(decode_eager_class(b))
            }
        case .decode_eager_struct:
            for _ in 0..<iterations {
                results.append(decode_eager_struct(b))
            }
        default: ()
        }
        
        
        let time4 = CFAbsoluteTimeGetCurrent()
        
        // Use results
        let time5 = CFAbsoluteTimeGetCurrent()
        
        switch runType {
        case .decode_eager_class, .decode_eager_struct:
            for i in 0..<Int(iterations) {
                let result = flatuse(results[i], start:i)
                total = total + UInt64(result)
            }
        case .decode_functions:
            for i in 0..<Int(iterations) {
                let result = functionalDecode(builder._dataStart, start: i)
                total = total + UInt64(result)
            }
        case .decode_direct1_class:
            for i in 0..<Int(iterations) {
                let result = decode_direct1(builder._dataStart, count:builder._dataCount, start: i, withStruct: false)
                total = total + UInt64(result)
            }
        case .decode_direct1_struct:
            for i in 0..<Int(iterations) {
                let result = decode_direct1(builder._dataStart, count:builder._dataCount, start: i, withStruct: true)
                total = total + UInt64(result)
            }
        case .decode_direct2:
            for i in 0..<Int(iterations) {
                let result = decode_direct2(builder._dataStart, count:builder._dataCount, start: i)
                total = total + UInt64(result)
            }
        case .decode_direct3:
            for i in 0..<Int(iterations) {
                let result = decode_direct3(i)
                total = total + UInt64(result)
            }
        case .decode_direct4_class:
            for i in 0..<Int(iterations) {
                let result = decode_direct4_class(i)
                total = total + UInt64(result)
            }
        case .decode_direct4_struct:
            for i in 0..<Int(iterations) {
                let result = decode_direct4_struct(builder._dataStart, count:builder._dataCount, start: i)
                total = total + UInt64(result)
            }
        case .decode_struct:
            for i in 0..<Int(iterations) {
                let result = decode_struct(builder._dataStart, start: i)
                total = total + UInt64(result)
            }
        case .decode_from_file:
            for i in 0..<Int(iterations) {
                let reader = FBFileReaderStruct(fileHandle: fileHandle!, cache: nil)
                let result = decode_from_file(reader, start: i)
                total = total + UInt64(result)
            }
        }
        
        let time6 = CFAbsoluteTimeGetCurrent()
        
        if let fileUrl = fileUrl {
            try!NSFileManager.defaultManager().removeItemAtURL(fileUrl)
        }
        
        encode = encode + (time2 - time1)
        decode = decode + (time4 - time3)
        use = use + (time6 - time5)
    }
    
    print("=================================")
    print("\(((encode) * 1000).string(0)) ms encode")
    print("\(((decode) * 1000).string(0)) ms decode")
    print("\(((use) * 1000).string(0)) ms use")
    print("\(((decode+use) * 1000).string(0)) ms decode+use")
    print("=================================")
    print("")
    return (Int(total), encodedsize)
}

func flatbench() {
    let benchmarks : [BenchmarkRunType] = [.decode_eager_class, .decode_eager_struct, .decode_direct1_class, .decode_direct1_struct, .decode_direct2, .decode_direct3, .decode_direct4_class, .decode_direct4_struct, .decode_functions, .decode_struct, /*.decode_from_file*/]
    
    var total = 0
    var subtotal = 0
    var messageSize = 0
    
    print("Running a total of \(inner_loop_iterations*iterations) iterations")
    print("")
    
    for benchmark in benchmarks
    {
        (subtotal, messageSize) = runbench(benchmark)
        total = total + subtotal
    }
    
    print("")
    print("=================================")
    print("Subtotal: \(subtotal) Total: \(total)")
    print("Encoded size is \(messageSize) bytes, should be 344 if not using unique strings")
    // 344 is with proper padding https://google.github.io/flatbuffers/flatbuffers_benchmarks.html
    print("=================================")
    print("")
}

func createTempFileHandle() -> (handle : NSFileHandle, url : NSURL){
    // The template string:
    let template = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("file.XXXXXX")
    
    // Fill buffer with a C string representing the local file system path.
    var buffer = [Int8](count: Int(PATH_MAX), repeatedValue: 0)
    template!.getFileSystemRepresentation(&buffer, maxLength: buffer.count)
    
    // Create unique file name (and open file):
    let fd = mkstemp(&buffer)
    let url = NSURL(fileURLWithFileSystemRepresentation: buffer, isDirectory: false, relativeToURL: nil)
    //print(url.path!)
    return (NSFileHandle(fileDescriptor: fd, closeOnDealloc: true), url)
}

flatbench()
