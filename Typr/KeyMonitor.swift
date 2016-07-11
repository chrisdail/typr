//
//  KeyMonitor.swift
//  Typr
//
//  Created by Christopher Dail on 2016-07-02.
//  Copyright © 2016 Christopher Dail. All rights reserved.
//

import Foundation
import Cocoa

class KeyMonitor {
    var managedObjectContext: NSManagedObjectContext
    var workspace: NSWorkspace!
    var statusItem: NSStatusItem
    
    let characterSet = NSCharacterSet.alphanumericCharacterSet()
    let whitespaceSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()

    var lastWord = ""    
    var stats: WordStats
    
    lazy var logPath: String = {
        let documents = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        return NSString(string: documents).stringByAppendingPathComponent("TyprWordStats.log")
    }()
    
    init(managedObjectContext: NSManagedObjectContext, statusItem: NSStatusItem) {
        self.managedObjectContext = managedObjectContext
        self.statusItem = statusItem
        workspace = NSWorkspace.sharedWorkspace()
        
        stats = WordStats.findOrCreate(managedObjectContext)
        updateStatusBar()
    }
    
    func handler(event: NSEvent) {
        for uni in event.charactersIgnoringModifiers!.unicodeScalars {
            // If we are a whitespace character AND last character was not whitespace
            if whitespaceSet.longCharacterIsMember(uni.value) {
                // Only count words with at least 2 characters
                if lastWord.characters.count >= 2 || lastWord == "a" || lastWord == "i" {
                    onWord(lastWord)
                    lastWord = ""
                }
            }
            else if characterSet.longCharacterIsMember(uni.value) {
                lastWord.append(uni)
            }
        }
        
    }
    
    func onWord(word: String) {
        // Get the current application with focus
        let app = workspace.frontmostApplication
        let appName = app!.localizedName!
        
        // Detect if we have changed days
        if (!stats.isFromToday()) {
            stats = WordStats.findOrCreate(managedObjectContext)
            logStats()
        }
        stats.recordNewWord(appName)
        updateStatusBar()
    }
    
    func updateStatusBar() {
        statusItem.title = String(format: "%d", stats.total.intValue)
    }
    
    // Logs out the daily summary
    func logStats() {
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.LongStyle
        let dateString = formatter.stringFromDate(stats.date)
        let message = "Totals for \(dateString): \(stats.total) \(stats.countByApp)\n"
        
        if let fileHandle = NSFileHandle(forWritingAtPath: logPath) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.writeData(message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        }
        else {
            do {
                try message.writeToFile(logPath, atomically: true, encoding: NSUTF8StringEncoding)
            }
            catch {
                print(error)
            }
        }

    }
    
    // Get the current date without time information
    func currentDate() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month,
            NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear], fromDate: NSDate())
        return calendar.dateFromComponents(dateComponents)!
    }
    
}
