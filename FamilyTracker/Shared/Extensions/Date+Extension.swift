//
//  Date+Extension.swift
//  FamilyTracker
//
//  Created by Mahesh on 09/04/21.
//

import Foundation

extension Date {
    func currentUTCDate() -> String {
        let dtf = DateFormatter()
        dtf.timeZone = TimeZone.current
        dtf.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dtf.string(from: self)
    }
}
