//
//  Engram.swift
//  NightFall
//
//  Created by Jeff Ligon on 2/2/15.
//  Copyright (c) 2015 Visceral Origami LLC. All rights reserved.
//

import SpriteKit

enum EngramType: Int, Printable {
    case Unknown = 0, Croissant, Cupcake, Danish, Donut, Macaroon, SugarEngram
    
    static func random() -> EngramType {
        return EngramType(rawValue: Int(arc4random_uniform(6)) + 1)!
    }
    var spriteName: String {
        let spriteNames = [
            "Croissant",
            "Cupcake",
            "Danish",
            "Donut",
            "Macaroon",
            "SugarEngram"]
        
        return spriteNames[rawValue - 1]
    }
    
    var highlightedSpriteName: String {
        return spriteName + "-Highlighted"
    }
    
    var description: String{
        return spriteName
    }
    
}

func ==(lhs: Engram, rhs: Engram) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

class Engram: Printable, Hashable{
    var column: Int
    var row: Int
    let engramType: EngramType
    var sprite: SKSpriteNode?
    
    init(column: Int, row: Int, engramType: EngramType) {
        self.column = column
        self.row = row
        self.engramType = engramType
    }
    
    var hashValue: Int {
        return row*10 + column
    }
    
    var description: String {
        return "type:\(engramType) square:(\(column),\(row))"
    }
}

