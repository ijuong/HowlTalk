//
//  ChatRoomsViewController.swift
//  HowlTalk
//
//  Created by rex on 2018. 8. 21..
//  Copyright © 2018년 ijuyong. All rights reserved.
//

import UIKit
import Firebase
import Kingfisher

class ChatRoomsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableview: UITableView!
    var uid : String!
    var chatrooms : [ChatModel]! = []
    var keys : [String] = []
    var destinationUsers : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.uid = Auth.auth().currentUser?.uid
        
        self.getChatroomList()
        
        // Do any additional setup after loading the view.
    }
    
    func getChatroomList(){
        
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
                for item in datasnapshot.children.allObjects as! [DataSnapshot]{
                
                    if let chatroomdic = item.value as? [String:AnyObject]{
                        let chatmodel = ChatModel(JSON: chatroomdic)
                        self.keys.append(item.key)
                        self.chatrooms.append(chatmodel!)
                    }
                }
            
                self.tableview.reloadData()
            })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatrooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "RowCell", for: indexPath) as! CustomCell
        
        var destinationUid : String?
        print("aaaaaaaaaaaa")
        for item in chatrooms[indexPath.row].users{
            if(item.key != self.uid){
                destinationUid = item.key
                destinationUsers.append(destinationUid!)
                print(item.key)
            }
        }
        
        Database.database().reference().child("users").child(destinationUid!).observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
            
            let userModel = UserModel()
            userModel.setValuesForKeys(datasnapshot.value as! [String:AnyObject])
            
            cell.label_title.text = userModel.userName
            
            let url = URL(string: userModel.profileImageUrl!)
            cell.imageview.layer.cornerRadius = cell.imageview.frame.width/2
            cell.imageview.layer.masksToBounds = true
            cell.imageview.kf.setImage(with: url)
            
            if(self.chatrooms[indexPath.row].comments.keys.count == 0) {
                return
            }
            
            /* kingfisher
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
                DispatchQueue.main.sync {
                    cell.imageview.image = UIImage(data: data!)
                    cell.imageview.layer.cornerRadius = cell.imageview.frame.width/2
                    cell.imageview.layer.masksToBounds = true
                }
            }).resume()
            */
            let lastMessageKey = self.chatrooms[indexPath.row].comments.keys.sorted(){$0>$1}
            cell.label_lastmessage.text = self.chatrooms[indexPath.row].comments[lastMessageKey[0]]?.message
            
            let unixTime = self.chatrooms[indexPath.row].comments[lastMessageKey[0]]?.timestamp
            cell.label_timestamp.text = unixTime?.toDayTime
            
        })
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        print("indexPath.row")
        print(indexPath.row)
        print(chatrooms[indexPath.row].users.count)
        //if(self.destinationUsers.count > 2) {
        if(chatrooms[indexPath.row].users.count > 2){
            let destinationUid = self.destinationUsers[indexPath.row]
            
            let view = self.storyboard?.instantiateViewController(withIdentifier: "GroupChatRoomViewController") as! GroupChatRoomViewController
            view.destinationRoom = self.keys[indexPath.row]
            
            self.navigationController?.pushViewController(view, animated: true)
            
            print("11111111111")
        }else{
            let destinationUid = self.destinationUsers[indexPath.row]
            
            let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
            view.destinationUid = destinationUid
            
            self.navigationController?.pushViewController(view, animated: true)
            
            print("222222222")
        }
        
       
        
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

class CustomCell : UITableViewCell {

    @IBOutlet weak var label_lastmessage: UILabel!
    
    @IBOutlet weak var imageview: UIImageView!
    
    @IBOutlet weak var label_title: UILabel!

    @IBOutlet weak var label_timestamp: UILabel!
}
