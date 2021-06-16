//
//  CLLocation+Extension.swift
//  FamilyTracker
//
//  Created by Vijay Godse on 15/04/21.
//

import CoreLocation

extension CLLocation {
    func fetchCityAndCountry(completion: @escaping (_ name: String?, _ city:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first?.name, $0?.first?.locality, $1) }
    }
    
    func fetchAddress(completion: @escaping (_ name: String?, _ city:  String?, _ country:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first?.name, $0?.first?.locality, $0?.first?.country, $1) }
    }
}
