//
//  SitesList.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import Foundation

enum SitesList {
    static let sitesWithNames: [(String, URL)] = [
        ("Cбербанк", "https://www.sberbank.ru"),
        ("Банк ВТБ", "https://www.vtb.ru/")
    ].map { (name, url) -> (String, URL) in
        return (name, URL(string: url)!)
    }
    @UserDefault(key: "local_sites", defaultValue: [])
    static var localSites: [AvalibilityViewModel]
    
    @UserDefault(key: "target", defaultValue: [])
    static var target: [URL]
}

@propertyWrapper
struct UserDefault<Value: Codable> {
    let key: String
    let defaultValue: Value
    var container: UserDefaults = .standard

    var wrappedValue: Value {
        get {
            guard let data = container.data(forKey: key) else {
                return defaultValue
            }
            let model = try? JSONDecoder().decode(Value.self, from: data)
            return model ?? defaultValue
        }
        set {
            guard let model = try? JSONEncoder().encode(newValue) else {
                return
            }
            container.set(model, forKey: key)
        }
    }
}


