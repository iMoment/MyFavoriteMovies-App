//
//  Movie.swift
//  MyFavoriteMovies

import UIKit

// Movie

struct Movie {
    
    // Properties
    
    let title: String
    let id: Int
    let posterPath: String?
    
    // Initializers
    
    init(dictionary: [String : AnyObject]) {
        title = dictionary[Constants.TMDBResponseKeys.Title] as! String
        id = dictionary[Constants.TMDBResponseKeys.ID] as! Int
        posterPath = dictionary[Constants.TMDBResponseKeys.PosterPath] as? String
    }
    
    static func moviesFromResults(results: [[String:AnyObject]]) -> [Movie] {
        
        var movies = [Movie]()
        
        // Iterate through array of dictionaries, each Movie is a dictionary
        for result in results {
            movies.append(Movie(dictionary: result))
        }
        
        return movies
    }
    
}

// Movie: Equatable

extension Movie: Equatable {}

func ==(lhs: Movie, rhs: Movie) -> Bool {
    return lhs.id == rhs.id
}