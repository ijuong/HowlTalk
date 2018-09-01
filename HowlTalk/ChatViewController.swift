//
//  ChatViewController.swift
//  HowlTalk
//
//  Created by rex on 2018. 8. 15..
//  Copyright © 2018년 ijuyong. All rights reserved.
//

import UIKit
import Firebase
import Alamofire
import Kingfisher

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textfield_message: UITextField!
    @IBOutlet weak var tableview: UITableView!
    
    var uid : String?
    var chatRoomUid : String?
    var comments : [ChatModel.Comment] = []
    var destinationUserModel : UserModel?
    
    var databaseRef : DatabaseReference?
    var observe : UInt?
    
    var peopleCount : Int?
    
    public var destinationUid : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        
        checkChatRoom()
        self.tabBarController?.tabBar.isHidden = true
        
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        
        // Do any additional setup after loading the view.
    }

    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationCenter.default.removeObserver(self)
        self.tabBarController?.tabBar.isHidden = false
        
        databaseRef?.removeObserver(withHandle: observe!)
    }
    
    @objc func keyboardWillShow(notification: Notification){
        
        if let keyboardSize = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue{
            self.bottomConstraint.constant = keyboardSize.height
        }
        
        UIView.animate(withDuration: 0, animations: {
            self.view.layoutIfNeeded()
        }, completion: {
            (complete) in
            
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1, section:0), at: UITableViewScrollPosition.bottom, animated: true)
            }
        })
    }
    
    @objc func keyboardWillHide(notification: Notification){
        self.bottomConstraint.constant = 20
        self.view.layoutIfNeeded()
    }
    
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if(self.comments[indexPath.row].uid == uid){
            let view = tableView.dequeueReusableCell(withIdentifier: "MyMessageCell", for : indexPath) as! MyMessageCell
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            setReadCount(label: view.label_read_counter, position: indexPath.row)
            
            return view
            
        }else{
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for : indexPath) as! DestinationMessageCell
            view.label_name.text = destinationUserModel?.userName
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            let url = URL(string: (self.destinationUserModel?.profileImageUrl)!)
           
            view.imageview_profile.layer.cornerRadius = view.imageview_profile.frame.width/2
            view.imageview_profile.clipsToBounds = true
            view.imageview_profile.kf.setImage(with: url)
            /* kingfisher로 변경
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, reponse, err) in
                DispatchQueue.main.async {
                    view.imageview_profile.image = UIImage(data: data!)
                    view.imageview_profile.layer.cornerRadius = view.imageview_profile.frame.width/2
                    view.imageview_profile.clipsToBounds = true
                }
            }).resume()
            */
            if let time = self.comments[indexPath.row].timestamp{
                view.label_timestamp.text = time.toDayTime
            }
            
            setReadCount(label: view.label_read_counter, position: indexPath.row)
            
            return view
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func createRoom(){
        let createRoomInfo : Dictionary<String,Any> = ["users" : [
            uid! : true,
            destinationUid! : true
            ]
        ]
        
        if (chatRoomUid == nil) {
            self.sendButton.isEnabled = false
            
            Database.database().reference().child("chatrooms").childByAutoId().setValue(createRoomInfo, withCompletionBlock :  { (err, ref) in
                if(err == nil){
                    self.checkChatRoom()
                }
            })
        }else{
            let value : Dictionary<String,Any> = [
                "uid" : uid!,
                "message" : textfield_message.text!,
                "timestamp" : ServerValue.timestamp()
            ]
            
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value, withCompletionBlock: {
                (err, ref) in
                self.sendGcm()
                self.textfield_message.text = ""
            })
        }
    }
    
    func sendGcm(){
        
        let url = "https://gcm-http.googleapis.com/gcm/send"
        let header : HTTPHeaders = [
            "Content-Type":"application/json",
            "Authorization":"key=AIzaSyAZiC4wi9zP7zYHCY2F8TpkxEnWVBu9hmc"
        ]
        
        var userName = Auth.auth().currentUser?.displayName
        var notificationModel = NotificationModel()
        notificationModel.to = destinationUserModel?.pushToken
        notificationModel.notification.title = userName
        notificationModel.notification.text = textfield_message.text
        notificationModel.data.title = userName
        notificationModel.data.text = textfield_message.text
        
        let param = notificationModel.toJSON()
        
        Alamofire.request(url, method: .post, parameters: param, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
            print(response.result.value)
        }

        
    }
    
    func checkChatRoom(){
        
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
          
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                
                if let chatRoomdic = item.value as? [String:AnyObject]{
                    
                    let chatModel = ChatModel(JSON: chatRoomdic)
                    if (chatModel?.users[self.destinationUid!]  == true){
                        self.chatRoomUid = item.key
                        self.sendButton.isEnabled = true
                        self.getDestinationInfo()
                    }
                }
                
                
            }
        })
        
    }
    
    func getDestinationInfo(){
        Database.database().reference().child("users").child(self.destinationUid!).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            self.destinationUserModel = UserModel()
            self.destinationUserModel?.setValuesForKeys(datasnapshot.value as! [String:Any])
            self.getMessageList()
        })
    }
    
    func setReadCount(label: UILabel?, position: Int?) {
        
        let readCount = self.comments[position!].readUsers.count
        
        if(peopleCount == nil) {
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("users").observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
                
                let dic = datasnapshot.value as! [String:Any]
                
                self.peopleCount = dic.count
                
                let noReadCount = self.peopleCount! - readCount
                
                if(noReadCount > 0){
                    label?.isHidden = false
                    label?.text = String(noReadCount)
                }else{
                    label?.isHidden = true
                }
            })
        }else{
            let noReadCount = peopleCount! - readCount
            
            if(noReadCount > 0){
                label?.isHidden = false
                label?.text = String(noReadCount)
            }else{
                label?.isHidden = true
            }
        }
        
        
    }
    
    func getMessageList(){
        
        databaseRef = Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments")
        observe = databaseRef?.observe(DataEventType.value, with: { (datasnapshot) in
            self.comments.removeAll()
            
            var readUsersDic : Dictionary<String, AnyObject> = [:]
            
            for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                
                let key = item.key as String
                //print(item.value as! [String:AnyObject])
                let comment = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                let comment_modify = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                comment_modify?.readUsers[self.uid!] = true
                readUsersDic[key] = comment_modify?.toJSON() as! NSDictionary
                
                self.comments.append(comment!)
            }
            
            let nsDic = readUsersDic as NSDictionary
            
            if(!(self.comments.last?.readUsers.keys.contains(self.uid!))!) {
                datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                    self.tableview.reloadData()
                    
                    if self.comments.count > 0 {
                        self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1, section:0), at: UITableViewScrollPosition.bottom, animated: true)
                    }
                })
            }else{
                self.tableview.reloadData()
                
                if self.comments.count > 0 {
                    self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1, section:0), at: UITableViewScrollPosition.bottom, animated: true)
                }
            }
            
            
        })
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

extension Int {
    var toDayTime : String {
        let dateFomatter = DateFormatter()
        dateFomatter.locale = Locale(identifier: "ko_KR")
        dateFomatter.dateFormat = "yyyy.MM.dd HH:mm"
        
        let date = Date(timeIntervalSince1970: Double(self)/1000)
        
        return dateFomatter.string(from: date)
    }
        
}

class MyMessageCell : UITableViewCell{
    @IBOutlet weak var label_message: UILabel!
    @IBOutlet weak var label_timestamp: UILabel!
    @IBOutlet weak var label_read_counter: UILabel!
    
}

class DestinationMessageCell : UITableViewCell{
    @IBOutlet weak var label_message: UILabel!
    @IBOutlet weak var imageview_profile: UIImageView!
    @IBOutlet weak var label_name: UILabel!
    @IBOutlet weak var label_timestamp: UILabel!
    @IBOutlet weak var label_read_counter: UILabel!
    
}
