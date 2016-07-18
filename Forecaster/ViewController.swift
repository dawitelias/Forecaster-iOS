//
//  ViewController.swift
//  Forecaster
//
//  Created by Dawit Elias on 11/12/15.
//  Copyright © 2015 Dawit Elias. All rights reserved.
// lay out views w/ data from model
//

import UIKit
import CoreLocation
import MapKit
import SystemConfiguration


class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var currentBackground: UIImageView?
    @IBOutlet weak var currentTemperatureLabel: UILabel?
    @IBOutlet weak var currentPrecipitationLabel: UILabel?
    @IBOutlet weak var currentHumidityLabel: UILabel?
    @IBOutlet weak var currentWeatherIcon: UIImageView?
    @IBOutlet weak var currentWeatherSummary: UILabel?
    @IBOutlet weak var currentCityLabel: UILabel?
    @IBOutlet weak var currentDayOfWeek: UILabel!
    @IBOutlet weak var refreshButton: UIButton?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var zipcodeTextField: UITextField!
    
    @IBOutlet weak var tomorrowDayOfWeek: UILabel!
    @IBOutlet weak var tomorrowTemperatureLabel: UILabel!
    @IBOutlet weak var tomorrowIcon: UIImageView!
    var message = "Your network connection is turned off. We recommend you turn it on to get weather data."
    var alertTitle = "Network Connection Unavailable"
    
    private let forecastAPIKey = "a5572d439675e5934cab7f3162665f81"
    let locationManager = CLLocationManager()
    var latValue: Double = 0.0
    var lonValue: Double = 0.0
    var coord: (lat: Double, long: Double) = (1.0,1.0)
    let calendar = NSCalendar.currentCalendar()
    var dayOfWeek = "Monday"
    var convertBool: Bool = true
    
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        print("is this reachable: \(isReachable)")
        return (isReachable && !needsConnection)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        // Ask for Authorization from the user
        locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        locationManager.requestWhenInUseAuthorization()

        retrieveWeatherForecast()
        getDateInfo()
    }
    
    @IBAction func viewTapped(sender: AnyObject) {
        zipcodeTextField.resignFirstResponder()
    }
    
    // convert temperature
    @IBAction func doubleTapDetected(sender: UITapGestureRecognizer) {
        
        if convertBool == true {
            // convert to celsius, else fahrenheit
            let tempF = currentTemperatureLabel?.text
            let tempF2 = tomorrowTemperatureLabel?.text
            let truncatedF = Double(String(tempF!.characters.dropLast(2)))!
            let truncatedF2 = Double(String(tempF2!.characters.dropLast(2)))!
            
            let truncatedC = (truncatedF - 32) * (5/9)
            let truncatedC2 = (truncatedF2 - 32) * (5/9)
            let tempC = String(format: "%.0f", truncatedC)
            let tempC2 = String(format: "%.0f", truncatedC2)
            currentTemperatureLabel?.text = "\(tempC)ºC"
            tomorrowTemperatureLabel?.text = "\(tempC2)ºC"
            
            convertBool = false
            
        } else {
            let tempC = currentTemperatureLabel?.text
            let tempC2 = tomorrowTemperatureLabel?.text
            let truncatedC = Double(String(tempC!.characters.dropLast(2)))!
            let truncatedC2 = Double(String(tempC2!.characters.dropLast(2)))!
            
            let truncatedF = (truncatedC  * (9/5) + 32)
            let truncatedF2 = (truncatedC2  * (9/5) + 32)
            let tempF = String(format: "%.0f", truncatedF)
            let tempF2 = String(format: "%.0f", truncatedF2)
            currentTemperatureLabel?.text = "\(tempF)ºF"
            tomorrowTemperatureLabel?.text = "\(tempF2)ºF"
            
            convertBool = true
        }
    }
    
    
    @IBAction func searchButton(sender: AnyObject) {
        
        if zipcodeTextField != nil {
            let zipcode = zipcodeTextField.text
            let geocoder = CLGeocoder()
            
            toggleRefreshAnimation(true)
            getDateInfo() // might not need to do
            
            geocoder.geocodeAddressString(zipcode!, completionHandler: {(placemarks, error) -> Void in
                if((error) != nil){
                    print("Error", error)
                }
                if let placemark = placemarks?.first {
                    let coordinates: CLLocationCoordinate2D = placemark.location!.coordinate
                    let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                    
                    
                    let forecastService = ForecastService(APIKey: self.forecastAPIKey)
                    forecastService.getForecast(coordinates.latitude, long: coordinates.longitude) {
                        (let currently) in
                        if let currentWeather = currently {
                            // update ui
                            dispatch_async(dispatch_get_main_queue()) {
                                // execute closure
                                
                                geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                                    let placeArray = placemarks! as [CLPlacemark]
                                    
                                    // place details
                                    var placeMark: CLPlacemark!
                                    placeMark = placeArray[0]
                                    
                                    // Address dictionary
                                    print("New address: \(placeMark.addressDictionary)")
                                    
                                    self.currentCityLabel?.text = "\(placeMark.addressDictionary!["City"] as! NSString), \(placeMark.addressDictionary!["State"] as! NSString)"
                                    
                                    if let temperature = currentWeather.temperature {
                                        self.currentTemperatureLabel?.text = "\(temperature)ºF"
                                    }
                                    
                                    if let humidity = currentWeather.humidity {
                                        self.currentHumidityLabel?.text = "\(humidity)%"
                                    }
                                    
                                    if let precipitation = currentWeather.precipProbability {
                                        self.currentPrecipitationLabel?.text = "\(precipitation)%"
                                    }
                                    
                                    if let icon = currentWeather.icon {
                                        self.currentWeatherIcon?.image = icon
                                    }
                                    
                                    if let summary = currentWeather.summary {
                                        self.currentWeatherSummary?.text = summary
                                    }
                                    
                                    self.toggleRefreshAnimation(false)
                                    
                                }) // close reverse geocode location
                            }
                        }
                    } // getForecast()
                }
            })
            
        } else {
            print("You have not entered a zip code!")
            // put proper error message here
        }
        
//        let message = "Your location is turned off. We recommend you turn it on to get weather data."
//        let title = "Location Services Disabled"
//        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
//        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default)
//            { action -> Void in
//                print("OK Clicked")
//            })
    }
    
    @IBAction func refreshWeather() {
        toggleRefreshAnimation(true)
        getDateInfo()
        retrieveWeatherForecast()
    }
    
    func toggleRefreshAnimation(on: Bool) {
        refreshButton?.hidden = on
        if on {
            activityIndicator?.startAnimating()
            if isConnectedToNetwork() == false  {
                activityIndicator?.stopAnimating()
                refreshButton?.hidden = false
            } else if !CLLocationManager.locationServicesEnabled() {
                activityIndicator?.stopAnimating()
                refreshButton?.hidden = false
            }
        } else {
            activityIndicator?.stopAnimating()
        }
    }
    
    func networkAlertMessage() {
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
        let actionCancel = UIAlertAction(title: "Cancel", style: .Default) { _ in
        }
        let actionSettings = UIAlertAction(title: "Settings", style: .Default) { _ in
            let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alert.addAction(actionSettings)
        alert.addAction(actionCancel)
        self.presentViewController(alert, animated: true){}
    }
    
    func locationAlertMessage() {
        message = "Your location services is disabled. We recommend you turn it on to get weather data."
        alertTitle = "Location Services Disabled"
        let alert = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
        let actionCancel = UIAlertAction(title: "Cancel", style: .Default) { _ in
        }
        let actionSettings = UIAlertAction(title: "Settings", style: .Default) { _ in
            let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        alert.addAction(actionSettings)
        alert.addAction(actionCancel)
        self.presentViewController(alert, animated: true){}
    }
    
    func retrieveWeatherForecast() {
        // error checking if network connection can be made
        if isConnectedToNetwork() == true {
            
            // error checking if location connection can be made
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.startUpdatingLocation()
                
                
                let locValue: CLLocationCoordinate2D = locationManager.location!.coordinate
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude)
                print("1st runLatitude: \(location.coordinate.latitude)\nLongitude: \(location.coordinate.longitude)")
                
                let forecastService = ForecastService(APIKey: forecastAPIKey)
                forecastService.getForecast(location.coordinate.latitude, long: location.coordinate.longitude) {
                    (let currently) in
                    if let currentWeather = currently {
                        // update ui
                        dispatch_async(dispatch_get_main_queue()) {
                            // execute closure
                            
                            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
                                let placeArray = placemarks! as [CLPlacemark]
                                
                                // place details
                                var placeMark: CLPlacemark!
                                placeMark = placeArray[0]
                                
                                // Address dictionary
                                print(placeMark.addressDictionary)
                                
                                self.currentCityLabel?.text = "\(placeMark.addressDictionary!["City"] as! NSString), \(placeMark.addressDictionary!["State"] as! NSString)"
                                
                                if let temperature = currentWeather.temperature {
                                    self.currentTemperatureLabel?.text = "\(temperature)ºF"
                                }
                                
                                if let humidity = currentWeather.humidity {
                                    self.currentHumidityLabel?.text = "\(humidity)%"
                                }
                                
                                if let precipitation = currentWeather.precipProbability {
                                    self.currentPrecipitationLabel?.text = "\(precipitation)%"
                                }
                                
                                if let icon = currentWeather.icon {
                                    self.currentWeatherIcon?.image = icon
                                }
                                
                                if let summary = currentWeather.summary {
                                    self.currentWeatherSummary?.text = summary
                                }
                                
                                self.toggleRefreshAnimation(false)
                                
                            }) // close reverse geocode location
                        }
                    }
                } // getForecast()
                
                // location loading done
                
            } else {
                print("Location services disabled.")
                locationAlertMessage()
            }
        } else {
            networkAlertMessage()
        }
    } // retrieveWeatherForecaster()
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //let locValue: CLLocationCoordinate2D = manager.location!.coordinate
        //let currentLocation = locations.last! as CLLocation
        
        if manager.location != nil {
            // get coordinates from location manager
            latValue = locationManager.location!.coordinate.latitude
            lonValue = locationManager.location!.coordinate.longitude
            coord = (latValue, lonValue)
            
            manager.stopUpdatingLocation()
            print("Latitude: \(latValue)\nLongitude: \(lonValue)")
            print("Coords: \(coord)")
            
        } else {
            print("Location is nil")
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error while updating location " + error.localizedDescription)
    }
    
    func getDateInfo() {
        let hour = calendar.component(.Hour,fromDate: NSDate())
        let dayImage: UIImage = UIImage(named: "Sun")!
        let duskImage: UIImage = UIImage(named: "Blood")!
        let nightImage: UIImage = UIImage(named: "Moon")!
        
        
        switch hour {
        case 0 ... 7:
            currentBackground!.image = duskImage
        case 7 ... 16:
            currentBackground!.image = dayImage
        default:
            currentBackground!.image = nightImage
        }
        
        let todayDate = NSDate()
        let myCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        var myComponents = myCalendar!.components(.Weekday, fromDate: todayDate)
        var weekDayNum = myComponents.weekday
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale.currentLocale()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "dd"
        var dayOfMonthNum = Int(dateFormatter.stringFromDate(todayDate))!
        
        switch weekDayNum {
        case 1: dayOfWeek = "Sunday"
        case 2: dayOfWeek = "Monday"
        case 3: dayOfWeek = "Tuesday"
        case 4: dayOfWeek = "Wednesday"
        case 5: dayOfWeek = "Thursday"
        case 6: dayOfWeek = "Friday"
        case 7: dayOfWeek = "Saturday"
        default: dayOfWeek = ""
        }
        print(dayOfWeek)
        currentDayOfWeek?.text = "\(dayOfWeek), \(dayOfMonthNum)"
        
        let tomorrowDate = NSDate(timeInterval: 86400, sinceDate: todayDate)
        myComponents = myCalendar!.components(.Weekday, fromDate: tomorrowDate)
        
        // ------------ New switch statement for tomorrows date
        
        weekDayNum = myComponents.weekday
        switch weekDayNum {
        case 1: dayOfWeek = "Sunday"
        case 2: dayOfWeek = "Monday"
        case 3: dayOfWeek = "Tuesday"
        case 4: dayOfWeek = "Wednesday"
        case 5: dayOfWeek = "Thursday"
        case 6: dayOfWeek = "Friday"
        case 7: dayOfWeek = "Saturday"
        default: dayOfWeek = ""
        }
        
        dayOfMonthNum = dayOfMonthNum + 1
        
        tomorrowDayOfWeek?.text = "\(dayOfWeek), \(dayOfMonthNum)"

    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

