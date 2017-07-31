//
//  ViewController.swift
//  GridMaker
//
//  Created by jeongkyu kim on 2017. 7. 26..
//  Copyright © 2017년 jeongkyu kim. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var editorContainer: UIView!
    
    var editorView : CBQuiltEditorView?
    var resultImage : UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let info = CBQuiltEditorInfo()
        
        info.column = 4
        
        var itemLoader = CBQuiltUIImageItemLoader()
        itemLoader.image = UIImage(named: "1")
        itemLoader.imageSize = CGSize(width: 4, height: 1)
        info.loaderList.append(itemLoader)
        
        itemLoader = CBQuiltUIImageItemLoader()
        itemLoader.image = UIImage(named: "2")
        itemLoader.imageSize = CGSize(width: 2, height: 2)
        info.loaderList.append(itemLoader)
        
        itemLoader = CBQuiltUIImageItemLoader()
        itemLoader.image = UIImage(named: "3")
        info.loaderList.append(itemLoader)
        
        itemLoader = CBQuiltUIImageItemLoader()
        itemLoader.image = UIImage(named: "4")
        info.loaderList.append(itemLoader)
        
        itemLoader = CBQuiltUIImageItemLoader()
        itemLoader.image = UIImage(named: "5")
        info.loaderList.append(itemLoader)
        
        itemLoader = CBQuiltUIImageItemLoader()
        itemLoader.image = UIImage(named: "6")
        info.loaderList.append(itemLoader)
        
        itemLoader = CBQuiltUIImageItemLoader()
        itemLoader.image = UIImage(named: "7")
        itemLoader.imageSize = CGSize(width: 4, height: 1)
        info.loaderList.append(itemLoader)
        
        if let editorView = CBQuiltEditorView.createEditorView() {
            
            self.editorContainer.addSubview(editorView)
            
            if info.isValideArea() {
                editorView.reload(editorInfo: info)
            }
            
            self.editorView = editorView
        }
    }
    
    override func viewWillLayoutSubviews() {
         super.viewWillLayoutSubviews()
        
        var rect = CGRect.zero
        rect.size = CGSize(width: self.editorContainer.bounds.width, height: self.editorContainer.bounds.width)
        self.editorView?.frame = rect
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func save(_ sender: Any) {
        
        guard let editorView = self.editorView else { return }
        
        editorView.save(targetSize:1000) { (success, image) in
            self.resultImage = image
            self.performSegue(withIdentifier: "Result", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.destination as? ResultViewController {
            vc.image = self.resultImage
        }
    }
}

