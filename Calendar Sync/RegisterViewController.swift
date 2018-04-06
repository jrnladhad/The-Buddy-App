//
//  RegisterViewController.swift
//  Calendar Sync
//
//  Created by Jay on 3/22/18.
//  Copyright © 2018 Jay. All rights reserved.
//

import UIKit
import Google
import GoogleSignIn
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import FirebaseAuth
import GoogleAPIClientForREST


class RegisterViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate, FBSDKLoginButtonDelegate {
    
    private let scopes = [kGTLRAuthScopeCalendarReadonly]
    private let service = GTLRCalendarService()
    let facebookSignInButton = FBSDKLoginButton()
    let googleSignInButton = GIDSignInButton()
    let output = UITextView()
    
    @IBOutlet weak var emailCheckAlert: UILabel!
    @IBOutlet weak var passCheckAlert: UILabel!
    @IBOutlet weak var signUpPassAuth: UIButton!
    @IBOutlet weak var userNewPass: UITextField!
    @IBOutlet weak var userPassConfirm: UITextField!
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userName: UITextField!
    
    var refUser: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refUser = Database.database().reference().child("Users")
        
        // Setting the label for unmatch passweord to invisible.
        passCheckAlert.isHidden = true
        emailCheckAlert.isHidden = true
        
        // Configuring Google sign up.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()
        
        
        // Add the Facebook sign up button.
        facebookSignInButton.delegate = self
        facebookSignInButton.frame = CGRect(x: 16, y: 400, width: view.frame.width - 45, height: 28)
        view.addSubview(facebookSignInButton)
        
        // Add the Google sign up button.
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
    
    @IBAction func signUpUser(_ sender: Any) {
        let email = userEmail.text
        let confirmPass = userPassConfirm.text
        let newPass = userNewPass.text
        let name = userName.text
        if (email?.isEmpty)!{
            emailCheckAlert.isHidden = false
        }else{
            emailCheckAlert.isHidden = true
            if newPass == confirmPass{
                passCheckAlert.isHidden = true
                Auth.auth().createUser(withEmail: email!, password: confirmPass!) { (user, error) in
                    if let err = error{
                        print("Unable to connect with Firebase: ", err)
                    }else{
                        guard let uid = user?.uid else{return}
                        print("Successfully created an account: ", uid)
                        let key = Auth.auth().currentUser?.uid
                        let user = ["id": key,
                                    "useremail": email,
                                    "username": name]
                        self.refUser.child(key!).setValue(user)
                        self.performSegue(withIdentifier: "signUpMain", sender: sender)
                    }
                }
            } else if newPass != confirmPass{
                passCheckAlert.isHidden = false
            }
        }
    }
    
    
    func presentSignupAlertView() {
        let alertController = UIAlertController(title: "Error", message: "Couldn't create account", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    
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
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let err = error{
            print("Error: Could not sign up using Facebook: ", err)
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
