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
    
    let characterSet = NSCharacterSet.alphanumerics
    let whitespaceSet = CharacterSet.whitespacesAndNewlines

    var lastWord = ""    
    var stats: WordStats
    
    lazy var logPath: String = {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return NSString(string: documents).appendingPathComponent("TyprWordStats.log")
    }()
    
    init(managedObjectContext: NSManagedObjectContext, statusItem: NSStatusItem) {
        self.managedObjectContext = managedObjectContext
        self.statusItem = statusItem
        workspace = NSWorkspace.shared
        
        stats = WordStats.findOrCreate(managedObjectContext: managedObjectContext)
        updateStatusBar()
    }
    
    func handler(event: NSEvent) {
        for uni in event.charactersIgnoringModifiers!.unicodeScalars {
            let characterAsSet = CharacterSet(charactersIn: String(uni))
            // If we are a whitespace character AND last character was not whitespace
            if whitespaceSet.isSuperset(of: characterAsSet) {
                // Only count words with at least 2 characters
                if lastWord.count >= 2 || lastWord == "a" || lastWord == "i" {
                    onWord(word: lastWord)
                    lastWord = ""
                }
            }
            else if characterSet.isSuperset(of: characterAsSet) {
                lastWord += String(uni)
            }
        }
    }
    
    func onWord(word: String) {
        // Get the current application with focus
        let app = workspace.frontmostApplication
        let appName = app!.localizedName!
        
        // Detect if we have changed days
        if (!stats.isFromToday()) {
            logStats()
            stats = WordStats.findOrCreate(managedObjectContext: managedObjectContext)
        }
        stats.recordNewWord(appName: appName)
        updateStatusBar()
    }
    
    func updateStatusBar() {
        statusItem.title = String(format: "%d", stats.total.intValue)
    }
    
    // Logs out the daily summary
    func logStats() {
        let formatter = DateFormatter()
        formatter.dateStyle = DateFormatter.Style.long
        let dateString = formatter.string(from: stats.date)
        let message = "Totals for \(dateString): \(stats.total) \(stats.countByApp)\n"
        
        if let fileHandle = FileHandle(forWritingAtPath: logPath) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(message.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
        }
        else {
            do {
                try message.write(toFile: logPath, atomically: true, encoding: String.Encoding.utf8)
            }
            catch {
                print(error)
            }
        }
    }
}
