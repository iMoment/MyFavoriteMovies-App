//
//  FavoritesTableViewController.swift
//  MyFavoriteMovies

import UIKit

// FavoritesTableViewController: UITableViewController

class FavoritesTableViewController: UITableViewController {
    
    // Properties
    
    var appDelegate: AppDelegate!
    var movies: [Movie] = [Movie]()
    
    // Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        // Create and set logout button
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: #selector(logout))
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
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
            self.movies = Movie.moviesFromResults(results)
            performUIUpdatesOnMain {
                self.tableView.reloadData()
            }
        }
        
        // Start the request
        task.resume()
    }
    
    // Logout
    
    func logout() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// FavoritesTableViewController (UITableViewController)

extension FavoritesTableViewController {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Get cell type
        let cellReuseIdentifier = "FavoriteTableViewCell"
        let movie = movies[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier) as UITableViewCell!
        
        // Set cell defaults
        cell.textLabel!.text = movie.title
        cell.imageView!.image = UIImage(named: "Film Icon")
        cell.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        
        // Get the poster image, then populate the image view
        if let posterPath = movie.posterPath {
            
            // Set parameters
            // There are none.
            
            // Build URL
            let baseURL = NSURL(string: appDelegate.config.baseImageURLString)!
            let url = baseURL.URLByAppendingPathComponent("w154").URLByAppendingPathComponent(posterPath)
            
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
                
                // Parse the data
                // No need, the data is already raw image data.
                
                // Utilize data
                if let image = UIImage(data: data) {
                    performUIUpdatesOnMain {
                        cell.imageView!.image = image
                    }
                } else {
                    print("Could not create image from \(data)")
                }
            }
            
            // Start the request
            task.resume()
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Push the movie detail view
        let controller = storyboard!.instantiateViewControllerWithIdentifier("MovieDetailViewController") as! MovieDetailViewController
        controller.movie = movies[indexPath.row]
        navigationController!.pushViewController(controller, animated: true)
    }
}