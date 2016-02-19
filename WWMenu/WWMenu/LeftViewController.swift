//
//  LeftViewController.swift
//  WWMenu
//
//  Created by 吴申超 on 16/2/19.
//  Copyright © 2016年 吴申超. All rights reserved.
//

import UIKit

class LeftViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "left"

    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let app = UIApplication.sharedApplication().delegate as! AppDelegate
        app.menuController?.showRootController(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}