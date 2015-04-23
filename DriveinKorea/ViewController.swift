//
//  ViewController.swift
//  DriveinKorea
//
//  Created by DongningWang on 4/12/15.
//  Copyright (c) 2015 wandonye. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var searchText: UITextField!
    @IBOutlet var map: MKMapView!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var locationManager = CLLocationManager()
    var annotationList = [DriveAnnotation]()
    var annotationInRectList = [DriveAnnotation]()
    var searchType = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchText.delegate = self
        
        locationManager.delegate = self
        self.map.delegate = self
        
        self.spinner.hidden = true
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if (locationManager.respondsToSelector(Selector("requestWhenInUseAuthorization"))) {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation()
        self.showButton.enabled = false

        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func locateMe(sender: AnyObject) {
        locationManager.startUpdatingLocation()
    }
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        self.view.endEditing(true)
        
    }
    
    @IBAction func showButtonPressed(sender: UIButton) {
        //logic:
        if (showButton.enabled==true) {
            if (self.showButton.titleLabel?.text=="Overview") {
                self.map.removeAnnotations(self.map.annotations)
                self.map.addAnnotations(self.annotationList)
                self.map.showAnnotations(self.map.annotations, animated: true)

                if (self.searchType == 1) {
                    sender.setTitle("Results", forState: UIControlState.Normal)
                } else {
                    sender.setTitle("Near me", forState: UIControlState.Normal)
                }

            }else {
                if (self.searchType == 1) {
                    self.map.showsUserLocation = false
                    self.map.showAnnotations(self.map.annotations, animated: true)
                    self.map.showsUserLocation = true
                } else {
                    self.map.removeAnnotations(self.map.annotations)
                    self.map.addAnnotations(self.annotationInRectList)
                    self.map.showAnnotations(self.map.annotations, animated: true)
                }
                sender.setTitle("Overview", forState: UIControlState.Normal)
            }
        }
    }
    
    
    func textFieldDidBeginEditing(textField: UITextField!) {    //delegate method
        var allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        self.annotationInRectList.removeAll()
        self.annotationList.removeAll()
        self.showButton.enabled = false
    }
    
    
    func textFieldShouldReturn(textField: UITextField!) ->Bool {
        
        self.spinner.hidden = false
        self.spinner.startAnimating()
        
        textField.resignFirstResponder()
    
        let spaceSet = NSCharacterSet.whitespaceCharacterSet()
        
        var keyword = textField.text.stringByReplacingOccurrencesOfString(
            "[\\$\\!\\#\\@\\.\\/]", withString: "", options: .RegularExpressionSearch).stringByTrimmingCharactersInSet(spaceSet)
        
        self.searchText.text = keyword
        
        if keyword == "" {
            self.spinner.hidden = false
            self.spinner.startAnimating()

            return true
        }
        
        if regionContains(self.map.region, self.map.userLocation.location.coordinate) {
            self.searchType = 0 //if user location is inside current view
        } else {
            self.searchType = 1 //if user location is outside current view
        }
        
        var uLocLat = self.map.region.center.latitude
        var uLocLon = self.map.region.center.longitude
        
        var poscode = findPoscode(&keyword)
        //println(keyword)
        
        var cityIndex = hasCity(keyword)
        var keywordHasKr = hasHaniHang(keyword)

        let numbers = NSCharacterSet.decimalDigitCharacterSet()
        
        if let range = keyword.rangeOfCharacterFromSet(numbers) {
            //if keyword contains numbers, it is more likely an address
            var gisUrl = NSURL()
            //poscode removed, at the moment, poscode is of no use
            if (keywordHasKr){
                gisUrl = NSURL(string: "http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates?SingleLine=\(string2UTF8(keyword))&category=Address&outFields=location&forStorage=false&sourceCountry=KOR&f=json")!
            }else {
                //replace spaces with "%20" for english inquery
                keyword=keyword.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: NSStringCompareOptions.LiteralSearch, range: nil)
                gisUrl = NSURL(string: "http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates?SingleLine=\(keyword)&category=Address&outFields=location&forStorage=false&sourceCountry=KOR&f=json")!
            }

            var request = NSURLRequest(URL: gisUrl)
            
            let session = NSURLSession.sharedSession()
            
            var task = session.dataTaskWithURL(gisUrl, completionHandler: { (data, response, error) -> Void in
                if (error != nil) {
                    println(error)
                    return
                }else {
                    var err = NSError?()
                    var jsonResultsString:NSString = NSString(data: data, encoding: NSUTF8StringEncoding)!
                    
                    var jsonResultsDict = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &err) as NSDictionary
                    
                    if (err != nil) {
                        println(err)
                    } else if ((jsonResultsDict as Dictionary).indexForKey("candidates") == nil) {
                        println("No candidate found: \(gisUrl)")
                    } else {
                        var candidates = jsonResultsDict["candidates"] as NSArray
                        
                        if (candidates.count == 0){
                            
                            println("No address matched, will try without poscode: \(gisUrl)")
                            //try google
                            if (keywordHasKr){
                            gisUrl = NSURL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(uLocLat),\(uLocLon)&rankby=distance&keyword=\(string2UTF8(keyword))&key=\(gMapKey)")!
                            }else {
                            //replace spaces with "%20" for english inquery
                            keyword=keyword.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: NSStringCompareOptions.LiteralSearch, range: nil)
                            gisUrl = NSURL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(uLocLat),\(uLocLon)&rankby=distance&keyword=\(keyword)&key=\(gMapKey)")!
                            }
                            
                            if let data2 = NSData(contentsOfURL: gisUrl) {
                                if let jsonResultsString2 = NSString(data: data2, encoding: NSUTF8StringEncoding) {
                                    var jsonResultsDict = NSJSONSerialization.JSONObjectWithData(data2, options: nil, error: &err) as NSDictionary
                                    
                                    if (err != nil) {
                                        println(err)
                                        self.spinner.stopAnimating()
                                        self.spinner.hidden = true

                                        return
                                    } else {
                                        if let places = jsonResultsDict["results"] as? NSArray {
                                            
                                            if (places.count == 0) {
                                                println("Google has no result")
                                                return
                                            }
                                            
                                            for place in places {
                                                //println(place)
                                                var lati = (((place as NSDictionary)["geometry"] as NSDictionary)["location"] as NSDictionary)["lat"] as Double
                                                //println(lati)
                                                
                                                var longti = (((place as NSDictionary)["geometry"] as NSDictionary)["location"] as NSDictionary)["lng"] as Double
                                                //println(longti)
                                                
                                                var coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lati, longti)
                                                
                                                var annotation = DriveAnnotation(title: (place as NSDictionary)["name"] as NSString, locationName: (place as NSDictionary)["vicinity"] as NSString, coordinate: coordinate)
                                                self.annotationList.append(annotation)
                                                
                                                if (regionContains(self.map.region, coordinate)) {
                                                    self.annotationInRectList.append(annotation)
                                                }
                                            }
                                            println("google win")
                                            println(gisUrl)
                                            
                                            //start showing google result
                                            dispatch_async(dispatch_get_main_queue()) {
                                                self.spinner.stopAnimating()
                                                self.spinner.hidden = true

                                                if (self.annotationInRectList.count==self.annotationList.count) {
                                                    //println("all \(self.annotationList.count) in region")
                                                    self.map.addAnnotations(self.annotationList)
                                                    self.map.showAnnotations(self.map.annotations, animated: false)
                                                }else {
                                                    println("google found \(places.count) place(s)")
                                                    self.map.addAnnotations(self.annotationInRectList)
                                                    self.map.showAnnotations(self.map.annotations, animated: false)
                                                    self.showButton.enabled = true
                                                }
                                            }
                                            // done showing google result

                                        }
                                    }

                                }
                            }
                            
                        } else {
                            println("Address matched")
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.spinner.stopAnimating()
                                self.spinner.hidden = true
                            }
                            self.arcgisFindAddressCandFound((candidates[0]) as NSDictionary)
                            return
                        }
                        
                    }

                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.spinner.stopAnimating()
                    self.spinner.hidden = true
                }
            })
            task.resume()
            return true
            
        }else if (hasPreposition(keyword) && cityIndex >= 0) {
            //if keyword contains "near", "in" and a city name
            self.searchType = 1
            uLocLat = cityCoord.objectAtIndex(cityIndex)["x"] as Double
            uLocLon = cityCoord.objectAtIndex(cityIndex)["y"] as Double

            gmapAsyncGeocoding(keyword, keywordHasKr: keywordHasKr, uLocLat: uLocLat, uLocLon: uLocLon)
            return true
            
        } else {
            gmapAsyncGeocoding(keyword, keywordHasKr: keywordHasKr, uLocLat: uLocLat, uLocLon: uLocLon)
        }
        
        //println("region center: (\(uLocLat),\(uLocLon))")
        
        return true
    }
    
    func gmapAsyncGeocoding(keyword: String, keywordHasKr: Bool, uLocLat: Double, uLocLon: Double) ->Void {
        var url = NSURL()
        if (keywordHasKr){
            url = NSURL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(uLocLat),\(uLocLon)&rankby=distance&keyword=\(string2UTF8(keyword))&key=\(gMapKey)")!
        }else {
            //replace spaces with "%20" for english inquery
            let keywordFixSpace=keyword.stringByReplacingOccurrencesOfString(" ", withString: "%20", options: NSStringCompareOptions.LiteralSearch, range: nil)
            url = NSURL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(uLocLat),\(uLocLon)&rankby=distance&keyword=\(keywordFixSpace)&key=\(gMapKey)")!
        }
        
        var request = NSURLRequest(URL: url)
        
        let session = NSURLSession.sharedSession()
        
        var task = session.dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                println(error)
            }else {
                var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
                
                var places = jsonResult["results"] as NSArray
                
                if (places.count == 0) {
                    println("Google has no result")
                    return
                }
                
                for place in places {
                    //println(place)
                    var lati = (((place as NSDictionary)["geometry"] as NSDictionary)["location"] as NSDictionary)["lat"] as Double
                    //println(lati)
                    
                    var longti = (((place as NSDictionary)["geometry"] as NSDictionary)["location"] as NSDictionary)["lng"] as Double
                    //println(longti)
                    
                    var coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lati, longti)
                    
                    var annotation = DriveAnnotation(title: (place as NSDictionary)["name"] as NSString, locationName: (place as NSDictionary)["vicinity"] as NSString, coordinate: coordinate)
                    self.annotationList.append(annotation)
                    
                    if (regionContains(self.map.region, coordinate)) {
                        self.annotationInRectList.append(annotation)
                    }
                }
                println("google win")
                println(url)
                
                //to do : translate
                dispatch_async(dispatch_get_main_queue()) {
                    self.spinner.stopAnimating()
                    self.spinner.hidden = true
                    println(self.searchType)
                    
                    if self.searchType == 1 {
                        self.map.showsUserLocation = false
                        self.map.addAnnotations(self.annotationList)
                        self.map.showAnnotations(self.map.annotations, animated: false)
                        self.showButton.enabled = true
                        
                        if regionContains(self.map.region, self.map.userLocation.location.coordinate){
                            self.map.showsUserLocation = true
                            self.map.addAnnotations(self.annotationList)
                            self.map.showAnnotations(self.map.annotations, animated: false)
                            self.showButton.enabled = false
                        }
                        self.map.showsUserLocation = true

                    } else {
                        if (self.annotationInRectList.count==self.annotationList.count) {
                            //println("all \(self.annotationList.count) in region")
                            self.map.addAnnotations(self.annotationList)
                            self.map.showAnnotations(self.map.annotations, animated: false)
                        }else {
                            println("google found \(places.count) place(s)")
                            self.map.addAnnotations(self.annotationInRectList)
                            self.map.showAnnotations(self.map.annotations, animated: false)
                            self.showButton.enabled = true
                        }
                    }
                }
            }
        })
        task.resume()
        return
    }
    

    func arcgisFindAddressCandFound(candidate: NSDictionary) ->Void {
        var location = (candidate["location"]) as NSDictionary
        var lati = location["y"] as Double
        //println(lati)
        
        var longti = location["x"] as Double
        //println(longti)
        
        var coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lati, longti)
        
        var annotation = DriveAnnotation(title: candidate["address"] as NSString, locationName: "(\(lati),\(longti))" as NSString, coordinate: coordinate)
        dispatch_async(dispatch_get_main_queue()) {
            self.map.addAnnotation(annotation)
            self.map.showAnnotations(self.map.annotations, animated: false)
        }

    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {

        var userLocation: CLLocation = locations[0] as CLLocation
        var lati = userLocation.coordinate.latitude
        var longti = userLocation.coordinate.longitude
        var latdelta:CLLocationDegrees = 0.06
        var londelta:CLLocationDegrees = 0.06
        var span:MKCoordinateSpan = MKCoordinateSpanMake(latdelta, londelta)
        var location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lati, longti)
        var region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        self.map.setRegion(region, animated: false)
        
        locationManager.stopUpdatingLocation()
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        //println("view called")
        if let annotation = annotation as? DriveAnnotation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView {
                    dequeuedView.annotation = annotation
                    view = dequeuedView
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                //view.calloutOffset = CGPoint(x: -5, y: 5)
                var drButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as UIButton
                
                drButton.setImage(UIImage(named: "car_icon.png"), forState: UIControlState.Normal)
                drButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                view.rightCalloutAccessoryView = drButton
                
            }
            return view
        }
        return nil
        
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        let location = view.annotation as DriveAnnotation
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        location.mapItem().openInMapsWithLaunchOptions(launchOptions)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

