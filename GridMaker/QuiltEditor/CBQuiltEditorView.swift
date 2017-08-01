//
//  CBQuiltEditorView.swift
//  GridMaker
//
//  Created by jeongkyu kim on 2017. 7. 28..
//  Copyright © 2017년 jeongkyu kim. All rights reserved.
//

import UIKit

class CBQuiltEditorInfo : NSObject {
    
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
        
        return true
    }
}

class CBQuiltEditorView: UIView {
    
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
    
    func availableFilters() -> [CBFilterInfo] {
        var list = [CBFilterInfo]()
        var info = CBFilterInfo()
        info.type = .none
        info.name = "초기화"
        list.append(info)
        
        info = CBFilterInfo()
        info.type = .sample1
        info.name = "세피아"
        list.append(info)
        
        info = CBFilterInfo()
        info.type = .sample2
        info.name = "샘플1"
        list.append(info)
        
        info = CBFilterInfo()
        info.type = .sample3
        info.name = "샘플2"
        list.append(info)
        
        info = CBFilterInfo()
        info.type = .sample4
        info.name = "샘플3"
        list.append(info)
        
        return list
    }
    
    func apply(filter:CBFilterInfo, complete:@escaping (Void)->Void) {
        
//        print("START")
        
        DispatchQueue.main.async {
            for cell in self.collectionView.visibleCells as! [CBQuiltScrollCell] {
                cell.applyFilter(info: filter)
            }
            
            complete()
        }
        
//        print("FINISHED")
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
