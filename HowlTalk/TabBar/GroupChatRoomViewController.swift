//
//  GroupChatRoomViewController.swift
//  HowlTalk
//
//  Created by Juyong Lee on 2018. 9. 4..
//  Copyright © 2018년 ijuyong. All rights reserved.
//

import UIKit
import Firebase

class GroupChatRoomViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    

    @IBOutlet weak var button_send: UIButton!
    @IBOutlet weak var textfield_message: UITextField!
    @IBOutlet weak var tableview: UITableView!
    
    var destinationRoom : String?
    var uid : String?
    
    var databaseRef : DatabaseReference?
    var observe : UInt?
    
    var comments : [ChatModel.Comment] = []
    var users : [String:AnyObject]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uid = Auth.auth().currentUser?.uid
        
        Database.database().reference().child("users").observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            
            self.users = datasnapshot.value as! [String:AnyObject]
        })

        button_send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        getMessageList()
        
        // Do any additional setup after loading the view.
    }
    
    @objc func sendMessage(){
        
        let value : Dictionary<String, Any> = [
            "uid" : uid!,
            "message" : textfield_message.text!,
            "timestamp" : ServerValue.timestamp()
        ]
        
        Database.database().reference().child("chatrooms").child(destinationRoom!).child("comment").childByAutoId().setValue(value) { (err, ref) in
            self.textfield_message.text = ""
        }
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
            
            //setReadCount(label: view.label_read_counter, position: indexPath.row)
            
            return view
            
        }else{
            let destinationUser = users![self.comments[indexPath.row].uid]
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for : indexPath) as! DestinationMessageCell
            view.label_name.text = destinationUser!["userName"] as! String
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            let imageUrl = destinationUser!["profileImageUrl"] as! String
            let url = URL(string: (imageUrl))
            
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
            
            //setReadCount(label: view.label_read_counter, position: indexPath.row)
            
            return view
        }
        
        return UITableViewCell()
    }
    
    func getMessageList(){
        print("getMessageList")
        print(self.destinationRoom!)
        
        databaseRef = Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("comments")
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
            
            if(self.comments.last?.readUsers.keys == nil){
                return
            }
            
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
