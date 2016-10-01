//
//  bench_commonDefinitions.swift
//  FBTest
//
//  Created by Maxim Zaks on 27.09.16.
//  Copyright © 2016 maxim.zaks. All rights reserved.
//

import Foundation

public enum Enum : Int16 {
    case Apples, Pears, Bananas
}

public struct Foo : Scalar {
    public let id : UInt64
    public let count : Int16
    public let prefix : Int8
    public let length : UInt32
}
public func ==(v1:Foo, v2:Foo) -> Bool {
    return  v1.id==v2.id &&  v1.count==v2.count &&  v1.prefix==v2.prefix &&  v1.length==v2.length
}

public struct Bar : Scalar {
    public let parent : Foo
    public let time : Int32
    public let ratio : Float32
    public let size : UInt16
}
public func ==(v1:Bar, v2:Bar) -> Bool {
    return  v1.parent==v2.parent &&  v1.time==v2.time &&  v1.ratio==v2.ratio &&  v1.size==v2.size
}

public final class FooBar {
    public var sibling : Bar? = nil
    public var name : String? = nil
    public var rating : Float64 = 0
    public var postfix : UInt8 = 0
    public init(){}
    public init(sibling: Bar?, name: String?, rating: Float64, postfix: UInt8){
        self.sibling = sibling
        self.name = name
        self.rating = rating
        self.postfix = postfix
    }
}

public final class FooBarContainer {
    public var list : ContiguousArray<FooBar?> = []
    public var initialized : Bool = false
    public var fruit : Enum? = Enum.Apples
    public var location : String? = nil
    public init(){}
    public init(list: ContiguousArray<FooBar?>, initialized: Bool, fruit: Enum?, location: String?){
        self.list = list
        self.initialized = initialized
        self.fruit = fruit
        self.location = location
    }
}
