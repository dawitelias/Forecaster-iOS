//
//  ForecastService.swift
//  Forecaster
//
//  Created by Dawit Elias on 12/7/15.
//  Copyright © 2015 Dawit Elias. All rights reserved.
//

import Foundation

struct ForecastService {
    
    let forecastAPIKey : String
    let forecastBaseURL: NSURL?
    
    init(APIKey: String) {
        forecastAPIKey = APIKey
        forecastBaseURL = NSURL(string: "https://api.forecast.io/forecast/\(forecastAPIKey)/")
    }
    
    func getForecast(lat: Double, long: Double, completion: (CurrentWeather? -> Void)) {
        if let forecastURL = NSURL(string: "\(lat),\(long)", relativeToURL: forecastBaseURL) {
            
            let networkOperation = NetworkOperation(url: forecastURL)

            networkOperation.downloadJSONFromURL {
                (let JSONDictionary) in
                let currentWeather = self.currentWeatherFromJSON(JSONDictionary)
                completion(currentWeather)
            }
            
        } else {
            // in case we can't construct url
            print("Could not construct a valid URL")
        }
    }
    
    func currentWeatherFromJSON(jsonDictionary: [String: AnyObject]?) -> CurrentWeather? {
        // check that dictionary returns non-nil value
        if let currentWeatherDict = jsonDictionary?["currently"] as? [String: AnyObject] {
            return CurrentWeather(weatherDictionary: currentWeatherDict)
        } else {
            print("JSON dictionary returned nil for 'currently' key")
            return nil
        }
    }
    
}