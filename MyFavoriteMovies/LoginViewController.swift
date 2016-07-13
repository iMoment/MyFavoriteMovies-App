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
            
            /*
                TODO: Steps for Authentication...
                https://www.themoviedb.org/documentation/api/sessions
                
                Step 1: Create a request token
                Step 2: Ask the user for permission via the API ("login")
                Step 3: Create a session ID
                
                Extra Steps...
                Step 4: Get the user id
                Step 5: Go to the next view
            */
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
        
        // TODO: Get a request token, then store it (appDelegate.requestToken) and login with the token
        
        // 1. Set the parameters
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey : Constants.TMDBParameterValues.ApiKey
        ]
        
        // 2/3. Build the URL, Configure the request
        let request = NSURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/token/new"))
        
        // 4. Make the request
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
            
            // If error, print it and re-enable UI
            func displayError(error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Login Failed."
                }
            }
            
            // Check for error
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            // Check for successful 2XX response
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx.")
                return
            }
            
            // Check if data was returned; not necessary due to guard error check above
            guard let data = data else {
                displayError("No data was returned by the request.")
                return
            }
            
            // 5. Parse the data
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
            
            // 6. Use the data
            print(token)
        }

        // 7. Start the request
        task.resume()
    }
    
    private func loginWithToken(requestToken: String) {
        
        // TODO: Login, then get a session id
        
        // 1. Set the parameters
        // 2/3. Build the URL, Configure the request
        // 4. Make the request
        // 5. Parse the data
        // 6. Use the data!
        // 7. Start the request
    }
    
    private func getSessionID(requestToken: String) {
        
        // TODO: Get a session ID, then store it (appDelegate.sessionID) and get the user's id
        
        // 1. Set the parameters
        // 2/3. Build the URL, Configure the request
        // 4. Make the request
        // 5. Parse the data
        // 6. Use the data!
        // 7. Start the request
    }
    
    private func getUserID(sessionID: String) {
        
        // TODO: Get the user's ID, then store it (appDelegate.userID) for future use and go to next view!
        
        // 1. Set the parameters
        // 2/3. Build the URL, Configure the request
        // 4. Make the request
        // 5. Parse the data
        // 6. Use the data!
        // 7. Start the request
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