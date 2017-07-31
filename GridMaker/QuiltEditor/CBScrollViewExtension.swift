//
//  CBScrollViewExtension.swift
//  GridMaker
//
//  Created by jeongkyu kim on 2017. 7. 31..
//  Copyright © 2017년 jeongkyu kim. All rights reserved.
//

import UIKit

extension UIScrollView {
    
    func updateMinZoomScale(contentSize:CGSize, outSize:CGSize) {
        
        let widthScale = outSize.width / contentSize.width
        let heightScale = outSize.height / contentSize.height
        let scale = max(widthScale, heightScale)
        
        self.minimumZoomScale = scale
    }
    
    func scrollRectToVisibleCenter(visibleRect:CGRect, animated:Bool) {
        
        var center = visibleRect.origin
        center.x -= (visibleRect.width / 2)
        center.y -= (visibleRect.height / 2)
        
        var size = visibleRect.size
        size.width *= 2
        
        var rect = CGRect.zero
        rect.origin = center
        rect.size = size
        
        let view = UIView(frame: rect)
        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 0.5
        self.addSubview(view)
        
        self.scrollRectToVisible(rect, animated: animated)
    }
}
