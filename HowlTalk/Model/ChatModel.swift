//
//  ChatModel.swift
//  HowlTalk
//
//  Created by rex on 2018. 8. 15..
//  Copyright © 2018년 ijuyong. All rights reserved.
//

import ObjectMapper

class ChatModel: Mappable {
    
    public var users : Dictionary<String, Bool> = [:]
    public var comments : Dictionary<String, Comment> = [:]
    
    required init?(map: Map) {
    }
    
    func mapping(map: Map) {
        users <- map["users"]
        comments <- map["comments"]
    }
    
    public class Comment : Mappable{
        @objc public var uid : String!
        @objc public var message : String!
        public var timestamp : Int!
        public required init?(map: Map) {
        }
        public func mapping(map: Map) {
            uid <- map["uid"]
            message <- map["message"]
            timestamp <- map["timestamp"]
        }
    }
}
