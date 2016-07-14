//
//  LoginViewController.swift
//  MyFavoriteMovies

import UIKit

// LoginViewController: UIViewController

class LoginViewController: UIViewController {
    
    // Properties
    
    var appDelegate: AppDelegate!
    var keyboardOnScreen = false
    
    // Outlets
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: BorderedButton!
    @IBOutlet weak var debugTextLabel: UILabel!
    @IBOutlet weak var movieImageView: UIImageView!
        
    // Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate                        
        
        configureUI()
        
        subscribeToNotification(UIKeyboardWillShowNotification, selector: #selector(keyboardWillShow))
        subscribeToNotification(UIKeyboardWillHideNotification, selector: #selector(keyboardWillHide))
        subscribeToNotification(UIKeyboardDidShowNotification, selector: #selector(keyboardDidShow))
        subscribeToNotification(UIKeyboardDidHideNotification, selector: #selector(keyboardDidHide))
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // Login
    
    @IBAction func loginPressed(sender: AnyObject) {
        
        userDidTapView(self)
        
        if usernameTextField.text!.isEmpty || passwordTextField.text!.isEmpty {
            debugTextLabel.text = "Username or Password Empty."
        } else {
            setUIEnabled(false)
            getRequestToken()
        }
    }
    
    private func completeLogin() {
        performUIUpdatesOnMain {
            self.debugTextLabel.text = ""
            self.setUIEnabled(true)
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MoviesTabBarController") as! UITabBarController
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    // TheMovieDB
    
    private func getRequestToken() {
        
        // Set parameters
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey : Constants.TMDBParameterValues.ApiKey
        ]
        
        // Build URL / Configure request
        let request = NSURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/token/new"))
        
        // Make request
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
 
            func displayError(error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Login Failed. (Request Token)"
                }
            }
            
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                displayError("No data was returned by the request.")
                return
            }
            
            // Parsing the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // Check to see if TMDB returned an error (success != true)
            guard let success = parsedResult[Constants.TMDBResponseKeys.Success] as? Bool where success == true else {
                displayError("TMDB returned an error and was not successful.")
                return
            }

            // Check for "request_token" key in parsedResult
            guard let token = parsedResult[Constants.TMDBResponseKeys.RequestToken] as? String else {
                displayError("Cannot find key '\(Constants.TMDBResponseKeys.RequestToken)' in \(parsedResult)")
                return
            }
            
            // Store request token in AppDelegate
            self.appDelegate.requestToken = token
            self.loginWithToken(token)
        }

        // Start the request
        task.resume()
    }
    
    private func loginWithToken(requestToken: String) {
        
        // Set parameters
        let methodParameters: [String : String!] = [
                                Constants.TMDBParameterKeys.ApiKey : Constants.TMDBParameterValues.ApiKey,
                                Constants.TMDBParameterKeys.RequestToken : requestToken,
                                Constants.TMDBParameterKeys.Username : usernameTextField.text,
                                Constants.TMDBParameterKeys.Password : passwordTextField.text]
        
        // Build URL / Configure request
        let request = NSURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/token/validate_with_login"))
        
        // Make request
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
            
            func displayError(error: String, debugLabelText: String? = nil) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Login Failed. (Login Step)"
                }
            }
            
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                displayError("No data was returned by the request.")
                return
            }
        
            // Parsing the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // Check to see if TMDB returned an error (success != true)
            guard let success = parsedResult[Constants.TMDBResponseKeys.Success] as? Bool where success == true else {
                displayError("TMDB returned an error and was not successful.")
                return
            }
            
            // Use requestToken to get the Session ID
            self.getSessionID(requestToken)
        }
        
        // Start the request
        task.resume()
    }
    
    private func getSessionID(requestToken: String) {
        
        // Set parameters
        let methodParameters = [Constants.TMDBParameterKeys.ApiKey : Constants.TMDBParameterValues.ApiKey,
                                Constants.TMDBParameterKeys.RequestToken : requestToken]
        
        // Build URL / Configure request
        let request = NSURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/session/new"))
        
        // Make request
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in

            func displayError(error: String, debugLabelText: String? = nil) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Login Failed. (Session ID)"
                }
            }
            
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                displayError("No data was returned by the request.")
                return
            }
            
            // Parsing the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // Check to see if TMDB returned an error (success != true)
            guard let success = parsedResult[Constants.TMDBResponseKeys.Success] as? Bool where success == true else {
                displayError("TMDB returned an error and was not successful.")
                return
            }
            
            // Check for "session_id" key in parsedResult
            guard let sessionID = parsedResult[Constants.TMDBResponseKeys.SessionID] as? String else {
                displayError("Cannot find key '\(Constants.TMDBResponseKeys.SessionID)' in \(parsedResult)")
                return
            }
            
            // Store sessionID in AppDelegate, use to get User ID
            self.appDelegate.sessionID = sessionID
            self.getUserID(sessionID)
        }
        
        // Start the request
        task.resume()
    }
    
    private func getUserID(sessionID: String) {
        
        // Set parameters
        let methodParameters = [Constants.TMDBParameterKeys.ApiKey : Constants.TMDBParameterValues.ApiKey,
                                Constants.TMDBParameterKeys.SessionID : sessionID]
        
        // Build URL / Configure request
        let request = NSURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/account"))
        
        // Make request
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
            
            func displayError(error: String, debugLabelText: String? = nil) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Login Failed. (User ID)"
                }
            }
            
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx.")
                return
            }
            
            guard let data = data else {
                displayError("No data was returned by the request.")
                return
            }
            
            // Parsing the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            // Check for "id" key in parsedResult
            guard let id = parsedResult[Constants.TMDBResponseKeys.UserID] as? Int else {
                displayError("Cannot find key '\(Constants.TMDBResponseKeys.UserID)' in \(parsedResult)")
                return
            }
            
            // Store id in AppDelegate, complete the Login
            self.appDelegate.userID = id
            self.completeLogin()
        }
        
        // Start the request
        task.resume()
    }
}

// LoginViewController: UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    
    // UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Show/Hide Keyboard
    
    func keyboardWillShow(notification: NSNotification) {
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
            movieImageView.hidden = true
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
            movieImageView.hidden = false
        }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        keyboardOnScreen = true
    }
    
    func keyboardDidHide(notification: NSNotification) {
        keyboardOnScreen = false
    }
    
    private func keyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    private func resignIfFirstResponder(textField: UITextField) {
        if textField.isFirstResponder() {
            textField.resignFirstResponder()
        }
    }
    
    @IBAction func userDidTapView(sender: AnyObject) {
        resignIfFirstResponder(usernameTextField)
        resignIfFirstResponder(passwordTextField)
    }
}

// LoginViewController (Configure UI)

extension LoginViewController {
    
    private func setUIEnabled(enabled: Bool) {
        usernameTextField.enabled = enabled
        passwordTextField.enabled = enabled
        loginButton.enabled = enabled
        debugTextLabel.text = ""
        debugTextLabel.enabled = enabled
        
        // Adjust login button alpha
        if enabled {
            loginButton.alpha = 1.0
        } else {
            loginButton.alpha = 0.5
        }
    }
    
    private func configureUI() {
        
        // Configure background gradient
        let backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [Constants.UI.LoginColorTop, Constants.UI.LoginColorBottom]
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.frame = view.frame
        view.layer.insertSublayer(backgroundGradient, atIndex: 0)
        
        configureTextField(usernameTextField)
        configureTextField(passwordTextField)
    }
    
    private func configureTextField(textField: UITextField) {
        let textFieldPaddingViewFrame = CGRectMake(0.0, 0.0, 13.0, 0.0)
        let textFieldPaddingView = UIView(frame: textFieldPaddingViewFrame)
        textField.leftView = textFieldPaddingView
        textField.leftViewMode = .Always
        textField.backgroundColor = Constants.UI.GreyColor
        textField.textColor = Constants.UI.BlueColor
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        textField.tintColor = Constants.UI.BlueColor
        textField.delegate = self
    }
}

// LoginViewController (Notifications)

extension LoginViewController {
    
    private func subscribeToNotification(notification: String, selector: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: notification, object: nil)
    }
    
    private func unsubscribeFromAllNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}