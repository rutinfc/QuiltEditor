//
//  CBPatternLayoutPattern.swift
//  Cloud
//
//  Created by jeongkyu kim on 2018. 2. 23..
//  Copyright © 2018년 skt. All rights reserved.
//

import Foundation

class CBPatternLayoutInfo {

    var sectionHeight : CGFloat = 20
    var column : Int = 3
    var fixedHeight : CGFloat = 0
    var spacing : CGFloat = 2
    
    var patterns : [CGRect]
    
    init() {
        self.patterns = [CGRect]()
        
        for index in 0..<self.column {
            self.patterns.append(CGRect(x:index, y:0, width:1, height:1))
        }
    }
}

class CBSinglePatternLayoutInfo : CBPatternLayoutInfo {
    
    override init() {
        super.init()
        
        self.sectionHeight = 0
        self.fixedHeight = 150
        self.column = 1
        self.spacing = 0
        
        self.patterns.append(CGRect(x:0, y:0, width:1, height:1))
    }
}

class CBMagaginePatternLayoutInfo : CBPatternLayoutInfo {
    
    override init() {
        
        super.init()
        
        var pattern = [CGRect]()
        
        for index in 0..<self.column {
            pattern.append(CGRect(x:index, y:0, width:1, height:1))
        }
        
        pattern.append(CGRect(x:0, y:1, width:self.column - 1, height:self.column - 1))
        
        for index in 0..<self.column - 1{
            pattern.append(CGRect(x:self.column - 1, y:index + 1, width:1, height:1))
        }
        
        for index in 0..<self.column {
            pattern.append(CGRect(x:index, y:self.column, width:1, height:1))
        }
        
        pattern.append(CGRect(x:0, y:self.column + 1, width:1, height:1))
        
        pattern.append(CGRect(x:1, y:self.column + 1, width:self.column - 1, height:self.column - 1))
        
        pattern.append(CGRect(x:0, y:self.column + 2, width:1, height:1))
        
        self.patterns = pattern
    }
}

class CBMagaginePatternLayoutInfo2 : CBPatternLayoutInfo {
    
    override init() {
        
        super.init()
        
        var pattern = [CGRect]()
        
        for index in 0..<self.column {
            pattern.append(CGRect(x:index, y:0, width:1, height:1))
        }
        
        pattern.append(CGRect(x:0, y:1, width:self.column - 1, height:self.column - 1))
        
        for index in 0..<self.column - 1{
            pattern.append(CGRect(x:self.column - 1, y:index + 1, width:1, height:1))
        }
        
        for index in 0..<self.column {
            pattern.append(CGRect(x:index, y:self.column, width:1, height:1))
        }
        
        pattern.append(CGRect(x:0, y:self.column + 1, width:1, height:1))
        
        pattern.append(CGRect(x:1, y:self.column + 1, width:1, height:1))
        
        self.patterns = pattern
    }
}
