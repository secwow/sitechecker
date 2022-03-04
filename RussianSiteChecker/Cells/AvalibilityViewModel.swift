//
//  AvalibilityModel.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import Foundation

class AvalibilityViewModel: Hashable, Codable {
    init(name: String, url: URL, available: Bool, method: String? = nil) {
        self.name = name
        self.url = url
        self.available = available
        self.method = method
    }

    let name: String
    let url: URL
    let method: String?
    var available: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: AvalibilityViewModel, rhs: AvalibilityViewModel) -> Bool {
        return lhs.url == rhs.url
    }
}
