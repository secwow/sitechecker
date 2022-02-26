//
//  AvalibilityModel.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import Foundation

class AvalibilityViewModel: Hashable {
    internal init(name: String, url: URL, avaliable: Bool) {
        self.name = name
        self.url = url
        self.avaliable = avaliable
    }
    
    var name: String
    var url: URL
    var avaliable: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: AvalibilityViewModel, rhs: AvalibilityViewModel) -> Bool {
        return lhs.url == rhs.url
    }
}
