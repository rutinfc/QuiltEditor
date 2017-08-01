//
//  CBQuiltFilter.swift
//  GridMaker
//
//  Created by jeongkyu kim on 2017. 8. 1..
//  Copyright © 2017년 jeongkyu kim. All rights reserved.
//

import UIKit
import GPUImage

enum CBFilterType {
    
    case none, sample1, sample2, sample3, sample4
}

class CBFilterInfo {
    var name : String = ""
    var type : CBFilterType = .none
}

class CBFilterProcess {
    
    var type : CBFilterType = .none
    
    static func createFilter(type:CBFilterType) -> CBFilterProcess? {
    
        var process : CBFilterProcess?
        
        switch type {
        case .none:
            process = CBFilterProcess()
        case .sample1:
            process = CBFilterSample1Process()
        case .sample2:
            process = CBFilterSample2Process()
        case .sample3:
            process = CBFilterSample3Process()
        case .sample4:
            process = CBFilterSample4Process()
        }
        
        process?.type = type
        
        return process
    }
    
    func apply(image:UIImage, complete:@escaping (UIImage?)->Void) {
        
    }
}

fileprivate class CBFilterSample1Process:CBFilterProcess {
    
    override func apply(image:UIImage, complete:@escaping (UIImage?)->Void) {
        
        guard let source = GPUImagePicture(image:image) else {
            complete(nil)
            return
        }
        
        
        DispatchQueue.global().async {
            
            let filter = GPUImageSepiaFilter()
            
            source.addTarget(filter)
            filter.useNextFrameForImageCapture()
            source.processImage()
            let target = filter.imageFromCurrentFramebuffer()
            
            DispatchQueue.main.async {
                complete(target)
            }
        }
    }
}

fileprivate class CBFilterSample2Process:CBFilterProcess {
    
    override func apply(image:UIImage, complete:@escaping (UIImage?)->Void) {
        
        guard let source = GPUImagePicture(image:image) else {
            complete(nil)
            return
        }
        
        
        DispatchQueue.global().async {
            
            guard let url = Bundle.main.url(forResource: "01", withExtension: "acv") else {
                DispatchQueue.main.async {
                    complete(nil)
                }
                return
            }
            
            if let filter = GPUImageToneCurveFilter(acvurl: url) {
                source.addTarget(filter)
                filter.useNextFrameForImageCapture()
                source.processImage()
                let target = filter.imageFromCurrentFramebuffer()
                
                DispatchQueue.main.async {
                    complete(target)
                }
                return
            }
            
            DispatchQueue.main.async {
                complete(nil)
            }
        }
    }
}

fileprivate class CBFilterSample3Process:CBFilterProcess {
    override func apply(image:UIImage, complete:@escaping (UIImage?)->Void) {
        
        guard let source = GPUImagePicture(image:image) else {
            complete(nil)
            return
        }
        
        
        DispatchQueue.global().async {
            
            guard let url = Bundle.main.url(forResource: "02", withExtension: "acv") else {
                DispatchQueue.main.async {
                    complete(nil)
                }
                return
            }
            
            if let filter = GPUImageToneCurveFilter(acvurl: url) {
                source.addTarget(filter)
                filter.useNextFrameForImageCapture()
                source.processImage()
                let target = filter.imageFromCurrentFramebuffer()
                
                DispatchQueue.main.async {
                    complete(target)
                }
                return
            }
            
            DispatchQueue.main.async {
                complete(nil)
            }
        }
    }
}

fileprivate class CBFilterSample4Process:CBFilterProcess {
    override func apply(image:UIImage, complete:@escaping (UIImage?)->Void) {
        
        guard let source = GPUImagePicture(image:image) else {
            complete(nil)
            return
        }
        
        
        DispatchQueue.global().async {
            
            guard let url = Bundle.main.url(forResource: "03", withExtension: "acv") else {
                DispatchQueue.main.async {
                    complete(nil)
                }
                return
            }
            if let filter = GPUImageToneCurveFilter(acvurl: url) {
                source.addTarget(filter)
                filter.useNextFrameForImageCapture()
                source.processImage()
                let target = filter.imageFromCurrentFramebuffer()
                
                DispatchQueue.main.async {
                    complete(target)
                }
                return
            }
            
            DispatchQueue.main.async {
                complete(nil)
            }
        }
    }
}
