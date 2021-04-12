//
//  DateUtils.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 09/04/21.
//

import Foundation

class DateUtils {
    
    class func formatLastUpdated(dateString: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        dateFormatter.timeZone = TimeZone.current
        let date = dateFormatter.date(from: dateString)
        
        if let date = date {
            if Calendar.current.isDateInToday(date) {
                dateFormatter.timeZone = NSTimeZone.local
                dateFormatter.dateFormat = "h:mm a"
                let localTime = dateFormatter.string(from: date)
                return "Last updated at \(localTime)"
            } else if Calendar.current.component(.month, from: date) < Calendar.current.component(.month, from: Date()) ||  Calendar.current.component(.year, from: date) < Calendar.current.component(.year, from: Date()) {
                dateFormatter.timeZone = NSTimeZone.local
                dateFormatter.dateFormat = "d MMM yyyy"
                let localTime = dateFormatter.string(from: date)
                return "Last updated at \(localTime)"
            } else {
                dateFormatter.timeZone = NSTimeZone.local
                dateFormatter.dateFormat = "E d, h:mm a"
                let localTime = dateFormatter.string(from: date)
                return "Last updated at \(localTime)"
            }
        }
        return nil
    }
    
}
