//
//  Level.swift
//  NightFall
//
//  Created by Jeff Ligon on 2/2/15.
//  Copyright (c) 2015 Visceral Origami LLC. All rights reserved.
//

import Foundation
let NumColumns = 9
let NumRows = 9

class Level {
    private var engrams = Array2D<Engram>(columns: NumColumns, rows: NumRows)
    private var tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows)
    private var possibleSwaps = Set<Swap>()
    
    private var comboMultiplier = 0
    let targetScore: Int!
    let maximumMoves: Int!
    
    init(filename: String) {
        // 1
        if let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename) {
            // 2
            if let tilesArray: AnyObject = dictionary["tiles"] {
                // 3
                for (row, rowArray) in enumerate(tilesArray as [[Int]]) {
                    // 4
                    let tileRow = NumRows - row - 1
                    // 5
                    for (column, value) in enumerate(rowArray) {
                        if value == 1 {
                            tiles[column, tileRow] = Tile()
                        }
                    }
                }
                targetScore = (dictionary["targetScore"] as NSNumber).integerValue
                maximumMoves = (dictionary["moves"] as NSNumber).integerValue
            }
        }
        
    }
    
    private func calculateScores(chains: Set<Chain>) {
        // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplier
            switch chain.chainType{
            case .TeeShapped: chain.score = chain.score * 2
            case .EllShapped: chain.score = chain.score * 2
            case .Fiver:  chain.score = chain.score * 3
            default: break //no bonus!
            }
            ++comboMultiplier
        }
    }
    
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
    
    func performSwap(swap: Swap) {
        let columnA = swap.engramA.column
        let rowA = swap.engramA.row
        let columnB = swap.engramB.column
        let rowB = swap.engramB.row
        
        engrams[columnA, rowA] = swap.engramB
        swap.engramB.column = columnA
        swap.engramB.row = rowA
        
        engrams[columnB, rowB] = swap.engramA
        swap.engramA.column = columnB
        swap.engramA.row = rowB
    }
    
    func tileAtColumn(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }

    func engramAtColumn(column: Int, row: Int) -> Engram? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return engrams[column, row]
    }

    func shuffle() -> Set<Engram> {
        var set: Set<Engram>
        do {
            set = createInitialEngrams()
            detectPossibleSwaps()
            //println("possible swaps: \(possibleSwaps)")
        }
            while possibleSwaps.count == 0
        
        return set
    }
    
    func fillHoles() -> [[Engram]] {
        var columns = [[Engram]]()
        // 1
        for column in 0..<NumColumns {
            var array = [Engram]()
            for row in 0..<NumRows {
                // 2
                if tiles[column, row] != nil && engrams[column, row] == nil {
                    // 3
                    for lookup in (row + 1)..<NumRows {
                        if let engram = engrams[column, lookup] {
                            // 4
                            engrams[column, lookup] = nil
                            engrams[column, row] = engram
                            engram.row = row
                            // 5
                            array.append(engram)
                            // 6
                            break
                        }
                    }
                }
            }
            // 7
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func topUpEngrams() -> [[Engram]] {
        var columns = [[Engram]]()
        var engramType: EngramType = .Unknown
        
        for column in 0..<NumColumns {
            var array = [Engram]()
            // 1
            for var row = NumRows - 1; row >= 0 && engrams[column, row] == nil; --row {
                // 2
                if tiles[column, row] != nil {
                    // 3
                    var newEngramType: EngramType
                    do {
                        newEngramType = EngramType.random()
                    } while newEngramType == engramType
                    engramType = newEngramType
                    // 4
                    let engram = Engram(column: column, row: row, engramType: engramType)
                    engrams[column, row] = engram
                    array.append(engram)
                }
            }
            // 5
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    private func hasChainAtColumn(column: Int, row: Int) -> Bool {
        let engramType = engrams[column, row]!.engramType
        
        var horzLength = 1
        for var i = column - 1; i >= 0 && engrams[i, row]?.engramType == engramType;
            --i, ++horzLength { }
        for var i = column + 1; i < NumColumns && engrams[i, row]?.engramType == engramType;
            ++i, ++horzLength { }
        if horzLength >= 3 { return true }
        
        var vertLength = 1
        for var i = row - 1; i >= 0 && engrams[column, i]?.engramType == engramType;
            --i, ++vertLength { }
        for var i = row + 1; i < NumRows && engrams[column, i]?.engramType == engramType;
            ++i, ++vertLength { }
        return vertLength >= 3
    }
    
    private func detectHorizontalMatches() -> Set<Chain> {
        // 1
        var set = Set<Chain>()
        // 2
        for row in 0..<NumRows {
            for var column = 0; column < NumColumns - 2 ; {
                // 3
                if let engram = engrams[column, row] {
                    let matchType = engram.engramType
                    // 4
                    if engrams[column + 1, row]?.engramType == matchType &&
                        engrams[column + 2, row]?.engramType == matchType {
                            // 5
                            let chain = Chain(chainType: .Horizontal)
                            do {
                                chain.addEngram(engrams[column, row]!)
                                ++column
                            }
                                while column < NumColumns && engrams[column, row]?.engramType == matchType
                            
                            set.addElement(chain)
                            continue
                    }
                }
                // 6
                ++column
            }
        }
        return set
    }
    
    private func detectVerticalMatches() -> Set<Chain> {
        var set = Set<Chain>()
        
        for column in 0..<NumColumns {
            for var row = 0; row < NumRows - 2; {
                if let engram = engrams[column, row] {
                    let matchType = engram.engramType
                    
                    if engrams[column, row + 1]?.engramType == matchType &&
                        engrams[column, row + 2]?.engramType == matchType {
                            
                            let chain = Chain(chainType: .Vertical)
                            do {
                                chain.addEngram(engrams[column, row]!)
                                ++row
                            }
                                while row < NumRows && engrams[column, row]?.engramType == matchType
                            
                            set.addElement(chain)
                            continue
                    }
                }
                ++row
            }
        }
        return set
    }
    
    func removeMatches() -> Set<Chain> {
        var horizontalChains = detectHorizontalMatches()
        var verticalChains = detectVerticalMatches()
        var bigChains = Set<Chain>()
        
        for hChain in horizontalChains{
            for vChain in verticalChains{
                //start with 5's so we can ignore the others
                if vChain.engrams[1].engramType == hChain.engrams[1].engramType{
                    var newChain = Chain(chainType: Chain.ChainType.Fiver)
                    newChain.engrams = vChain.engrams + hChain.engrams
                    bigChains.addElement(newChain)
                    horizontalChains.removeElement(hChain)
                    verticalChains.removeElement(vChain)
                }else if (hChain.engrams[0] == vChain.engrams[0]) || (hChain.engrams[0] == vChain.engrams[2]) ||
                    (hChain.engrams[2] == vChain.engrams[0]) || (hChain.engrams[2] == vChain.engrams[2]){
                       //detect L's
                        var newChain = Chain(chainType: Chain.ChainType.EllShapped)
                        newChain.engrams = vChain.engrams + hChain.engrams
                        bigChains.addElement(newChain)
                        horizontalChains.removeElement(hChain)
                        verticalChains.removeElement(vChain)
                }else if (hChain.engrams[1] == vChain.engrams[0]) || (hChain.engrams[1] == vChain.engrams[2]) ||
                    (hChain.engrams[2] == vChain.engrams[1]) || (hChain.engrams[0] == vChain.engrams[1]){
                       //detect T's
                        var newChain = Chain(chainType: Chain.ChainType.TeeShapped)
                        newChain.engrams = vChain.engrams + hChain.engrams
                        bigChains.addElement(newChain)
                        horizontalChains.removeElement(hChain)
                        verticalChains.removeElement(vChain)
                }
                
            }
        }
        
        
        removeEngrams(bigChains)
        removeEngrams(horizontalChains)
        removeEngrams(verticalChains)
        
        calculateScores(bigChains)
        calculateScores(horizontalChains)
        calculateScores(verticalChains)
        
        return horizontalChains.unionSet(verticalChains).unionSet(bigChains)
    }
    
    private func removeEngrams(chains: Set<Chain>) {
        for chain in chains {
            for engram in chain.engrams {
                engrams[engram.column, engram.row] = nil
            }
        }
    }
    
    func isPossibleSwap(swap: Swap) -> Bool {
        return possibleSwaps.containsElement(swap)
    }
    
    func detectPossibleSwaps() {
        var set = Set<Swap>()
        
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                if let engram = engrams[column, row] {
                    
                    if row < NumRows - 1 {
                        if let other = engrams[column, row + 1] {
                            engrams[column, row] = other
                            engrams[column, row + 1] = engram
                            
                            // Is either engram now part of a chain?
                            if hasChainAtColumn(column, row: row + 1) ||
                                hasChainAtColumn(column, row: row) {
                                    set.addElement(Swap(engramA: engram, engramB: other))
                            }
                            
                            // Swap them back
                            engrams[column, row] = engram
                            engrams[column, row + 1] = other
                        }
                    }
                    
                    // Is it possible to swap this engram with the one on the right?
                    if column < NumColumns - 1 {
                        // Have a engram in this spot? If there is no tile, there is no engram.
                        if let other = engrams[column + 1, row] {
                            // Swap them
                            engrams[column, row] = other
                            engrams[column + 1, row] = engram
                            
                            // Is either engram now part of a chain?
                            if hasChainAtColumn(column + 1, row: row) ||
                                hasChainAtColumn(column, row: row) {
                                    set.addElement(Swap(engramA: engram, engramB: other))
                            }
                            
                            // Swap them back
                            engrams[column, row] = engram
                            engrams[column + 1, row] = other
                        }
                    }
                }
            }
        }
        
        possibleSwaps = set
    }
    
    private func createInitialEngrams() -> Set<Engram> {
        var set = Set<Engram>()
        
        // 1
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                
                if tiles[column, row] != nil {
                // 2
                    var engramType: EngramType
                    do {
                        engramType = EngramType.random()
                    }
                        while (column >= 2 &&
                            engrams[column - 1, row]?.engramType == engramType &&
                            engrams[column - 2, row]?.engramType == engramType)
                            || (row >= 2 &&
                                engrams[column, row - 1]?.engramType == engramType &&
                                engrams[column, row - 2]?.engramType == engramType)
                
                // 3
                let engram = Engram(column: column, row: row, engramType: engramType)
                engrams[column, row] = engram
                
                // 4
                set.addElement(engram)
                }
            }
        }
        return set
    }
    
}

