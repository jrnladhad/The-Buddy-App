//
//  ViewController.swift
//  Calendar Sync
//
//  Created by Jay on 3/21/18.
//  Copyright © 2018 Jay. All rights reserved.
//

import UIKit
import GoogleSignIn
import Google
import Firebase
import FirebaseAuth
import GoogleAPIClientForREST
import FBSDKLoginKit
import EventKit

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate, FBSDKLoginButtonDelegate, UITableViewDelegate {
    
    @IBOutlet weak var signInUser: UIButton!
    @IBOutlet weak var passSignIn: UITextField!
    @IBOutlet weak var emailSignIn: UITextField!
    @IBOutlet weak var signUpView: UIButton!
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLRAuthScopeCalendarReadonly]
    private let service = GTLRCalendarService()
    let facebookSignInButton = FBSDKLoginButton()
    let googleSignInButton = GIDSignInButton()
    let output = UITextView()
    let eventStore = EKEventStore()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Configure Facebook Sign-in.
        facebookSignInButton.delegate = self
        facebookSignInButton.frame = CGRect(x: 16, y: 400, width: view.frame.width - 45, height: 28)
        view.addSubview(facebookSignInButton)
        
        // Configure Google Sign-in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()
        
        // Add the sign-in button.
        // Change x value for moving horizontal, y to move vertical, width to change the width of the sign in button, height to change the height of button
        googleSignInButton.frame = CGRect(x: 16, y: 500, width: view.frame.width - 45, height: 50)
        view.addSubview(googleSignInButton)
        
        // Add a UITextView to display output.
        output.frame = view.bounds
        output.isEditable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        output.isHidden = true
        view.addSubview(output);
    }
    
        
    @IBAction func signUpUser(_ sender: UIButton) {
        performSegue(withIdentifier: "registerUser", sender: sender)
    }
    
    @IBAction func emailSignInUser(_ sender: UIButton) {
        let email = emailSignIn.text
        let pass = passSignIn.text
        Auth.auth().signIn(withEmail: email!, password: pass!) { (user, error) in
            if let err = error{
                print("Unable to login with given credetials: ", err)
            }else{
                guard let uid = user?.uid else{return}
                print("Successfully logged in using Email: ", uid)
                self.performSegue(withIdentifier: "signInMain", sender: sender)
            }
        }
    }
    
    
    
    // Facebook login and logout configuration.
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let err = error{
            showAlert(title: "Authentication Error", message: err.localizedDescription)
        }else{
            print("Successfully logged into Facebook: ", result)
            let f_credentials = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            Auth.auth().signIn(with: f_credentials) { (user, error) in
                if let err = error
                {
                    print("Failed to createa Firebase user with Facebook account: ", err)
                }
                guard let uid = user?.uid else{return}
                print("Successfully logged into Firebase with Facebook: ", uid)
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        let firebase = Auth.auth()
        do{
            try firebase.signOut()
        }catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    // Google sign in configuration.
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        } else {
            print("Successfully logged into Google: ", user)
            guard let authetication = user.authentication else{return}
            let g_credetials = GoogleAuthProvider.credential(withIDToken: authetication.idToken, accessToken: authetication.accessToken)
            Auth.auth().signIn(with: g_credetials) { (user, error) in
                if let err = error
                {
                    print("Failed to create a Firebase user with Google account: ", err)
                    return
                }
                guard let uid = user?.uid else{return}
                print("Successfully logged into Firebase with Google: ", uid)
            }
            self.googleSignInButton.isHidden = true
            self.output.isHidden = false
            self.service.authorizer = user.authentication.fetcherAuthorizer()
            fetchEvents()
        }
    }
    
    // Accessing iphone calendar.
    
    // Construct a query and get a list of upcoming events from the user calendar
    func fetchEvents() {
        let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
        query.maxResults = 10
        query.timeMin = GTLRDateTime(date: Date())
        query.singleEvents = true
        query.orderBy = kGTLRCalendarOrderByStartTime
        service.executeQuery(
            query,
            delegate: self,
            didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:)))
    }
    
    // Display the start dates and event summaries in the UITextView
    @objc func displayResultWithTicket(
        ticket: GTLRServiceTicket,
        finishedWithObject response : GTLRCalendar_Events,
        error : NSError?) {
        
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        
        var outputText = ""
        if let events = response.items, !events.isEmpty {
            for event in events {
                let start = event.start!.dateTime ?? event.start!.date!
                let startString = DateFormatter.localizedString(
                    from: start.date,
                    dateStyle: .short,
                    timeStyle: .short)
                outputText += "\(startString) - \(event.summary!)\n"
            }
        } else {
            outputText = "No upcoming events found."
        }
        output.text = outputText
    }
    
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }


}

