//
//  SignupViewController.swift
//  HowlTalk
//
//  Created by rex on 2018. 8. 7..
//  Copyright © 2018년 ijuyong. All rights reserved.
//

import UIKit
import Firebase

class SignupViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var signup: UIButton!
    @IBOutlet weak var cancel: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    
    let remoteConfig = RemoteConfig.remoteConfig()
    var color : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let statusBar = UIView()
        self.view.addSubview(statusBar)
        statusBar.snp.makeConstraints{ (m) in
            m.right.top.left.equalTo(self.view)
            m.height.equalTo(20)
        }
        
        color = remoteConfig["splash_background"].stringValue
        statusBar.backgroundColor = UIColor(hex: color!)
        
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imagePicker)))
        
        signup.backgroundColor = UIColor(hex: color!)
        cancel.backgroundColor = UIColor(hex: color!)
        
        signup.addTarget(self, action: #selector(signupEvent), for: .touchUpInside)
        cancel.addTarget(self, action: #selector(cancelEvent), for: .touchUpInside)
        
        // Do any additional setup after loading the view.
    }

    @objc func signupEvent(){
        
        Auth.auth().createUser(withEmail: self.email.text!, password: self.password.text!) { (user, error) in
            
            let uid = user?.user.uid
            let image = UIImageJPEGRepresentation(self.imageView.image!, 0.1)
            user?.user.createProfileChangeRequest().displayName = self.name.text!
            user?.user.createProfileChangeRequest().commitChanges(completion: nil)
            
            let reference = Storage.storage().reference().child("userImage").child(uid!)
            reference.putData(image!, metadata: nil, completion: { (metadata, error) in
            
                reference.downloadURL(completion: { (url, error) in
                    
                    let values = ["userName":self.name.text!,
                                  "profileImageUrl":url?.absoluteString,
                                  "uid":Auth.auth().currentUser?.uid]
                    
                    Database.database().reference().child("users").child(uid!).setValue(values, withCompletionBlock: { (err, ref) in
                        if(err==nil) {
                            self.cancelEvent()
                        }
                    })
                })
            })
        }
    }
    
    @objc func imagePicker(){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func cancelEvent() {
        self.dismiss(animated: true, completion: nil)
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
