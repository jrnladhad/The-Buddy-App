//
//  UserList.swift
//  Calendar Sync
//
//  Created by Jay on 4/3/18.
//  Copyright © 2018 Jay. All rights reserved.
//

import UIKit
import Firebase


class UserList: UIViewController, UISearchBarDelegate {

    
    @IBOutlet weak var searchFriends: UISearchBar!
    
    var refUser: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refUser = Database.database().reference()
    }
    func userSearch()
    {
        let searchText = searchFriends.text
        refUser.child("Users").queryOrdered(byChild: "username").queryStarting(atValue: searchText, childKey: "username").queryEnding(atValue: searchText! + "\u{f8ff}", childKey: "username").observeSingleEvent(of: .value) { (snapshot) in
            print(snapshot)
        }
        
    }
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        userSearch()
        return true
    }

}

