//
//  Chain.swift
//  NightFall
//
//  Created by Jeff Ligon on 2/2/15.
//  Copyright (c) 2015 Visceral Origami LLC. All rights reserved.
//

import Foundation

class Chain: Hashable, CustomStringConvertible {
    var engrams = [Engram]()
    var score:Int! = 0
    
    enum ChainType: CustomStringConvertible {
        case Horizontal
        case Vertical
        case EllShapped
        case TeeShapped
        case Fiver
        
        var description: String {
            switch self {
            case .Horizontal: return "Horizontal"
            case .Vertical: return "Vertical"
            case .EllShapped: return "L Shaped"
            case .TeeShapped: return "T Shaped"
            case .Fiver: return "Fiver"
            }
        }
    }
    
    
    
    var chainType: ChainType
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func addEngram(engram: Engram) {
        engrams.append(engram)
    }
    
    func firstEngram() -> Engram {
        return engrams[0]
    }
    
    func lastEngram() -> Engram {
        return engrams[engrams.count - 1]
    }
    
    var length: Int {
        return engrams.count
    }
    
    var description: String {
        return "type:\(chainType) engrams:\(engrams)"
    }
    
    var hashValue: Int {
        return engrams.reduce(0) { $0.hashValue ^ $1.hashValue }
    }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
    return lhs.engrams == rhs.engrams
}