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
    
    
    init(managedObjectContext: NSManagedObjectContext, statusItem: NSStatusItem) {
        self.managedObjectContext = managedObjectContext
        self.statusItem = statusItem
        workspace = NSWorkspace.sharedWorkspace()
        
        stats = WordStats.findOrCreate(managedObjectContext)
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
        }
        stats.recordNewWord(appName)
        
        statusItem.title = String(format: "%d", stats.total.intValue)
    }
    
    // Get the current date without time information
    func currentDate() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month,
            NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear], fromDate: NSDate())
        return calendar.dateFromComponents(dateComponents)!
    }
    
}

// 51 backspace
// 117 delete
// 