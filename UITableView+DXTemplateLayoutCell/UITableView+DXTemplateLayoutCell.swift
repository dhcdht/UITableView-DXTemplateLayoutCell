//
//  UITableView+DXTemplateLayoutCell.swift
//  UITableView-DXTemplateLayoutCell
//
//  Created by dhcdht on 15/6/7.
//  Copyright (c) 2015年 dhcdht. All rights reserved.
//

import UIKit

extension UITableView {
    
    //MARK: Private Defines
    
    private struct AssociatedKey {
        static var dx_debuglogEnabled_key = "dx_debuglogEnabled_key"
        
        static var dx_templateCellsByIdentifiers_key = "dx_templateCellsByIdentifiers_key"
        
        static var dx_autoCacheInvalidationEnabled_key = "dx_autoCacheInvalidationEnabled_key"
        static var dx_precacheEnabled_key = "dx_precacheEnabled_key"
        
        static var dx_cellHeightCache_key = "dx_cellHeightCache_key"
    }
    
    //MARK: Public Methods
    
    func dx_heightForCell(identifier: String, configuration: ((cell: UITableViewCell) -> Void)?) -> CGFloat {
        
        if (identifier.isEmpty) {
            return 0;
        }
        
        var templatecCell = self.dx_templateCell(identifier)
        if let cell = templatecCell {
            cell.prepareForReuse()
            
            if let notNilConfiguration = configuration {
                notNilConfiguration(cell: cell)
            }
            
            var contentViewWidth = CGRectGetWidth(self.bounds)
            
            // If a cell has accessory view or system accessory type, its content view's width is smaller
            // than cell's by some fixed value.
            if let notNilAccessoryView = cell.accessoryView {
                contentViewWidth -= 16 + CGRectGetWidth(notNilAccessoryView.bounds)
            } else {
                switch (cell.accessoryType) {
                case .None:
                    contentViewWidth -= 0
                case .DisclosureIndicator:
                    contentViewWidth -= 34
                case .DetailDisclosureButton:
                    contentViewWidth -= 68
                case .Checkmark:
                    contentViewWidth -= 40
                case .DetailButton:
                    contentViewWidth -= 48
                }
            }
            
            var fittingSize = CGSizeZero
            
            // If auto layout enabled, cell's contentView must have some constraints.
            var autoLayoutEnabled = false
            if (cell.contentView.constraints().count > 0) {
                if let enforceFrameLayout = cell.dx_enforceFrameLayout {
                    autoLayoutEnabled = !enforceFrameLayout
                } else {
                    autoLayoutEnabled = true
                }
            }
            
            if (autoLayoutEnabled) {
                // Add a hard width constraint to make dynamic content views (like labels) expand vertically instead
                // of growing horizontally, in a flow-layout manner.
                var tempWidthConstraint = NSLayoutConstraint(item: cell.contentView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: contentViewWidth)
                cell.contentView.addConstraint(tempWidthConstraint)
                fittingSize = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
                cell.contentView.removeConstraint(tempWidthConstraint)
            } else {
                // If not using auto layout, you have to override "-sizeThatFits:" to provide a fitting size by yourself.
                // This is the same method used in iOS8 self-sizing cell's implementation.
                // Note: fitting height should not include separator view.
                var selector = Selector("sizeThatFits:")
                var inherited = !cell.isMemberOfClass(UITableViewCell)
                var overrided = cell.dynamicType.instanceMethodForSelector(selector) != UITableViewCell.instanceMethodForSelector(selector)
                if (inherited && !overrided) {
                    assert(false, "Customized cell must override '-sizeThatFits:' method if not using auto layout.")
                }
                fittingSize = cell.sizeThatFits(CGSizeMake(contentViewWidth, 0))
            }
            
            // Add 1px extra space for separator line if needed, simulating default UITableViewCell.
            if (self.separatorStyle != UITableViewCellSeparatorStyle.None) {
                fittingSize.height += 1.0/UIScreen.mainScreen().scale
            }
            
            if (autoLayoutEnabled) {
                self.dx_debugLog("calculate using auto layout - \(fittingSize.height)")
            } else {
                self.dx_debugLog("calculate using frame layout - \(fittingSize.height)")
            }
            
            return fittingSize.height
        }
        
        return 0
    }
    
    func dx_heightForCell(identifier: String, cacheByIndexPath: NSIndexPath, configuration: ((cell: UITableViewCell) -> Void)?) -> CGFloat {
        
        if (identifier.isEmpty) {
            return 0
        }
        
        // Enable auto cache invalidation if you use this "cacheByIndexPath" API.
        self.dx_autoCacheInvalidationEnabled = true
        
        // Enable precache if you use this "cacheByIndexPath" API.
        if (nil == self.dx_precacheEnabled || !self.dx_precacheEnabled!) {
            self.dx_precacheEnabled = true
            
            // Manually trigger precache only for the first time.
            self.dx_precacheIfNeed()
        }
        
        // Check cache
        if (self.dx_cellHeightCache.hasCachedHeightAtIndexPath(cacheByIndexPath)) {
            var height = self.dx_cellHeightCache.cachedHeightAtIndexPath(cacheByIndexPath)
            if let notNilHeight = height {
                self.dx_debugLog("hit cache - [\(cacheByIndexPath.section):\(cacheByIndexPath.row)] \(notNilHeight)")
                
                return notNilHeight
            }
        }
        
        var height = self.dx_heightForCell(identifier, configuration: configuration)
        
        self.dx_cellHeightCache.cacheIndexPath(cacheByIndexPath, height: height)
        self.dx_debugLog("cached - [\(cacheByIndexPath.section):\(cacheByIndexPath.row)] \(height)")
        
        return height
    }
    
    var dx_debuglogEnabled: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.dx_debuglogEnabled_key)?.boolValue
        }
        set {
            if let value = newValue {
                objc_setAssociatedObject(self, &AssociatedKey.dx_debuglogEnabled_key, NSNumber(bool: value), UInt(OBJC_ASSOCIATION_COPY))
            } else {
                objc_setAssociatedObject(self, &AssociatedKey.dx_debuglogEnabled_key, nil, UInt(OBJC_ASSOCIATION_COPY))
            }
        }
    }
    
    //MARK: Private Methods
    
    private func dx_debugLog(message: String) {
        if (self.dx_debuglogEnabled == false) {
            return
        }
        
        NSLog("** DXTemplateLayoutCell ** %@", message)
    }
    
    private var dx_templateCellsByIdentifiers: NSMutableDictionary? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.dx_templateCellsByIdentifiers_key) as? NSMutableDictionary
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.dx_templateCellsByIdentifiers_key, newValue, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
    
    private var dx_autoCacheInvalidationEnabled: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.dx_autoCacheInvalidationEnabled_key)?.boolValue
        }
        set {
            if let value = newValue {
                objc_setAssociatedObject(self, &AssociatedKey.dx_autoCacheInvalidationEnabled_key, NSNumber(bool: value), UInt(OBJC_ASSOCIATION_COPY))
            } else {
                objc_setAssociatedObject(self, &AssociatedKey.dx_autoCacheInvalidationEnabled_key, nil, UInt(OBJC_ASSOCIATION_COPY))
            }
        }
    }
    
    private var dx_precacheEnabled: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.dx_precacheEnabled_key)?.boolValue
        }
        set {
            if let value = newValue {
                objc_setAssociatedObject(self, &AssociatedKey.dx_precacheEnabled_key, NSNumber(bool: value), UInt(OBJC_ASSOCIATION_COPY))
            } else {
                objc_setAssociatedObject(self, &AssociatedKey.dx_precacheEnabled_key, nil, UInt(OBJC_ASSOCIATION_COPY))
            }
        }
    }
    
    private func dx_templateCell(reuseIdentifier: String) -> UITableViewCell? {
        assert(reuseIdentifier.isEmpty == false, "ReuseIdentifier must not empty")
        
        var templateCellsByIdentifiers = self.dx_templateCellsByIdentifiers
        if (nil == templateCellsByIdentifiers) {
            templateCellsByIdentifiers = NSMutableDictionary()
            self.dx_templateCellsByIdentifiers = templateCellsByIdentifiers
        }
        
        var templateCell = templateCellsByIdentifiers?.objectForKey(reuseIdentifier) as? UITableViewCell
        if (nil == templateCell) {
            templateCell = self.dequeueReusableCellWithIdentifier(reuseIdentifier) as? UITableViewCell
            
            assert(templateCell != nil, "Cell must be registered to table view for identifier \(reuseIdentifier)")
            
            templateCell?.dx_isTemplateLayoutCell = true;
            templateCell?.contentView.setTranslatesAutoresizingMaskIntoConstraints(false)
            
            if let cacheCell = templateCell {
                templateCellsByIdentifiers?.setObject(cacheCell, forKey: reuseIdentifier)
            }
            
            self.dx_debugLog("layout cell created - \(reuseIdentifier)")
        }
        
        return templateCell
    }
    
    private func dx_precacheIfNeed() -> Void {
        if (nil == self.dx_precacheEnabled || !self.dx_precacheEnabled!) {
            return;
        }
        
        if let delegate = self.delegate {
            if (!delegate.respondsToSelector(Selector("tableView:heightForRowAtIndexPath:"))) {
                return;
            }
        } else {
            return;
        }
        
        var runLoop = CFRunLoopGetCurrent()
        
        // This is a idle mode of RunLoop, when UIScrollView scrolls, it jumps into "UITrackingRunLoopMode"
        // and won't perform any cache task to keep a smooth scroll.
        var runLoopMode = kCFRunLoopDefaultMode
        
        // Collect all index paths to be precached.
        var mutableIndexPathsToBePrecached = self.dx_allIndexPathsToBePrecached()
        
        // Setup a observer to get a perfect moment for precaching tasks.
        // We use a "kCFRunLoopBeforeWaiting" state to keep RunLoop has done everything and about to sleep
        // (mach_msg_trap), when all tasks finish, it will remove itself.
        var observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault,
            CFRunLoopActivity.BeforeWaiting.rawValue, Boolean(1), 0) { (observer, activity) -> Void in
                // Remove observer when all precache tasks are done.
                if (mutableIndexPathsToBePrecached.count == 0) {
                    CFRunLoopRemoveObserver(runLoop, observer, runLoopMode)
                    
                    return
                }
                
                // Pop first index path record as this RunLoop iteration's task.
                var indexPath = mutableIndexPathsToBePrecached.first
                mutableIndexPathsToBePrecached.removeAtIndex(0)
                
                // This method creates a "source 0" task in "idle" mode of RunLoop, and will be
                // performed in a future RunLoop iteration only when user is not scrolling.
                NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: Selector("dx_precacheIndexPathIfNeeded:"), userInfo: indexPath, repeats: false)
        }
        
        CFRunLoopAddObserver(runLoop, observer, runLoopMode)
    }
    
    private func dx_allIndexPathsToBePrecached() -> [NSIndexPath] {
        var allIndexPaths = [NSIndexPath]()
        
        var numberOfSections = self.numberOfSections()
        for section in 0..<numberOfSections {
            var numberOfRowsInSection = self.numberOfRowsInSection(section)
            for row in 0..<numberOfRowsInSection {
                var indexPath = NSIndexPath(forRow: row, inSection: section)
                if (!self.dx_cellHeightCache.hasCachedHeightAtIndexPath(indexPath)) {
                    allIndexPaths.append(indexPath)
                }
            }
        }
        
        return allIndexPaths
    }
    
    private var dx_cellHeightCache: DXTemplateLayoutCellHeightCache {
        get {
            var cache = objc_getAssociatedObject(self, &AssociatedKey.dx_cellHeightCache_key) as? DXTemplateLayoutCellHeightCache
            if (nil == cache) {
                cache = DXTemplateLayoutCellHeightCache()
                objc_setAssociatedObject(self, &AssociatedKey.dx_cellHeightCache_key, cache, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC));
            }
            
            return cache!;
        }
    }
    
    func dx_precacheIndexPathIfNeeded(timer: NSTimer) -> Void {
        var indexPath = timer.userInfo as! NSIndexPath
        if (self.dx_cellHeightCache.hasCachedHeightAtIndexPath(indexPath)) {
            return
        }
        
        // This RunLoop source may have been invalid at this point when data source
        // changes during precache's dispatching.
        if (indexPath.section >= self.numberOfSections() || indexPath.row >= self.numberOfRowsInSection(indexPath.section)) {
            return;
        }
        
        if let delegate = self.delegate {
            if (delegate.respondsToSelector(Selector("tableView:heightForRowAtIndexPath:"))) {
                var height = delegate.tableView!(self, heightForRowAtIndexPath: indexPath)
                self.dx_cellHeightCache.cacheIndexPath(indexPath, height: height)
                
                self.dx_debugLog("finished precache - [\(indexPath.section):\(indexPath.row)] \(height)")
            }
        }
    }
}

extension UITableViewCell {
    
    //MARK: Private Defines
    
    private struct AssociatedKey {
        static var dx_isTemplateLayoutCellKey = "dx_isTemplateLayoutCellKey"
        static var dx_enforceFrameLayout = "dx_enforceFrameLayout"
    }
    
    //MARK: Public Methods
    
    var dx_isTemplateLayoutCell: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.dx_isTemplateLayoutCellKey)?.boolValue
        }
        set {
            if let value = newValue {
                objc_setAssociatedObject(self, &AssociatedKey.dx_isTemplateLayoutCellKey, NSNumber(bool: value), UInt(OBJC_ASSOCIATION_COPY))
            }
        }
    }
    
    var dx_enforceFrameLayout: Bool? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.dx_enforceFrameLayout)?.boolValue
        }
        set {
            if let value = newValue {
                objc_setAssociatedObject(self, &AssociatedKey.dx_enforceFrameLayout, NSNumber(bool: value), UInt(OBJC_ASSOCIATION_COPY))
            }
        }
    }
}

private class DXTemplateLayoutCellHeightCache {
    
    // 2 dimensions array, sections-rows-height
    var sections = NSMapTable()
    
//    func cacheKeyForIndexPath(indexPath: NSIndexPath) -> String {
//        return "\(indexPath.section)-\(indexPath.row)"
//    }
    
    func hasCachedHeightAtIndexPath(indexPath: NSIndexPath) -> Bool {
        var cachedHeight = self.cachedHeightAtIndexPath(indexPath)
        
        if let _ = cachedHeight {
            return true;
        } else {
            return false;
        }
    }
    
    func cacheIndexPath(indexPath: NSIndexPath, height: CGFloat) -> Void {
        var sectionCache = self.sections.objectForKey(indexPath.section) as? NSMapTable
        if (nil == sectionCache) {
            sectionCache = NSMapTable()
            self.sections.setObject(sectionCache!, forKey: indexPath.section)
        }
        sectionCache?.setObject(height, forKey: indexPath.row)
    }
    
    func cachedHeightAtIndexPath(indexPath: NSIndexPath) -> CGFloat? {
        var sectionCache = self.sections.objectForKey(indexPath.section) as? NSMapTable
        var cachedHeight = sectionCache?.objectForKey(indexPath.row) as? CGFloat
        
        return cachedHeight
    }
}

extension UITableView {
    
    func dx_reloadData(shouldRemoveCache: Bool) -> Void {
        if let notNilAutoCache = self.dx_autoCacheInvalidationEnabled {
            if (notNilAutoCache && shouldRemoveCache) {
                self.dx_cellHeightCache.sections.removeAllObjects()
            }
        }
        
        self.dx_reloadData()
        
        self.dx_precacheIfNeed()
    }
    
    override public class func initialize() {
        struct Static {
            static var token: dispatch_once_t = 0
        }
        
        var selectors = [
            "reloadData",
            "insertSections:withRowAnimation:",
            "deleteSections:withRowAnimation:",
            "reloadSections:withRowAnimation:",
            "moveSection:toSection:",
            "insertRowsAtIndexPaths:withRowAnimation:",
            "deleteRowsAtIndexPaths:withRowAnimation:",
            "reloadRowsAtIndexPaths:withRowAnimation:",
            "moveRowAtIndexPath:toIndexPath:",
        ]
        
        for selector in selectors {
            let swizzledSelector = "dx_\(selector)"
            
            let originalMethod = class_getInstanceMethod(self, Selector(selector))
            let swizzledMethod = class_getInstanceMethod(self, Selector(swizzledSelector))
            
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    func dx_reloadData() -> Void {
        self.dx_reloadData(true)
    }
    
    func dx_insertSections(sections: NSIndexSet, withRowAnimation: UITableViewRowAnimation) -> Void {
        
        self.dx_insertSections(sections, withRowAnimation: withRowAnimation)
        
        self.dx_precacheIfNeed()
    }
    
    func dx_deleteSections(sections: NSIndexSet, withRowAnimation: UITableViewRowAnimation) -> Void {
        if let notNilAutoCache = self.dx_autoCacheInvalidationEnabled {
            if (notNilAutoCache) {
                sections.enumerateIndexesUsingBlock({ (index, stop) -> Void in
                    self.dx_cellHeightCache.sections.removeObjectForKey(index)
                })
            }
        }
        
        self.dx_deleteSections(sections, withRowAnimation: withRowAnimation)
    }
    
    func dx_reloadSections(sections: NSIndexSet, withRowAnimation: UITableViewRowAnimation) -> Void {
        if let notNilAutoCache = self.dx_autoCacheInvalidationEnabled {
            if (notNilAutoCache) {
                sections.enumerateIndexesUsingBlock({ (index, stop) -> Void in
                    self.dx_cellHeightCache.sections.removeObjectForKey(index)
                })
            }
        }
        
        self.dx_reloadSections(sections, withRowAnimation: withRowAnimation)
        
        self.dx_precacheIfNeed()
    }
    
    func dx_moveSection(section: NSInteger, toSection: NSInteger) -> Void {
        if let notNilAutoCache = self.dx_autoCacheInvalidationEnabled {
            if (notNilAutoCache) {
                var sectionCache1 = self.dx_cellHeightCache.sections.objectForKey(section) as? NSMapTable
                var sectionCache2 = self.dx_cellHeightCache.sections.objectForKey(toSection) as? NSMapTable
                
                if let _ = sectionCache1 {
                    self.dx_cellHeightCache.sections.setObject(sectionCache1!, forKey: toSection)
                }
                if let _ = sectionCache2 {
                    self.dx_cellHeightCache.sections.setObject(sectionCache2!, forKey: section)
                }
            }
        }
        
        self.dx_moveSection(section, toSection: toSection)
    }
    
    func dx_insertRowsAtIndexPaths(indexPaths: NSArray, withRowAnimation: UITableViewRowAnimation) -> Void {
        
        self.dx_insertRowsAtIndexPaths(indexPaths, withRowAnimation: withRowAnimation)
        
        self.dx_precacheIfNeed()
    }
    
    func dx_deleteRowsAtIndexPaths(indexPaths: NSArray, withRowAnimation: UITableViewRowAnimation) -> Void {
        if let notNilAutoCache = self.dx_autoCacheInvalidationEnabled {
            if (notNilAutoCache) {
                indexPaths.enumerateObjectsUsingBlock({ (indexPath, index, stop) -> Void in
                    var sectionCache = self.dx_cellHeightCache.sections.objectForKey(indexPath.section) as? NSMapTable
                    sectionCache?.removeObjectForKey(indexPath.row)
                })
            }
        }
        
        self.dx_deleteRowsAtIndexPaths(indexPaths, withRowAnimation: withRowAnimation)
    }
    
    func dx_reloadRowAtIndexPaths(indexPaths: NSArray, withRowAnimation: UITableViewRowAnimation) -> Void {
        if let notNilAutoCache = self.dx_autoCacheInvalidationEnabled {
            if (notNilAutoCache) {
                indexPaths.enumerateObjectsUsingBlock({ (indexPath, index, stop) -> Void in
                    var sectionCache = self.dx_cellHeightCache.sections.objectForKey(indexPath.section) as? NSMapTable
                    sectionCache?.removeObjectForKey(indexPath.row)
                })
            }
        }
        
        self.dx_reloadRowAtIndexPaths(indexPaths, withRowAnimation: withRowAnimation)
        
        self.dx_precacheIfNeed()
    }
    
    func dx_moveRowAtIndexPath(sourceIndexPath: NSIndexPath, toIndexPath: NSIndexPath) -> Void {
        if let notNilAutoCache = self.dx_autoCacheInvalidationEnabled {
            if (notNilAutoCache) {
                var sectionCache1 = self.dx_cellHeightCache.sections.objectForKey(sourceIndexPath.section) as? NSMapTable
                var sectionCache2 = self.dx_cellHeightCache.sections.objectForKey(toIndexPath.section) as? NSMapTable
                
                var rowCache1 = sectionCache1?.objectForKey(sourceIndexPath.row) as? CGFloat
                var rowCache2 = sectionCache2?.objectForKey(toIndexPath.row) as? CGFloat
                
                if let _ = rowCache1 {
                    sectionCache2?.setObject(rowCache1!, forKey: toIndexPath.row)
                }
                if let _ = rowCache2 {
                    sectionCache1?.setObject(rowCache2!, forKey: sourceIndexPath.row)
                }
            }
        }
        
        self.dx_moveRowAtIndexPath(sourceIndexPath, toIndexPath: toIndexPath)
    }
}
