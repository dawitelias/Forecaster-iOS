//
//  NetworkOperation.swift
//  Forecaster
//
//  Created by Dawit Elias on 12/7/15.
//  Copyright © 2015 Dawit Elias. All rights reserved.
//

import Foundation

class NetworkOperation {

    // lazy annotation for lazy loading
    lazy var config: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
    lazy var session: NSURLSession = NSURLSession(configuration: self.config)
    let queryURL: NSURL
    
    typealias JSONDictionaryCompletion = ([String: AnyObject]?) -> Void

    
    init(url: NSURL) {
        self.queryURL = url
    }
    
    func downloadJSONFromURL(completion: JSONDictionaryCompletion) {
        let request: NSURLRequest = NSURLRequest(URL: queryURL)
        let dataTask = session.dataTaskWithRequest(request) {
            (let data, let response, let error) in
            
            // check response response status for success (GET) code
            if let httpResponse = response as? NSHTTPURLResponse {
                
                switch(httpResponse.statusCode) {
                case 200:
                    // create json object w/ return data
                    do {
                        let jsonDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String: AnyObject]
                        completion(jsonDictionary)
                    } catch {
                        print("JSON serialization failed.")
                    }
                default:
                    print("GET request not successful. HTTP status code: \(httpResponse.statusCode)")
                }
                
            } else {
                print("Error: Not a valid HTTP response")
            }
            
        } // dataTask
        
        // start data task
        dataTask.resume()
    }
    
    
}