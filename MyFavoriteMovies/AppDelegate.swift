//
//  AppDelegate.swift
//  MyFavoriteMovies

import UIKit

// AppDelegate: UIResponder, UIApplicationDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MProperties
    
    var window: UIWindow?
    
    var sharedSession = NSURLSession.sharedSession()
    var requestToken: String? = nil
    var sessionID: String? = nil
    var userID: Int? = nil
    
    // Configuration for TheMovieDB
    var config = Config()
    
    // UIApplicationDelegate
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        
        // If necessary, update the configuration...
        config.updateIfDaysSinceUpdateExceeds(7)
        
        return true
    }
}

// Create URL from Parameters

extension AppDelegate {
    
    func tmdbURLFromParameters(parameters: [String:AnyObject], withPathExtension: String? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.TMDB.ApiScheme
        components.host = Constants.TMDB.ApiHost
        components.path = Constants.TMDB.ApiPath + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
}