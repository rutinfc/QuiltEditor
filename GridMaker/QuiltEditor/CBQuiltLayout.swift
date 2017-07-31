//
//  CBQuiltLayout.swift
//  GridMaker
//
//  Created by jeongkyu kim on 2017. 7. 26..
//  Copyright © 2017년 jeongkyu kim. All rights reserved.
//

import UIKit

@objc protocol CBQuiltLayoutDelegate : UICollectionViewDelegate {
    
    @objc optional func collectionView(_ collectionView:UICollectionView, layout:UICollectionViewLayout, blockSizeAtIndexPath indexPath:IndexPath) -> CGSize
    @objc optional func collectionView(_ collectionView:UICollectionView, layout:UICollectionViewLayout, insetsAtIndexPath indexPath:IndexPath) -> UIEdgeInsets
}

@objc class CBQuiltLayout: UICollectionViewLayout {
    
    weak open var delegate : CBQuiltLayoutDelegate?
    
    var direction : UICollectionViewScrollDirection = .vertical {
        
        didSet {
            self.invalidateLayout()
        }
    }
    
    var blockCount : Int = 4  {
        didSet {
            self.invalidateLayout()
        }
    }
    
    override var collectionViewContentSize: CGSize {
        
        guard let collectionView = self.collectionView else {
            return CGSize.zero
        }
        
        let rect = UIEdgeInsetsInsetRect(collectionView.frame, collectionView.contentInset)
        
        if (self.isVertical) {
            
            return CGSize(width: rect.width, height: (self.blockPoint.y + 1) * self.pixels)
        }
        
        return CGSize(width:(self.blockPoint.x + 1) * self.pixels, height:rect.height)
    }
    
    private var isVertical : Bool {
        return (self.direction == .vertical)
    }
    
    private var pixels : CGFloat {
        
        guard let collectionView = self.collectionView else {
            return 0
        }
        
        if (self.isVertical) {
            return (collectionView.frame.width / CGFloat(self.blockCount))
        }
        
        return (collectionView.frame.height / CGFloat(self.blockCount))
    }
    
    private var restrictedDimensionBlockSize : Int {
        
        guard let collectionView = self.collectionView else {
            return 1
        }
        
        let rect = UIEdgeInsetsInsetRect(collectionView.frame, collectionView.contentInset)
        
        var size = rect.height / self.pixels
        
        if self.isVertical {
            size = rect.width / self.pixels
        }
        
        if size == 0 {
            return 1
        }
        
        return Int(size)
    }
    
    private var spacePoint = CGPoint.zero
    private var blockPoint = CGPoint.zero
    private var indexPaths = [Int:[Int:IndexPath]]()
    private var positions = [Int:[Int:CGPoint]]()
    private var positionsCached = false
    private var previousLayoutAttributes = [UICollectionViewLayoutAttributes]()
    private var previousLayoutRect : CGRect = CGRect.zero
    private var lastIndexPath : IndexPath?
        
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var attirbutes = [UICollectionViewLayoutAttributes]()
        
        if self.delegate == nil {
            return attirbutes;
        }
        
        if rect == self.previousLayoutRect {
            return self.previousLayoutAttributes
        }
        
        if self.pixels == 0 {
            return attirbutes
        }
        
        self.previousLayoutRect = rect
        
        var dimensionStart = Int(rect.origin.x / self.pixels)
        var dimensionLength = Int(rect.width / self.pixels)
        
        if self.isVertical {
            dimensionStart = Int(rect.origin.y / self.pixels)
            dimensionLength = Int(rect.height / self.pixels)
        }
        
        let dimensionEnd = Int(dimensionStart + dimensionLength + 1)
        
        self.fillInBlocks(unrestrictedRow: dimensionEnd)
        
        self.traversTilesBetween(dimensionStart: dimensionStart, dimensionEnd: dimensionEnd) { (point) in
            
            if let indexPath = self.indexPath(point: point) {
                
                if let attribute = self.layoutAttributesForItem(at: indexPath) {
                    attirbutes.append(attribute)
                }
            }
        }
        
        self.previousLayoutAttributes = attirbutes
        
        return attirbutes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        guard let collectionView = self.collectionView else { return nil }
        
        var frame = self.frame(indexPath: indexPath)
        
        if let insets = self.delegate?.collectionView?(collectionView, layout: self, insetsAtIndexPath: indexPath) {
            frame = UIEdgeInsetsInsetRect(frame, insets)
        }
        
        let attribute = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        attribute.frame = frame
        
        return attribute
    }
    
    override func invalidateLayout() {
        
        super.invalidateLayout()
        
        self.blockPoint = CGPoint.zero
        self.spacePoint = CGPoint.zero
        self.previousLayoutRect = CGRect.zero
        self.previousLayoutAttributes.removeAll()
        self.lastIndexPath = nil
        self.indexPaths.removeAll()
        self.positions.removeAll()
    }
    
    override func prepare() {
        super.prepare()
        
        if self.delegate == nil {
            return
        }
        
        if self.pixels == 0 {
            return
        }
        
        guard let collectionView = self.collectionView else { return }
        
        let scrollFrame = CGRect(x: collectionView.contentOffset.x, y: collectionView.contentOffset.y, width: collectionView.frame.width, height: collectionView.frame.height)
        
        var items = Int(scrollFrame.maxX / self.pixels) + 1
        
        if self.isVertical {
            items = Int(scrollFrame.maxY / self.pixels) + 1
        }
        
        self.fillInBlocks(unrestrictedRow: items)
    }
    
    private func frame(indexPath:IndexPath) -> CGRect {
        
        guard let collectionView = self.collectionView else {
            return CGRect.zero
        }
        
        let rect = UIEdgeInsetsInsetRect(collectionView.frame, collectionView.contentInset)
        
        let position = self.position(indexPath: indexPath)
        let size = self.blockSize(indexPath: indexPath)
        
        var result = CGRect.zero
        
        if self.isVertical {
            
            let dimension = (rect.width - CGFloat(self.restrictedDimensionBlockSize) * self.pixels) / 2
            result.origin = CGPoint(x: round(position.x * self.pixels + dimension), y: round(position.y * self.pixels))
            result.size = CGSize(width: round(size.width * self.pixels), height: round(size.height * self.pixels))

        } else {
            
            let dimension = (rect.height - CGFloat(self.restrictedDimensionBlockSize) * self.pixels) / 2
            result.origin = CGPoint(x: position.x * self.pixels, y: position.y * self.pixels + dimension)
            result.size = CGSize(width: size.width * self.pixels, height: size.height * self.pixels)
        }
        
        return result
    }
    
    private func fillInBlocks(unrestrictedRow:Int) {
        
        self.loopLastIndexPath { (item, section) in
            
            let indexPath = IndexPath(item: item, section: section)
            
            if self.placeBlock(indexPath: indexPath) == true {
                self.lastIndexPath = indexPath
            }
            
            var currentItem = self.spacePoint.x
            if self.isVertical {
                currentItem = self.spacePoint.y
            }
            
            if Int(currentItem) >= unrestrictedRow {
                return true
            }
            
            return false
        }
    }
    
    private func fillInBlock(indexPath:IndexPath) {
        
        self.loopLastIndexPath { (item, section) -> Bool in
            
            let indexPath = IndexPath(item: item, section: section)
            
            if self.placeBlock(indexPath:indexPath) == true {
                self.lastIndexPath = indexPath
            }
            
            return false
        }
    }
    
    private func placeBlock(indexPath:IndexPath) -> Bool {
        
        let blockSize = self.blockSize(indexPath: indexPath)
        
        var all = true
        var dimension = Int(self.spacePoint.x)
        var maximum = Int(self.collectionViewContentSize.width)
        
        if self.isVertical {
            dimension = Int(self.spacePoint.y)
            maximum = Int(self.collectionViewContentSize.height)
        }
        
        for current in dimension ..< maximum {
            
            for restictedDimension in 0 ..< self.restrictedDimensionBlockSize {
                
                var blockOrigin = CGPoint(x: current, y: restictedDimension)
                if self.isVertical {
                    blockOrigin = CGPoint(x: restictedDimension, y: current)
                }
                
                if self.indexPath(point: blockOrigin) != nil {
                    continue;
                }
                
                if all == true {
                    self.spacePoint = blockOrigin
                    all = false
                }
                
                if self.checkBlock(blockOrigin: blockOrigin, blockSize: blockSize, indexPath: indexPath) == false {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func checkBlock(blockOrigin:CGPoint, blockSize:CGSize, indexPath:IndexPath) -> Bool {
        
        let allBlocks = self.traversTiles(point: blockOrigin, size: blockSize, iterator: { (point) -> Bool in
            
            let spaceAvailable = (self.indexPath(point: point) == nil)
            var value = point.y
            var blockValue = blockOrigin.y
            
            if self.isVertical == true {
                value = point.x
                blockValue = blockOrigin.x
            }
            let inBounds = (Int(value) < self.restrictedDimensionBlockSize)
            let maximumBoundSize = (blockValue == 0)
            
            if (spaceAvailable && maximumBoundSize && !inBounds) {
                return true
            }
            
            return (spaceAvailable && inBounds)
        })
        
        if allBlocks == false {
            return true
        }
        
        self.setIndexPath(indexPath, position: blockOrigin)
        
        _ = self.traversTiles(point: blockOrigin, size: blockSize, iterator: { (point) -> Bool in
            
            self.setPosition(point, indexPath: indexPath)
            
            self.blockPoint = point
            
            return true
        })
        
        return false
    }
    
    private func position(indexPath:IndexPath) -> CGPoint {
        
        var point = self.positions[indexPath.section]?[indexPath.item]
        
        if point == nil {
            self.fillInBlock(indexPath: indexPath)
            
            point = self.positions[indexPath.section]?[indexPath.item]
        }
        
        return point!
    }
    
    private func indexPath(point:CGPoint) -> IndexPath? {
        
        var unresticedPoint = point.x
        var restricedPoint = point.y
        
        if self.isVertical == true {
            unresticedPoint = point.y
            restricedPoint = point.x
        }
        
        return self.indexPaths[Int(restricedPoint)]?[Int(unresticedPoint)]
    }
    
    private func setIndexPath(_ indexPath:IndexPath, position:CGPoint) {
        
        var section = self.positions[indexPath.section]
        
        if section == nil {
            section = [Int:CGPoint]()
        }
        
        section?[indexPath.item] = position
        
        self.positions[indexPath.section] = section
    }
    
    private func setPosition(_ point:CGPoint, indexPath:IndexPath) {
        
        var unresticedPoint = point.x
        var restricedPoint = point.y
        
        if self.isVertical == true {
            unresticedPoint = point.y
            restricedPoint = point.x
        }
        
        var section = self.indexPaths[Int(restricedPoint)]
        
        if section == nil {
            section = [Int:IndexPath]()
        }
        
        section?[Int(unresticedPoint)] = indexPath
        
        self.indexPaths[Int(restricedPoint)] = section
    }
    
    private func traversTilesBetween(dimensionStart:Int, dimensionEnd:Int, iterator:(CGPoint)->Void) {
        
        let isVertical = self.isVertical
        
        for unrestricted in dimensionStart ..< dimensionEnd {
            
            for restricted in 0..<self.restrictedDimensionBlockSize {
                
                var point = CGPoint(x: unrestricted, y: restricted)
                
                if isVertical == true {
                    point = CGPoint(x: restricted, y: unrestricted)
                }
                iterator(point)
            }
        }
    }
    
    private func traversTiles(point:CGPoint, size:CGSize, iterator:(CGPoint) -> Bool) -> Bool {
        
        for col in Int(point.x) ..< Int(point.x+size.width) {
            
            for row in Int(point.y) ..< Int(point.y+size.height) {
                
                if iterator(CGPoint(x: col, y: row)) == false {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func blockSize(indexPath:IndexPath) -> CGSize {
        
        guard let collectionView = self.collectionView else { return CGSize(width: 1, height: 1) }
        
        guard let delegate = self.delegate else { return CGSize(width: 1, height: 1) }
        
        guard let size = delegate.collectionView?(collectionView, layout: self, blockSizeAtIndexPath: indexPath) else { return CGSize(width: 1, height: 1) }
        
        return size
    }
    
    private func loopLastIndexPath(loop:(_ item:Int, _ section:Int)->Bool) {
        
        guard let collectionView = self.collectionView else { return }
        
        var lastSection = 0
        var lastItem = 0
        
        if let lastIndexPath = self.lastIndexPath {
            lastSection = lastIndexPath.section
            lastItem = lastIndexPath.item + 1
        }
        
        for section in lastSection ..< collectionView.numberOfSections {
            
            let items = collectionView.numberOfItems(inSection: section)
            
            for item in lastItem ..< items {
                
                if loop(item, section) == true {
                    return
                }
            }
        }
    }
}

