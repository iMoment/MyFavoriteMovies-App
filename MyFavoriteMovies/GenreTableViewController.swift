//
//  GenreTableViewController.swift
//  MyFavoriteMovies

import UIKit

// GenreTableViewController: UITableViewController

class GenreTableViewController: UITableViewController {
    
    // Properties
    
    var appDelegate: AppDelegate!
    var movies: [Movie] = [Movie]()
    var genreID: Int? = nil
    
    // Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        // Get the correct genre id
        genreID = genreIDFromItemTag(tabBarItem.tag)
        
        // Create and set logout button
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: #selector(logout))
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        
        // TODO: Get movies by a genre id, then populate the table
        
        // 1. Set the parameters
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
        ]
        
        // 2/3. Build the URL, Configure the request
        let request = NSMutableURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/genre/\(genreID!)/movies"))
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // 4. Make the request
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
            
            // Check for error
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            // Check for successful 2XX response
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx!")
                return
            }
            
            // Check if data was returned; not necessary due to guard error check above
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            // 5. Parse the data
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
            
            // 6. Use the data
            self.movies = Movie.moviesFromResults(results)
            performUIUpdatesOnMain {
                self.tableView.reloadData()
            }
        }
        
        // 7. Start the request
        task.resume()
    }
    
    // Logout
    
    func logout() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// GenreTableViewController (UITableViewController)

extension GenreTableViewController {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Get cell type
        let cellReuseIdentifier = "MovieTableViewCell"
        let movie = movies[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier) as UITableViewCell!
        
        // Set cell defaults
        cell.textLabel!.text = movie.title
        cell.imageView!.image = UIImage(named: "Film Icon")
        cell.imageView!.contentMode = UIViewContentMode.ScaleAspectFit
        
        // TODO: Get the poster image, then populate the image view
        if let posterPath = movie.posterPath {
            
            // 1. Set the parameters
            // There are none.
            
            // 2. Build the URL
            let baseURL = NSURL(string: appDelegate.config.baseImageURLString)!
            let url = baseURL.URLByAppendingPathComponent("w154").URLByAppendingPathComponent(posterPath)
            
            // 3. Configure the request
            let request = NSURLRequest(URL: url)
            
            // 4. Make the request
            let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
                
                // Check for error
                guard (error == nil) else {
                    print("There was an error with your request: \(error)")
                    return
                }
                
                // Check for successful 2XX response
                guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                    print("Your request returned a status code other than 2xx!")
                    return
                }
                
                // Check if data was returned; not necessary due to guard error check above
                guard let data = data else {
                    print("No data was returned by the request!")
                    return
                }
                
                // 5. Parse the data
                // No need, the data is already raw image data.
                
                // 6. Use the data
                if let image = UIImage(data: data) {
                    performUIUpdatesOnMain {
                        cell.imageView!.image = image
                    }
                } else {
                    print("Could not create image from \(data)")
                }
            }
            
            // 7. Start the request
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

// GenreTableViewController (Genre Map)

extension GenreTableViewController {
    
    private func genreIDFromItemTag(itemTag: Int) -> Int {
        
        let genres: [String] = [
            "Sci-Fi",
            "Comedy",
            "Action"
        ]
        
        let genreMap: [String:Int] = [
            "Action": 28,
            "Sci-Fi": 878,
            "Comedy": 35
        ]
        
        return genreMap[genres[itemTag]]!
    }    
}