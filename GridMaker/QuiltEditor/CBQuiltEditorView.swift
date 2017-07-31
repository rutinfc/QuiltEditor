//
//  CBQuiltEditorView.swift
//  GridMaker
//
//  Created by jeongkyu kim on 2017. 7. 28..
//  Copyright © 2017년 jeongkyu kim. All rights reserved.
//

import UIKit
import ImageIO

@objc class CBQuiltItemLoader : NSObject {
    
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
        
        if (self.cachedImage != nil) {
            image(self.cachedImage!)
            return
        }
        
        image(self.image)
        self.cachedImage = self.image
    }
}

@objc class CBQuiltEditorInfo : NSObject {
    
    var column = 2
    var loaderList = [CBQuiltItemLoader]()
    
    func loader(indexPath:IndexPath) -> CBQuiltItemLoader {
        return self.loaderList[indexPath.item]
    }
    
    func isValideArea() -> Bool {
        
        var totalBlock = self.column * self.column
        
        for loader in self.loaderList {
            
            totalBlock -= loader.blockSize
            
            if (totalBlock < 0) {
                return false
            }
        }
        
        if totalBlock > 0 {
            return false
        }
        
        return true
    }
}

@objc class CBQuiltEditorView: UIView {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var layout : CBQuiltLayout!
    
    var editorInfo : CBQuiltEditorInfo?
    
    static func createEditorView() -> CBQuiltEditorView? {
        
        let views = Bundle.main.loadNibNamed("CBQuiltEditorView", owner: self, options: nil)
        
        if let views = views as? [CBQuiltEditorView] {
            
            for view in views {
                
                if view.restorationIdentifier == "EditorView" {
                    return view
                }
            }
        }
        
        return nil
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        if let layout = self.collectionView.collectionViewLayout as? CBQuiltLayout {
            layout.delegate = self
        }
        let nib = UINib(nibName: "CBQuiltScrollCell", bundle: Bundle.main)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "ScrollCell")
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        self.collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func reload(editorInfo:CBQuiltEditorInfo) {
        
        self.collectionView.layer.borderColor = UIColor.green.cgColor
        self.collectionView.layer.borderWidth = 0.5
        
        self.editorInfo = editorInfo
        self.layout.blockCount = editorInfo.column
        self.collectionView.reloadData()
    }
    
    func save(targetSize:CGFloat, complete:(_ success:Bool, _ image:UIImage?) -> Void) {
        
        for cell in self.collectionView.visibleCells as! [CBQuiltScrollCell] {
            cell.cachedCurrentOffset()
        }
        
        let prevFrame = self.frame
        
        let scale = targetSize / prevFrame.width
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let frame = self.bounds.applying(transform)
        
        self.frame = frame
        
        var image : UIImage?
        
        UIGraphicsBeginImageContextWithOptions(frame.size, true, 2)
        
        self.collectionView.drawHierarchy(in: frame, afterScreenUpdates: true)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if image == nil {
            complete(false, nil)
        } else {
            complete(true, image)
        }
        
        self.frame = prevFrame
    }
}

extension CBQuiltEditorView : UICollectionViewDelegate, UICollectionViewDataSource, CBQuiltLayoutDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let editorInfo = self.editorInfo else { return 0 }
        
        return (editorInfo.loaderList.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScrollCell", for: indexPath)
        
        if let quiltCell = cell as? CBQuiltScrollCell {
            quiltCell.loader = self.editorInfo?.loader(indexPath: indexPath)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView:UICollectionView, layout:UICollectionViewLayout, blockSizeAtIndexPath indexPath:IndexPath) -> CGSize {
        
        guard let editorInfo = self.editorInfo else { return CGSize(width: 1, height: 1) }
        
        let loaderInfo = editorInfo.loaderList[indexPath.item]
        
        return loaderInfo.imageSize
    }

}
