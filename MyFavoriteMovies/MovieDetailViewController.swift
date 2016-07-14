//
//  MovieDetailViewController.swift
//  MyFavoriteMovies

import UIKit

// MovieDetailViewController: UIViewController

class MovieDetailViewController: UIViewController {
    
    // Properties
    
    var appDelegate: AppDelegate!
    var isFavorite = false
    var movie: Movie?
    
    // Outlets
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    // Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let movie = movie {
            
            // Setting some defaults
            posterImageView.image = UIImage(named: "film342.png")
            titleLabel.text = movie.title
            
            // Set parameters
            let methodParameters = [
                Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
                Constants.TMDBParameterKeys.SessionID: appDelegate.sessionID!
            ]
            
            // Build URL / Configure request
            let request = NSMutableURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/account/\(appDelegate.userID!)/favorite/movies"))
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // Make request
            let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
                
                guard (error == nil) else {
                    print("There was an error with your request: \(error)")
                    return
                }
                
                guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                    print("Your request returned a status code other than 2xx!")
                    return
                }
                
                guard let data = data else {
                    print("No data was returned by the request!")
                    return
                }
                
                // Parsing the data
                let parsedResult: AnyObject!
                do {
                    parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                } catch {
                    print("Could not parse the data as JSON: '\(data)'")
                    return
                }
                
                // Check for TheMovieDB error
                if let _ = parsedResult[Constants.TMDBResponseKeys.StatusCode] as? Int {
                    print("TheMovieDB returned an error. See the '\(Constants.TMDBResponseKeys.StatusCode)' and '\(Constants.TMDBResponseKeys.StatusMessage)' in \(parsedResult)")
                    return
                }
                
                // Check for "results" key in parsedResult
                guard let results = parsedResult[Constants.TMDBResponseKeys.Results] as? [[String:AnyObject]] else {
                    print("Cannot find key '\(Constants.TMDBResponseKeys.Results)' in \(parsedResult)")
                    return
                }
                
                // Utilize data
                let movies = Movie.moviesFromResults(results)
                self.isFavorite = false
                
                for movie in movies {
                    if movie.id == self.movie!.id {
                        self.isFavorite = true
                    }
                }
                
                performUIUpdatesOnMain {
                    self.favoriteButton.tintColor = (self.isFavorite) ? nil : UIColor.blackColor()
                }
            }
            
            // Start the request
            task.resume()
            
            // Get the poster image, then populate the image view
            if let posterPath = movie.posterPath {
                
                // Set the parameters
                // There are none.
                
                // Build URL
                let baseURL = NSURL(string: appDelegate.config.baseImageURLString)!
                let url = baseURL.URLByAppendingPathComponent("w342").URLByAppendingPathComponent(posterPath)
                
                // Configure request
                let request = NSURLRequest(URL: url)
                
                // Make request
                let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
                    
                    guard (error == nil) else {
                        print("There was an error with your request: \(error)")
                        return
                    }
                    
                    guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                        print("Your request returned a status code other than 2xx!")
                        return
                    }
                    
                    guard let data = data else {
                        print("No data was returned by the request!")
                        return
                    }
                    
                    // Parse data
                    // No need, the data is already raw image data.
                    
                    // Utilize data
                    if let image = UIImage(data: data) {
                        performUIUpdatesOnMain {
                            self.posterImageView!.image = image
                        }
                    } else {
                        print("Could not create image from \(data)")
                    }
                }
                
                // Start the request
                task.resume()
            }
        }
    }
    
    // Favorite Actions
    
    @IBAction func toggleFavorite(sender: AnyObject) {
        
         let shouldFavorite = !isFavorite
        
        // Set parameters
        let methodParameters = [Constants.TMDBParameterKeys.ApiKey : Constants.TMDBParameterValues.ApiKey,
                                Constants.TMDBParameterKeys.SessionID : appDelegate.sessionID!]
        
        // Build URL / Configure request
        let request = NSMutableURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/account/\(appDelegate.userID!)/favorite"))
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "{\"media_type\": \"movie\",\"media_id\": \(movie!.id),\"favorite\": \(shouldFavorite)}".dataUsingEncoding(NSUTF8StringEncoding)
        
        // Make request
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
            
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                print("No data was returned by the request.")
                return
            }
            
            // Parsing the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // Check for TMDB status_code
            guard let tmdbStatusCode = parsedResult[Constants.TMDBResponseKeys.StatusCode] as? Int else {
                print("Could not find key '\(Constants.TMDBResponseKeys.StatusCode)' in \(parsedResult)")
                return
            }
            
            // Check for correct TMDB status_code
            if shouldFavorite && !(tmdbStatusCode == 12 || tmdbStatusCode == 1) {
                print("Unrecognized '\(Constants.TMDBResponseKeys.StatusCode)' in \(parsedResult)")
                return
            } else if !shouldFavorite && tmdbStatusCode != 13 {
                print("Unrecognized '\(Constants.TMDBResponseKeys.StatusCode)' in \(parsedResult)")
                return
            }
            
            // Utilize data
            self.isFavorite = shouldFavorite
            performUIUpdatesOnMain {
                self.favoriteButton.tintColor = (shouldFavorite) ? nil : UIColor.blackColor()
            }
            
        }
        
        // Start the request
        task.resume()
    }
}