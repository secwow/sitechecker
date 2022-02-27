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
    
    private init() {}
    
    func onboardingPassed() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: onboardingKey)
    }
    
    var isOnboardingPassed: Bool {
        return UserDefaults.standard.bool(forKey: onboardingKey) ?? false
    }
}
