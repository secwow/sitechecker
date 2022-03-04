//
//  Storage.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 27.02.2022.
//

import Foundation

class Storage {
    static let shared = Storage()
    private let onboardingKey = "onboarding"
    private let firstLaunchKey = "firstKey"

    
    private init() {}
    
    func onboardingPassed() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: onboardingKey)
    }
    
    var isOnboardingPassed: Bool {
        return UserDefaults.standard.bool(forKey: onboardingKey)
    }
    
    var isFirstLaunch: Bool {
        return UserDefaults.standard.bool(forKey: firstLaunchKey) == false
    }
    
    func firstLaunchOccured() {
        UserDefaults.standard.set(true, forKey: firstLaunchKey)
        UserDefaults.standard.synchronize()
    }
}
