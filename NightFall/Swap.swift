//
//  Swap.swift
//  NightFall
//
//  Created by Jeff Ligon on 2/2/15.
//  Copyright (c) 2015 Visceral Origami LLC. All rights reserved.
//

import Foundation

struct Swap: Printable, Hashable {
    let engramA: Engram
    let engramB: Engram
    
    init(engramA: Engram, engramB: Engram) {
        self.engramA = engramA
        self.engramB = engramB
    }
    
    var description: String {
        return "swap \(engramA) with \(engramB)"
    }
    var hashValue: Int {
        return engramA.hashValue ^ engramB.hashValue
    }
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.engramA == rhs.engramA && lhs.engramB == rhs.engramB) ||
        (lhs.engramB == rhs.engramA && lhs.engramA == rhs.engramB)
}