//
//  WordStats.swift
//  Typr
//
//  Created by Christopher Dail on 2016-07-03.
//  Copyright © 2016 Christopher Dail. All rights reserved.
//

import CoreData

class WordStats: NSManagedObject {

    @NSManaged var total: NSNumber
    @NSManaged var date: NSDate
    @NSManaged var countByApp: NSDictionary

    func recordNewWord(appName: String) {
        var stats = countByApp as! [String: NSNumber]
        
        if let count = stats[appName] {
            stats[appName] = NSNumber(int: count.intValue + 1)
        }
        else {
            stats[appName] = NSNumber(int: 1)
        }
        countByApp = stats as NSDictionary
        total = NSNumber(int: total.intValue + 1)
        save()
        
        // Log changes after every word
        //print(countByApp)
    }
    
    func save() {
        do {
            try self.managedObjectContext?.save()
        } catch {
            print(error)
        }
    }
    
    func isFromToday() -> Bool {
        return WordStats.currentDate().isEqualToDate(date)
    }
    
    class func findOrCreate(managedObjectContext: NSManagedObjectContext) -> WordStats {
        // Try to find by the current date
        let fetchRequest = NSFetchRequest(entityName: "WordStats")
        
        // Create Predicate
        let predicate = NSPredicate(format: "%K == %@", "date", currentDate())
        fetchRequest.predicate = predicate
        
        do {
            if let stats = try managedObjectContext.executeFetchRequest(fetchRequest).first as? WordStats {
                return stats
            }
        } catch {
            print(error)
        }
        
        // Record not found, create a new one
        let stats = NSEntityDescription.insertNewObjectForEntityForName("WordStats", inManagedObjectContext:     managedObjectContext) as! WordStats
        stats.date = currentDate()
        stats.total = NSNumber(int: 0)
        stats.countByApp = NSDictionary()
        return stats
    }
    
    // Get the current date without time information
    class func currentDate() -> NSDate {
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Day, NSCalendarUnit.Month,
            NSCalendarUnit.Year, NSCalendarUnit.WeekOfYear], fromDate: NSDate())
        return calendar.dateFromComponents(dateComponents)!
    }
}
