//
//  CBStoryPreviewGridLayout.swift
//  Cloud
//
//  Created by jeongkyu kim on 2018. 2. 21..
//  Copyright © 2018년 skt. All rights reserved.
//

import UIKit

class CBStoryPreviewGridLayout : UICollectionViewLayout {
    
    var column : Int {
        didSet {
            self.patterns.removeAll()
            for index in 0..<self.column {
                self.patterns.append(CGRect(x: index, y: 0, width: 1, height: 1))
            }
        }
    }
    
    var sectionHeight : CGFloat {
        didSet {
            self.dirty = true
            self.invalidateLayout()
        }
    }
    
    var spacing : CGFloat {
        didSet {
            self.dirty = true
            self.invalidateLayout()
        }
    }
    
    var isStickyHeader : Bool = true
    
    private var contentSize : CGSize = CGSize.zero
    private var contentHeight : CGFloat = 0
    private var yOffset : CGFloat = 0
    private var blockSize : CGFloat = 0
    
    private var dirty : Bool = true
    private var pagingHeight : CGFloat = 300
    
    private var patterns : [CGRect] = [CGRect]()
    private var itemBounds : [CGRect] = [CGRect]()
    
    private var previousLayoutRect : CGRect = CGRect.zero
    private var previousLayoutAttributes = [UICollectionViewLayoutAttributes]()
    private var gridLayoutAttributes = [[UICollectionViewLayoutAttributes]]()
    private var sectionLayoutAttributes = [UICollectionViewLayoutAttributes]()
    private var pagingLayoutAttributes = [Int : [UICollectionViewLayoutAttributes]]()

    override var collectionViewContentSize: CGSize {
        return self.contentSize
    }
    
    override init() {
        self.sectionHeight = 20
        self.column = 4
        self.spacing = 2
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.sectionHeight = 20
        self.column = 4
        self.spacing = 2
        super.init(coder:aDecoder)
        
        for index in 0..<self.column {
            self.patterns.append(CGRect(x:CGFloat(index), y:0, width:1, height:1))
        }
    }
    
    override func prepare() {
        super.prepare()
        
        self.prepareLayoutAttribute()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        if self.isStickyHeader == false && self.previousLayoutRect.equalTo(rect) == true {
            return self.previousLayoutAttributes
        }
        
        self.previousLayoutRect = rect
        self.previousLayoutAttributes.removeAll()
        
        var current = rect.minY
        
        if current < 0 {
            current = 0
        }
        
        repeat {
            
            let pagingIndex = Int(current / self.pagingHeight)
            
            guard let attributes = self.pagingLayoutAttributes[pagingIndex] else {
                break
            }
            
            self.previousLayoutAttributes.append(contentsOf: attributes)
            
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
        return self.gridLayoutAttributes[indexPath.section][indexPath.item]
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        guard let collectionView = self.collectionView else {
            return nil
        }
        
        if elementKind == UICollectionElementKindSectionHeader {
            
            if self.isStickyHeader == false {
                return self.sectionLayoutAttributes[indexPath.section]
            }
            
            let attribute = self.sectionLayoutAttributes[indexPath.section]
            
            let boundaries = self.itemBounds[indexPath.section]
            
            print("<----- SECTION | \(indexPath.section) | \(boundaries)")
            
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
        
        if self.isStickyHeader == true {
            
            return true
        }
        
        guard let collectionView = self.collectionView else {
            return false
        }
        
        return (collectionView.frame.size.equalTo(newBounds.size) == false)
    }
    
    func clearPattern() {
        self.patterns.removeAll()
    }
    
    func addPatern(rect:CGRect) {
        self.patterns.append(rect)
    }
}

private extension CBStoryPreviewGridLayout {
    
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
        
        self.gridLayoutAttributes.removeAll()
        self.sectionLayoutAttributes.removeAll()
        self.pagingLayoutAttributes.removeAll()
        self.itemBounds.removeAll()
        
        self.contentHeight = 2
        self.yOffset = 0

        guard let collectionView = self.collectionView else {
            return
        }
        
        self.pagingHeight = collectionView.bounds.height
        
        let width = collectionView.bounds.width
        
        self.blockSize = (width - self.spacing * CGFloat(self.column - 1)) / CGFloat(self.column)
        
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
    
    func indexingPaging(attribute:UICollectionViewLayoutAttributes) {
        let frame = attribute.frame
        let pagingIndex = Int(frame.minY / self.pagingHeight)
        
        var attributes = self.pagingLayoutAttributes[pagingIndex]
        if attributes == nil {
            attributes = [UICollectionViewLayoutAttributes]()
        }
        
        attributes?.append(attribute)
        self.pagingLayoutAttributes[pagingIndex] = attributes
    }
    
    func prepareSectionGridLayoutAttribute() {
        
        guard let collectionView = self.collectionView else {
            return
        }
        
        let sectionCount = collectionView.numberOfSections
        
        let sectionWidth = collectionView.bounds.width
        
        for index in 0..<sectionCount {
            
            self.yOffset = self.contentHeight
            
            let indexPath = IndexPath(item: 0, section: index)
            
            let sectionAttr = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: indexPath)
            
            self.sectionLayoutAttributes.append(sectionAttr) // 섹션에 대한 속성을 추가한다
            
            let frame = CGRect(x: 0, y: self.yOffset, width: sectionWidth, height: self.sectionHeight)
            
            sectionAttr.frame = frame
            sectionAttr.zIndex = index + 1
            
            self.contentHeight += self.sectionHeight
            
            self.prepareGridLayoutAttribute(section: index)
        }
    }
    
    func prepareGridLayoutAttribute(section:Int) {
        
        guard let collectionView = self.collectionView else {
            return
        }
        
        if self.patterns.count == 0 {
            return
        }
        
        let itemCount = collectionView.numberOfItems(inSection: section)
        
        var itemBounds = CGRect.zero
        
        if let previewBounds = self.itemBounds.last {
            itemBounds.origin.y = previewBounds.maxY
        }
        
        var attributes = [UICollectionViewLayoutAttributes]()
        
        for index in 0..<itemCount {
            
            let indexPath = IndexPath(item:index, section:section)
            
            let itemAttr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            
            attributes.append(itemAttr) // 아이템에 대한 속성을 추가한다
            itemAttr.zIndex = 0
            
            let currentPatternIndex = index % self.patterns.count
            
            if currentPatternIndex == 0 {
                self.yOffset = self.contentHeight
            }
            
            let pattern = self.patterns[currentPatternIndex]
            
            var frame = CGRect.zero
            frame.origin.x = pattern.minX * (self.blockSize + self.spacing)
            frame.origin.y = pattern.minY * (self.blockSize + self.spacing) + self.yOffset
            frame.size.width = pattern.width * self.blockSize + (pattern.width - 1) * self.spacing
            frame.size.height = pattern.height * self.blockSize + (pattern.height - 1) * self.spacing
            
            itemAttr.frame = frame
            
            self.indexingPaging(attribute: itemAttr)
            
            self.contentHeight = max(self.contentHeight, frame.maxY + self.spacing)
            
            itemBounds = frame.union(itemBounds)
        }
        
        self.gridLayoutAttributes.append(attributes)
        
        self.itemBounds.append(itemBounds)
    }
}
