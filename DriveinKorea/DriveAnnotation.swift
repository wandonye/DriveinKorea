//
//  DriveAnnotation.swift
//  DriveinKorea
//
//  Created by DongningWang on 4/13/15.
//  Copyright (c) 2015 wandonye. All rights reserved.
//

import Foundation
import MapKit
import AddressBook

class DriveAnnotation: NSObject, MKAnnotation {
    
    let title: String
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        super.init()
    }
    
    var subtitle: String {
        return locationName
    }

    func mapItem() -> MKMapItem {
        let addressDictionary = [String(kABPersonAddressStreetKey): subtitle]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDictionary)
        
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        
        return mapItem
    }
}
