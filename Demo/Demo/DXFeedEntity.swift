//
//  DXFeedEntity.swift
//  UITableView-DXTemplateLayoutCell
//
//  Created by dhcdht on 15/6/9.
//  Copyright (c) 2015年 dhcdht. All rights reserved.
//

import UIKit

class DXFeedEntity: NSObject {
    
    var title: String
    var content: String
    var username: String
    var time: String
    var imageName: String
    
    init(dictionary: NSDictionary) {
        self.title = dictionary["title"] as! String
        self.content = dictionary["content"] as! String
        self.username = dictionary["username"] as! String
        self.time = dictionary["time"] as! String
        self.imageName = dictionary["imageName"] as! String
    }
}
