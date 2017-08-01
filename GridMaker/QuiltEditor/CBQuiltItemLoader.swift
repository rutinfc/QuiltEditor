//
//  CBQuiltItemLoader.swift
//  GridMaker
//
//  Created by jeongkyu kim on 2017. 8. 1..
//  Copyright © 2017년 jeongkyu kim. All rights reserved.
//

import UIKit
import ImageIO

class CBQuiltItemLoader {
    
    private var faceAllBounds : CGRect = CGRect.zero
    fileprivate var cachedImage : UIImage?
    
    var imageSize : CGSize = CGSize(width: 1, height: 1)
    var blockSize : Int {
        return Int(self.imageSize.width * self.imageSize.height)
    }
    
    func detectingFace(scale:CGFloat, frame:CGRect, complete:@escaping (CGRect)->Void) {
        
        if self.faceAllBounds.equalTo(CGRect.zero) == false {
            complete(self.faceAllBounds)
            return
        }
        
        DispatchQueue.global().async {
            
            self.load(image: { (image) in
                
                guard let image = image else { return }
                guard let cgImage = image.cgImage else { return }
                let ciImage = CIImage(cgImage: cgImage)
                
                guard let detector = CIDetector(ofType:CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]) else {
                    return
                }
                
                var fatures: [CIFaceFeature]!
                if let orientation = ciImage.properties[kCGImagePropertyOrientation as String] {
                    fatures = detector.features(in: ciImage, options: [CIDetectorImageOrientation: orientation]) as! [CIFaceFeature]
                } else {
                    fatures = detector.features(in: ciImage)as! [CIFaceFeature]
                }
                
                var featureBounds = CGRect.zero
                
                for faceFeature in fatures {
                    
                    let faceViewBounds = faceFeature.bounds
                    
                    if featureBounds.equalTo(CGRect.zero) {
                        featureBounds = faceViewBounds
                    } else {
                        featureBounds = featureBounds.union(faceViewBounds)
                    }
                }
                
                if featureBounds.equalTo(CGRect.zero) == true {
                    
                    DispatchQueue.main.async {
                        complete(CGRect.zero)
                    }
                    return
                }
                
                let inputImageSize = ciImage.extent.size
                
                var transform = CGAffineTransform(scaleX: 1, y: -1)
                transform = transform.translatedBy(x: 0, y: -inputImageSize.height)
                
                self.faceAllBounds = featureBounds.applying(transform)
                
                self.faceAllBounds = self.faceAllBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
                self.faceAllBounds.origin.x += frame.origin.x
                self.faceAllBounds.origin.y += frame.origin.y
                
                DispatchQueue.main.async {
                    complete(self.faceAllBounds)
                }
            })
        }
    }
    
    func load(image:(UIImage?)->Void) {
        
    }
}

class CBQuiltUIImageItemLoader : CBQuiltItemLoader {
    
    var image : UIImage?
    
    override func load(image:(UIImage?)->Void) {
        
        if let cachedImage = self.cachedImage {
            image(cachedImage)
            return
        }
        
        image(self.image)
        self.cachedImage = self.image
    }
}
