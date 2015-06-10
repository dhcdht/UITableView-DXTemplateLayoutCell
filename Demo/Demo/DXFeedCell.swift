//
//  DXFeedCell.swift
//  UITableView-DXTemplateLayoutCell
//
//  Created by dhcdht on 15/6/9.
//  Copyright (c) 2015年 dhcdht. All rights reserved.
//

import UIKit

class DXFeedCell : UITableViewCell {
    var entity: DXFeedEntity? {
        set {
            if let value = newValue {
                
                self.titleLabel?.text = value.title
                self.contentLabel?.text = value.content
                var length = value.imageName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
                self.contentImageView?.image = length > 0 ? UIImage(named: value.imageName) : nil
                self.usernameLabel?.text = value.username
                self.timeLabel?.text = value.time
                
            } else {
                _entity = nil;
            }
        }
        
        get {
            return _entity!
        }
    }
    var _entity: DXFeedEntity?
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var contentLabel: UILabel?
    @IBOutlet weak var contentImageView: UIImageView?
    @IBOutlet weak var usernameLabel: UILabel?
    @IBOutlet weak var timeLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentView.bounds = UIScreen.mainScreen().bounds
    }
}
