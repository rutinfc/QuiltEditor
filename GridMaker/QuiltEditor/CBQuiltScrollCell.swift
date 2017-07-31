//
//  CBQuiltScrollCell.swift
//  GridMaker
//
//  Created by jeongkyu kim on 2017. 7. 28..
//  Copyright © 2017년 jeongkyu kim. All rights reserved.
//

import UIKit
import ImageIO

class CBQuiltScrollCell: UICollectionViewCell, UIScrollViewDelegate {

    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var prevPosition : CGPoint?
    var prevDiffScale : CGFloat?
    var detectingFace : Bool = false
    
    var loader:CBQuiltItemLoader? {
        
        didSet {
            
            guard let loader = self.loader else {
                return;
            }
            
            loader.load { (image) in
                
                self.imageView.image = image
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let image = self.imageView.image {
            
            self.scrollView.updateMinZoomScale(contentSize:image.size, outSize: self.contentView.bounds.size)
            self.scrollView.maximumZoomScale = self.scrollView.minimumZoomScale * 2
            self.scrollView.zoomScale = self.scrollView.minimumZoomScale
        }
        
        if (self.detectingFace == false) {
            
            self.loader?.detectingFace(scale: self.scrollView.zoomScale, frame: self.imageView.frame, complete: { (faceBounds) in
                
                if faceBounds.equalTo(CGRect.zero) == false {
                    let view = UIView(frame: faceBounds)
                    view.layer.borderColor = UIColor.red.cgColor
                    view.layer.borderWidth = 0.5
                    self.scrollView.addSubview(view)
                    self.scrollView.scrollRectToVisibleCenter(visibleRect:faceBounds, animated: false)
                }
                
                self.detectingFace = true
            })
            
        } else {
            
            self.restoreContentOffset()
        }
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        self.title.text = String(describing: layoutAttributes.indexPath)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        self.updateConstraints(viewSize:self.contentView.bounds.size)
    }
    
    func restoreContentOffset() {
        
        if let prevPosition = self.prevPosition {
            
            if let prevDiffScale = self.prevDiffScale {
                
                if prevDiffScale != 1 {
                    self.scrollView.zoomScale *= prevDiffScale
                    print(prevDiffScale)
                }
            }
            
            var offset = prevPosition
            offset.x *= self.scrollView.zoomScale
            offset.y *= self.scrollView.zoomScale
            self.scrollView.contentOffset = offset
            
        }
    }
    
    func cachedCurrentOffset() {
        
        var offset = scrollView.contentOffset
        offset.x /= scrollView.zoomScale
        offset.y /= scrollView.zoomScale
        
        self.prevDiffScale = scrollView.zoomScale / scrollView.minimumZoomScale
        
        self.prevPosition = offset
        self.detectingFace = true
        
//        print("CACHED : \(String(describing: self.title.text)) | \(scrollView.contentOffset) | \(scrollView.zoomScale) -> \(offset) | \(String(describing: self.prevDiffScale))")
    }
    
    fileprivate func updateConstraints(viewSize:CGSize) {
        
        guard let image = self.imageView.image else { return }
        
        let imageSize = image.size
        
        var hPadding = (viewSize.width - self.scrollView.zoomScale * imageSize.width) / 2
        if hPadding < 0 {
            hPadding = 0
        }
        
        var vPadding = (viewSize.height - self.scrollView.zoomScale * imageSize.height) / 2
        if vPadding < 0 {
            vPadding = 0
        }
        
        self.topConstraint.constant = vPadding
        self.bottomConstraint.constant = vPadding
        
        self.leadingConstraint.constant = hPadding
        self.trailingConstraint.constant = hPadding

        self.contentView.layoutIfNeeded()
    }
}

