//
//  CBPatternLayout.swift
//  Cloud
//
//  Created by jeongkyu kim on 2018. 2. 21..
//  Copyright © 2018년 skt. All rights reserved.
//

import UIKit

protocol CBPatternLayoutDelegate : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, sectionLayoutInfo section: Int) -> CBPatternLayoutInfo
}

class CBPatternLayout : UICollectionViewLayout {
    
    var stickySection : Bool = false
    
    private var contentSize : CGSize = CGSize.zero
    private var contentHeight : CGFloat = 0
    private var yOffset : CGFloat = 0
    
    private var dirty : Bool = true
    private var pagingHeight : CGFloat = 1000
    
    private var previousLayoutRect : CGRect = CGRect.zero
    private var previousLayoutAttributes = [UICollectionViewLayoutAttributes]()
    
    private var itemBounds : [CGRect] = [CGRect]()
    
    private var gridLayoutAttributes = [[UICollectionViewLayoutAttributes]]()
    private var sectionLayoutAttributes = [UICollectionViewLayoutAttributes]()
    private var pagingLayoutAttributes = NSMutableArray()

    override var collectionViewContentSize: CGSize {
        return self.contentSize
    }
    
    override func invalidateLayout() {
        self.dirty = true
        super.invalidateLayout()
    }
    
    override func prepare() {
        super.prepare()
        
        if let collectionView = self.collectionView {
            
            if self.sectionLayoutAttributes.count != collectionView.numberOfSections {
                self.dirty = true
            }
            
            for (index, _) in sectionLayoutAttributes.enumerated() {
                let count = self.gridLayoutAttributes[index].count
                
                if collectionView.numberOfItems(inSection: index) != count {
                    self.dirty = true
                    break
                }
            }
        }
        
        self.prepareLayoutAttribute()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        if self.stickySection == false && self.previousLayoutRect.equalTo(rect) == true {
            return self.previousLayoutAttributes
        }
        
        self.previousLayoutRect = rect
        self.previousLayoutAttributes.removeAll()
        
        var current = rect.minY
        
        if current < 0 {
            current = 0
        }
        
        repeat {
            
            if let attr = self.pagingAttributes(offset:current) {
                self.previousLayoutAttributes.append(contentsOf: attr)
            } else {
                break
            }
            
            current += self.pagingHeight
            
        } while current <= (rect.maxY + self.pagingHeight)
        
        for (section, bounds) in self.itemBounds.enumerated() {
            
            if bounds.intersects(rect) {
                
                let indexPath = IndexPath(item:0, section:section)
                
                if let sectionAttr = self.layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: indexPath) {
                    self.previousLayoutAttributes.append(sectionAttr)
                }
            }
        }
        
        return self.previousLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        if self.gridLayoutAttributes[indexPath.section].count > indexPath.item {
            return self.gridLayoutAttributes[indexPath.section][indexPath.item]
        }
        return nil
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        guard let collectionView = self.collectionView else {
            return nil
        }
        
        if elementKind == UICollectionElementKindSectionHeader {
            
            if self.stickySection == false {
                return self.sectionLayoutAttributes[indexPath.section]
            }
            
            let attribute = self.sectionLayoutAttributes[indexPath.section]
            
            let boundaries = self.itemBounds[indexPath.section]
            
            // Helpers
            let contentOffsetY = collectionView.contentOffset.y
            var frameForSupplementaryView = attribute.frame
            
            let minimum = boundaries.minY
            let maximum = boundaries.maxY - frameForSupplementaryView.height
            
            if contentOffsetY < minimum {
                frameForSupplementaryView.origin.y = minimum
            } else if contentOffsetY > maximum {
                frameForSupplementaryView.origin.y = maximum
            } else {
                frameForSupplementaryView.origin.y = contentOffsetY
            }
            
            attribute.frame = frameForSupplementaryView
            
            return attribute
        }
        
        return nil
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        
        if self.stickySection == true {
            
            return true
        }
        
        guard let collectionView = self.collectionView else {
            return false
        }
        
        return (collectionView.frame.size.equalTo(newBounds.size) == false)
    }
    
    var deleteIndexPaths = [IndexPath]()
    var insertIndexPaths = [IndexPath]()
    
    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        
        super.prepare(forCollectionViewUpdates: updateItems)
        
        for (_, item) in updateItems.enumerated() {
            
            if let indexPath = item.indexPathBeforeUpdate, item.updateAction == .delete {
                self.deleteIndexPaths.append(indexPath)
            }
            
            if let indexPath = item.indexPathAfterUpdate, item.updateAction == .insert {
                self.insertIndexPaths.append(indexPath)
            }
        }
    }
    
    override func finalizeCollectionViewUpdates() {
        
        self.deleteIndexPaths.removeAll()
        self.insertIndexPaths.removeAll()
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        if let attr = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath) {
            
            attr.alpha = 1
            
            if self.insertIndexPaths.contains(attr.indexPath) {
                attr.alpha = 0
            }
            
            return attr
        }
        
        return nil
    }
    
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        if let attr = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath) {
            
            attr.transform3D = CATransform3DIdentity
            attr.alpha = 1
            
            if self.deleteIndexPaths.contains(attr.indexPath) {
                
                attr.transform3D = CATransform3DMakeScale(0.1, 0.1, 1)
                attr.alpha = 0
            }
            
            return attr
        }
        
        return nil
    }
    
    override func initialLayoutAttributesForAppearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        if let attr = super.initialLayoutAttributesForAppearingSupplementaryElement(ofKind: elementKind, at: elementIndexPath) {
            
            attr.alpha = 1
            attr.transform3D = CATransform3DIdentity
            
            if self.insertIndexPaths.contains(attr.indexPath) {
                attr.transform3D = CATransform3DMakeScale(0.1, 0.1, 1)
                attr.alpha = 0
            }
            
            return attr
        }
        
        return nil
    }
    
    override func finalLayoutAttributesForDisappearingSupplementaryElement(ofKind elementKind: String, at elementIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        if let attr = super.finalLayoutAttributesForDisappearingSupplementaryElement(ofKind: elementKind, at:elementIndexPath) {
            
            attr.alpha = 1
            
            if self.deleteIndexPaths.contains(attr.indexPath) {
                
                for indexPath in self.insertIndexPaths {
                    
                    if indexPath.section == attr.indexPath.section {
                        attr.alpha = 0
                    }
                }
            }
            
            return attr
        }
        
        return nil
    }
}

private extension CBPatternLayout {
    
    func hasSection() -> Bool {
        
        if let collectionView = self.collectionView {
            return (collectionView.numberOfSections > 0)
        }
        return false
    }
    
    func prepareLayoutAttribute() {
        
        if self.dirty == false {
            return
        }
        
        self.pagingLayoutAttributes.removeAllObjects()
        
        self.gridLayoutAttributes.removeAll()
        self.sectionLayoutAttributes.removeAll()
        self.itemBounds.removeAll()
        
        self.contentHeight = 2
        self.yOffset = 0

        guard let collectionView = self.collectionView else {
            return
        }
        
        self.pagingHeight = collectionView.bounds.height
        
        let width = collectionView.bounds.width
        
        if self.hasSection() == true {
            self.prepareSectionGridLayoutAttribute()
        } else {
            self.prepareGridLayoutAttribute(section:0)
        }
        
        self.contentSize = CGSize(width:width, height:self.contentHeight)
        
        self.dirty = false
        self.previousLayoutRect = CGRect.zero
        self.previousLayoutAttributes.removeAll()
    }
    
    func pagingAttributes(offset:CGFloat) -> [UICollectionViewLayoutAttributes]? {
        
        let pagingIndex = Int(offset / self.pagingHeight)
        
        if self.pagingLayoutAttributes.count <= pagingIndex {
            return nil
        }
        
        guard let attributes = self.pagingLayoutAttributes[pagingIndex] as? NSArray else {
            return nil
        }
        
        let attr = attributes.copy() as! [UICollectionViewLayoutAttributes]
        
        return attr
    }
    
    func indexingPaging(attribute:UICollectionViewLayoutAttributes) {
        let frame = attribute.frame
        let pagingIndex = Int(frame.minY / self.pagingHeight)
        
        if self.pagingLayoutAttributes.count > pagingIndex {
            
            if let attributes = self.pagingLayoutAttributes[pagingIndex] as? NSMutableArray {
                attributes.add(attribute)
            }
            return
        }
        
        let attributes : NSMutableArray = []
        attributes.add(attribute)
        self.pagingLayoutAttributes.add(attributes)
    }
    
    func prepareSectionGridLayoutAttribute() {
        
        guard let collectionView = self.collectionView else {
            return
        }
        
        guard let delegate = collectionView.delegate as? CBPatternLayoutDelegate else {
            return
        }
        
        let sectionCount = collectionView.numberOfSections
        
        let sectionWidth = collectionView.bounds.width
        
        for index in 0..<sectionCount {
            
            self.yOffset = self.contentHeight
            
            let indexPath = IndexPath(item: 0, section: index)
            
            let sectionAttr = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: indexPath)
            
            self.sectionLayoutAttributes.append(sectionAttr) // 섹션에 대한 속성을 추가한다
            
            let pattern = delegate.collectionView(collectionView,sectionLayoutInfo:index)
            
            let frame = CGRect(x: 0, y: self.yOffset, width: sectionWidth, height: pattern.sectionHeight)
            
            sectionAttr.alpha = 1
            sectionAttr.frame = frame
            sectionAttr.zIndex = index + 1
            
            self.contentHeight += pattern.sectionHeight
            
            self.prepareGridLayoutAttribute(section: index)
        }
    }
    
    func prepareGridLayoutAttribute(section:Int) {
        
        guard let collectionView = self.collectionView else {
            return
        }
        
        guard let delegate = collectionView.delegate as? CBPatternLayoutDelegate else {
            return
        }
        
        let patternLayout = delegate.collectionView(collectionView, sectionLayoutInfo:section)
        
        if patternLayout.patterns.count == 0 {
            return
        }
        
        let blockSizeX = (collectionView.bounds.width - patternLayout.spacing * CGFloat(patternLayout.column - 1)) / CGFloat(patternLayout.column)
        var blockSizeY = blockSizeX
        
        if patternLayout.fixedHeight > 0 {
            blockSizeY = patternLayout.fixedHeight
        }
        
        let itemCount = collectionView.numberOfItems(inSection: section)
        
        var itemBounds = CGRect.zero
        
        if let previewBounds = self.itemBounds.last {
            itemBounds.origin.y = previewBounds.maxY
        }
        
        let attributes = NSMutableArray()
        let patternCount = patternLayout.patterns.count
        
        for index in 0..<itemCount {
            
            let indexPath = IndexPath(item:index, section:section)
            let itemAttr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            itemAttr.alpha = 1
            attributes.add(itemAttr) // 아이템에 대한 속성을 추가한다
            itemAttr.zIndex = 0
            
            let currentPatternIndex = index % patternCount
            
            if currentPatternIndex == 0 {
                self.yOffset = self.contentHeight
            }
            
            let pattern = patternLayout.patterns[currentPatternIndex]
            
            var frame = CGRect.zero
            frame.origin.x = pattern.minX * (blockSizeX + patternLayout.spacing)
            frame.origin.y = pattern.minY * (blockSizeY + patternLayout.spacing) + self.yOffset
            frame.size.width = pattern.width * blockSizeX + (pattern.width - 1) * patternLayout.spacing
            frame.size.height = pattern.height * blockSizeY + (pattern.height - 1) * patternLayout.spacing
            
            
            itemAttr.frame = frame
            
            self.indexingPaging(attribute: itemAttr)
            
            self.contentHeight = max(self.contentHeight, frame.maxY + patternLayout.spacing)
            
            itemBounds = frame.union(itemBounds)
        }
        
        let attr = attributes.copy() as! [UICollectionViewLayoutAttributes]
        
        self.gridLayoutAttributes.append(attr)
        
        self.itemBounds.append(itemBounds)
    }
}
