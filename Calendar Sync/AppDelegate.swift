//
//  AppDelegate.swift
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
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate{
    
    
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication)
    {
        // Initialize sign-in
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let err = error
        {
            print("Unable to log in to Google: ", err)
            return
        }
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
    }
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool
    {
        
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool
    {
        _ = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        return GIDSignIn.sharedInstance().handle(url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])
    }
}

