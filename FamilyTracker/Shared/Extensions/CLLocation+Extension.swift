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
    
    func getAddress(handler: @escaping (_ address: String?) -> Void)
    {
        CLGeocoder().reverseGeocodeLocation(self, completionHandler: {(placemarks, error) -> Void in
            
            guard error == nil else { handler(nil); return }
            
            guard let place = placemarks else { handler(nil); return }
            
            if place.count > 0 {
                let pm = place[0]
                
                var addArray:[String] = []
                if let name = pm.name {
                    addArray.append(name)
                }
                if let thoroughfare = pm.thoroughfare {
                    addArray.append(thoroughfare)
                }
                if let subLocality = pm.subLocality {
                    addArray.append(subLocality)
                }
                if let locality = pm.locality {
                    addArray.append(locality)
                }
                if let subAdministrativeArea = pm.subAdministrativeArea {
                    addArray.append(subAdministrativeArea)
                }
                if let administrativeArea = pm.administrativeArea {
                    addArray.append(administrativeArea)
                }
                if let country = pm.country {
                    addArray.append(country)
                }
                if let postalCode = pm.postalCode {
                    addArray.append(postalCode)
                }
                
                let addressString = addArray.joined(separator: ", ")
                
                print(addressString)
                
                handler(addressString)
            }
            else { handler(nil)}
        })
    }
}
