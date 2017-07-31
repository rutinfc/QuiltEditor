//
//  ResultViewController.swift
//  GridMaker
//
//  Created by jeongkyu kim on 2017. 7. 31..
//  Copyright © 2017년 jeongkyu kim. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {
    
    var image:UIImage?
    @IBOutlet weak var size: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.imageView.image = self.image
        self.size.text = "\(String(describing: self.image?.size))"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
