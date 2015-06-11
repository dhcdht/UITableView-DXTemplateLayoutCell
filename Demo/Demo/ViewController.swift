//
//  ViewController.swift
//  UITableView-DXTemplateLayoutCell
//
//  Created by dhcdht on 15/6/7.
//  Copyright (c) 2015年 dhcdht. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, UIActionSheetDelegate {
    
    var cellHeightCacheEnabled: Bool?
    var prototypeEntitiesFromJSON: NSArray?
    var feedEntitySections: NSMutableArray?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tableView.dx_debuglogEnabled = true;
        
        self.cellHeightCacheEnabled = true;
        
        self.buildTestDataThen { () -> Void in
            self.feedEntitySections = NSMutableArray()
            self.feedEntitySections?.addObject(self.prototypeEntitiesFromJSON!)
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func buildTestDataThen(then: () -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            var dataFilePath = NSBundle.mainBundle().pathForResource("data", ofType: "json")
            var data = NSData.dataWithContentsOfMappedFile(dataFilePath!) as! NSData
            var rootDic = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as? NSDictionary
            
            var entities = NSMutableArray()
            var feedDics = rootDic?.objectForKey("feed") as? NSArray
            feedDics?.enumerateObjectsUsingBlock({ (obj, index, stop) -> Void in
                var dic = obj as! NSDictionary
                var entity = DXFeedEntity(dictionary: dic)
                entities.addObject(entity)
            })
            self.prototypeEntitiesFromJSON = entities
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                then()
            })
        })
    }
    
    //MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count = self.feedEntitySections?.count
        
        if let notNilCount = count {
            return notNilCount
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var value = self.feedEntitySections?.objectAtIndex(section) as! NSArray
        return value.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: DXFeedCell = tableView.dequeueReusableCellWithIdentifier("DXFeedCell", forIndexPath: indexPath) as! DXFeedCell
 
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: DXFeedCell, atIndexPath: NSIndexPath) -> Void {
        cell.dx_enforceFrameLayout = false;
        if (atIndexPath.row % 2 == 0) {
            cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        var value = self.feedEntitySections?.objectAtIndex(atIndexPath.section).objectAtIndex(atIndexPath.row) as? DXFeedEntity
        cell.entity = value
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var value: CGFloat
        if (self.cellHeightCacheEnabled!) {
            value = tableView.dx_heightForCell("DXFeedCell", cacheByIndexPath: indexPath) { (cell) -> Void in
                var dxCell: DXFeedCell = cell as! DXFeedCell
                self.configureCell(dxCell, atIndexPath: indexPath)
            }
        } else {
            value = tableView.dx_heightForCell("DXFeedCell", configuration: { (cell) -> Void in
                var dxCell: DXFeedCell = cell as! DXFeedCell
                self.configureCell(dxCell, atIndexPath: indexPath)
            })
        }
        
        return value
    }
    
    @IBAction func refreshControlAction(sender: UIRefreshControl) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * NSEC_PER_SEC)), dispatch_get_main_queue()) { () -> Void in
            self.feedEntitySections?.removeAllObjects()
            self.feedEntitySections?.addObject(self.prototypeEntitiesFromJSON!)
            self.tableView.reloadData()
            sender.endRefreshing()
        }
    }
    
    @IBAction func leftSwitchAction() {
        if let value = self.cellHeightCacheEnabled {
            self.cellHeightCacheEnabled = !value
        } else {
            self.cellHeightCacheEnabled = true
        }
    }
    
    @IBAction func rightNavigationItemAction() {
        var actionSheet = UIActionSheet(title: "Actions", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Insert a row", "Insert a section", "Delete a section")
        
        actionSheet.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        //TODO:
        var selectors = [
            "insertRow",
            "insertSection",
            "deleteSection",
        ]
        
        var index = buttonIndex-1;
        if (index < selectors.count) {
            var sel: Selector = Selector(selectors[index])
            NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: sel, userInfo: nil, repeats: false)
        }
    }
    
    func randomEntity() -> DXFeedEntity? {
        var count: Int
        if let jsonArray = self.prototypeEntitiesFromJSON {
            count = jsonArray.count
            var randomNumber = arc4random_uniform(UInt32(count))
            var randomEntity = jsonArray[Int(randomNumber)] as! DXFeedEntity
            
            return randomEntity
        }
        
        return nil
    }
    
    func insertRow() {
        if (self.feedEntitySections?.count == 0) {
            self.feedEntitySections?.addObject(NSMutableArray())
        }
        
        var entity = self.randomEntity()
        if let notNilEntity = entity {
            self.tableView.beginUpdates()
            var arr = self.feedEntitySections?.objectAtIndex(0) as! NSMutableArray
            arr.insertObject(notNilEntity, atIndex: 0)
            var indexPath = NSIndexPath(forItem: 0, inSection: 0)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
        }
    }
    
    func insertSection() {
        var entity = self.randomEntity()
        if let notNilEntity = entity {
            self.tableView.beginUpdates()
            self.feedEntitySections?.insertObject([notNilEntity], atIndex: 0)
            self.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
        }
    }
    
    func deleteSection() {
        if (self.feedEntitySections?.count > 0) {
            self.tableView.beginUpdates()
            self.feedEntitySections?.removeObjectAtIndex(0)
            self.tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
        }
    }
}

