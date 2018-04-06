//
//  MainDisplay.swift
//  Calendar Sync
//
//  Created by Jay on 3/24/18.
//  Copyright © 2018 Jay. All rights reserved.
//

import UIKit

class MainDisplay: UIViewController {

    
    @IBOutlet weak var users: UIButton!
    @IBOutlet weak var workout: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func scheduleWorkout(_ sender: Any) {
        
    }
    
    @IBAction func userTapped(_ sender: Any) {
        performSegue(withIdentifier: "Userlist", sender: sender)
    }
}
