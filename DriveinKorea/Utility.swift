//
//  Utility.swift
//  DriveinKorea
//
//  Created by DongningWang on 4/14/15.
//  Copyright (c) 2015 wandonye. All rights reserved.
//

import Foundation
import MapKit


/* Standardises and angle to [-180 to 180] degrees */
func standardAngle(var angle: CLLocationDegrees) -> CLLocationDegrees {
    angle %= 360
    return angle < -180 ? -360 - angle : angle > 180 ? 360 - 180 : angle
}

/* confirms that a region contains a location */
func regionContains(region: MKCoordinateRegion, location: CLLocationCoordinate2D) -> Bool {
    //println("(\(location.latitude),\(location.longitude))")
    //println("(\(region.center.latitude),\(region.center.longitude)), \(region.span.latitudeDelta), \(region.span.longitudeDelta)")
    let deltaLat = abs(standardAngle(region.center.latitude - location.latitude))
    let deltalong = abs(standardAngle(region.center.longitude - location.longitude))
    return region.span.latitudeDelta >= deltaLat && region.span.longitudeDelta >= deltalong
}

func string2UTF8(str: NSString) ->NSString {
    var arr = [UInt8]()
    
    var utf8str = ""
    arr += (str as String).utf8
    
    for i in arr {
        utf8str += "%"
        utf8str += NSString(format: "%2X", i)
    }
    
    return utf8str
}

func hasHaniHang(str: NSString) ->Bool {
    var ar = NSArray?()
    var range = NSMakeRange(0, str.length)
    var lng = (str as NSString).linguisticTagsInRange(range, scheme: NSLinguisticTagSchemeScript, options: NSLinguisticTaggerOptions.allZeros, orthography: nil, tokenRanges: &ar) as NSArray
    if (lng.containsObject("Hani") || lng.containsObject("Kore")){
        return true
    }
    return false
}

func hasPreposition(str: NSString) ->Bool {
    if ((str as String).rangeOfString(" in ", options: NSStringCompareOptions.CaseInsensitiveSearch) != nil){
        return true
        //found "something in somewhere"
    }

    var ar = NSArray?()
    var range = NSMakeRange(0, str.length)
    var tagArray = str.linguisticTagsInRange(range, scheme: NSLinguisticTagSchemeLexicalClass, options: NSLinguisticTaggerOptions.allZeros, orthography: nil, tokenRanges: &ar) as NSArray
    //println(tagArray)
    if (tagArray.containsObject("Preposition")){
        println("Found Preposition")
        return true
    }
    return false
}

func findPoscode(inout str: String) ->String { //return poscode or "" if nothing found, str will be changed so that poscode is removed

    let spaceSet = NSCharacterSet.whitespaceCharacterSet()
    var arr = Array(str)
    
    var i = 0
    for char in arr {
        if char == "-" && i>2 && i < (str as NSString).length-3 {
            var start1 = advance(str.startIndex,i-3)
            var end1 = advance(str.startIndex,i-1)
            var start2 = advance(str.startIndex,i+1)
            var end2 = advance(str.startIndex,i+3)
            
            var prevStr = str[start1...end1]
            var postStr = str[start2...end2]
            let tester1 = prevStr.stringByReplacingOccurrencesOfString("[0-9]", withString: "")
            let tester2 = postStr.stringByReplacingOccurrencesOfString("[0-9]", withString: "")
            if (tester1 == "" && tester2 == "") {
                var poscode = str[start1...end2]
                str = str.stringByReplacingOccurrencesOfString(poscode, withString: "", options: NSStringCompareOptions.RegularExpressionSearch).stringByTrimmingCharactersInSet(spaceSet)
                return poscode
            }
        }
        i += 1
    }
    return ""
}

func hasCity(str: NSString) ->Int {
    var index = 0
    for eCity in eCityDict {

        if ((str as String).rangeOfString(eCity as String, options: NSStringCompareOptions.CaseInsensitiveSearch) != nil){
            return index
            //has enlish city name
        }
        index += 1
    }

    index = 0
    for kCity in kCityDict {
        if ((str as String).rangeOfString(kCity as String) != nil){
            return index
            //has korean city name
        }
        index += 1
    }
    return -1
}