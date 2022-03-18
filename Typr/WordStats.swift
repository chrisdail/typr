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
    @NSManaged var date: Date
    @NSManaged var countByApp: NSDictionary

    func recordNewWord(appName: String) {
        var stats = countByApp as! [String: NSNumber]
        
        if let count = stats[appName] {
            stats[appName] = NSNumber(value: count.intValue + 1)
        }
        else {
            stats[appName] = NSNumber(value: 1)
        }
        countByApp = stats as NSDictionary
        total = NSNumber(value: total.intValue + 1)
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
        return WordStats.currentDate() == date
    }
    
    class func findOrCreate(managedObjectContext: NSManagedObjectContext) -> WordStats {
        // Try to find by the current date
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "WordStats")
        
        // Create Predicate
        let predicate = NSPredicate(format: "%K == %@", "date", currentDate() as NSDate)
        fetchRequest.predicate = predicate
        
        do {
            if let stats = try managedObjectContext.fetch(fetchRequest).first as? WordStats {
                return stats
            }
        } catch {
            print(error)
        }
        
        // Record not found, create a new one
        let stats = NSEntityDescription.insertNewObject(forEntityName: "WordStats", into: managedObjectContext) as! WordStats
        stats.date = currentDate()
        stats.total = NSNumber(value: 0)
        stats.countByApp = NSDictionary()
        return stats
    }
    
    // Get the current date without time information
    class func currentDate() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let date = Calendar.current.date(from: components)
        return date!
    }
}
