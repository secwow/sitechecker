//
//  RootComponent.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 27.02.2022.
//

import Foundation
import UIKit

class RootCompontent {
    private let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        self.window.makeKeyAndVisible()
        
        var vc: UIViewController?
        
        if Storage.shared.isOnboardingPassed {
            vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "SitesListViewController")
        } else {
            vc = UIStoryboard(name: "Tutorial", bundle: .main).instantiateViewController(withIdentifier: "Onboarding")
        }
        
        window.rootViewController = vc
    }
}
