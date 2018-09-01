//
//  AccountViewController.swift
//  HowlTalk
//
//  Created by Juyong Lee on 2018. 8. 28..
//  Copyright © 2018년 ijuyong. All rights reserved.
//

import UIKit
import Firebase

class AccountViewController: UIViewController {

    @IBOutlet weak var conditionsCommentButton: UIButton!
    @IBOutlet weak var myComment: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        conditionsCommentButton.addTarget(self, action: #selector(showAlert), for: .touchUpInside)
        
        let uid = Auth.auth().currentUser?.uid
        
        Database.database().reference().child("users").child(uid!).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
        
            let userModel = UserModel()
            userModel.setValuesForKeys(datasnapshot.value as! [String:AnyObject])
            
            self.myComment.text = userModel.comment
        })

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func showAlert(){
        
        let alertController  = UIAlertController(title: "상태 메세지", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addTextField { (textfield) in
            textfield.placeholder = "상태메세지를 입력해주세요"
        }
        
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            
            if let textfield = alertController.textFields?.first{
                let dic = ["comment": textfield.text!]
                let uid = Auth.auth().currentUser?.uid
                Database.database().reference().child("users").child(uid!).updateChildValues(dic)
                
                self.myComment.text = textfield.text!
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { (action) in
            
        }))
        
        self.present(alertController, animated: true, completion: nil)
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
