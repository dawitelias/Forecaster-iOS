//
//  CurrentWeather.swift
//  Forecaster
//
//  Created by Dawit Elias on 11/12/15.
//  Copyright © 2015 Dawit Elias. All rights reserved.
//

import Foundation
import UIKit

enum Icon: String {
    // define member for every possible instance of icon type from Forecast.io api
    // 10 possible values; clear-day, clear-night, rain, etc
    case ClearDay = "clear-day"
    case ClearNight = "clear-night"
    case Rain = "rain"
    case Snow = "snow"
    case Sleet = "sleet"
    case Wind = "wind"
    case Fog = "fog"
    case Cloudy = "cloudy"
    case PartlyCloudyDay = "partly-cloudy-day"
    case PartlyCloudyNight = "partly-cloudy-night"
    
    func toImage() -> UIImage? {
        var imageName: String
        
        switch self {
            
        case .ClearDay:
            imageName = "clear-day.png"
        case .ClearNight:
            imageName = "clear-night.png"
        case .Cloudy:
            imageName = "cloudy.png"
        case .Fog:
            imageName = "fog.png"
        case .PartlyCloudyDay:
            imageName = "partly-cloudy-day.png"
        case .PartlyCloudyNight:
            imageName = "partly-cloudy-night.png"
        case .Rain:
            imageName = "rain.png"
        case .Sleet:
            imageName = "sleet.png"
        case .Snow:
            imageName = "snow.png"
        case .Wind:
            imageName = "wind.png"
        }

        return UIImage(named: imageName)
    }

}

struct CurrentWeather {

    let temperature: Int?
    let humidity: Int?
    let precipProbability: Int?
    let summary: String?
    
    var icon: UIImage? = UIImage(named: "cloudy-day.png")
    
    init(weatherDictionary: [String: AnyObject]) {
        temperature = weatherDictionary["temperature"] as? Int
        if let humidityFloat = weatherDictionary["humidity"] as? Double {
            humidity = Int(humidityFloat * 100)
        } else {
            humidity = nil
        }
        
        if let precipFloat = weatherDictionary["precipProbability"] as? Double {
            precipProbability = Int(precipFloat * 100)
        } else {
            precipProbability = nil
        }
        
        summary = weatherDictionary["summary"] as? String
        
        if let iconString = weatherDictionary["icon"] as? String,
            let weatherIcon: Icon = Icon(rawValue: iconString) {
            icon = weatherIcon.toImage()
        }
        
    }
    
}