//
//  SitesList.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import Foundation

enum SitesList {
    static let sitesWithNames: [(String, URL)] = [
        ("Президент России", "http://www.kremlin.ru/"),
        ("Совет Безопасности Российской Федерации", "http://www.scrf.gov.ru/"),
        ("Совет Федерации", "http://sovetnational.ru/"),
        ("Совет при президенте Российской Федерации", "http://president-sovet.ru/"),
        ("Совет Федерации Федерального собрания Российской Федерации", "http://www.council.gov.ru/"),
        ("Государственная Дума", "http://www.duma.gov.ru/"),
        ("Конституционный суд Российской Федерации", "http://www.ksrf.ru/"),
        ("Верховный Суд Российской Федерации", "http://www.vsrf.ru/"),
        ("Правительство России", "http://government.ru/"),
        ("МВД России", "http://mvd.ru/"),
        ("МВД России", "https://xn--b1aew.xn--p1ai/"),
        ("МЧС России", "https://www.mchs.gov.ru/"),
        ("МИД", "http://www.mid.ru/ru/home"),
        ("Министерство обороны Российской Федерации", "https://mil.ru/"),
        ("Министерство юстиции Российской Федерации", "https://minjust.gov.ru/"),
        ("Министерство здравоохранения Российской Федерации", "https://minzdrav.gov.ru/"),
        ("Министерство культуры Российской Федерации", "http://mkrf.ru/"),
        ("Министерство просвещения РФ", "http://edu.gov.ru/"),
        ("Министерство науки и высшего образования РФи", "http://minobrnauki.gov.ru/"),
        ("Минприроды России", "http://www.mnr.gov.ru/"),
        ("Минпромторги", "http://minpromtorg.gov.ru/"),
        ("Министерство Российской Федерации по развитию Дальнего Востока и Арктики", "http://minvr.ru/"),
        ("Министерство сельского хозяйства Российской Федерации", "http://www.mcx.ru/"),
        ("Министерство спорта Российской Федерации", "http://www.minsport.gov.ru/"),
        ("Минстрой России", "http://www.minstroyrf.ru/"),
        ("Министерство транспорта Российской Федерации", "http://www.mintrans.ru/"),
        ("Министерство труда и социальной защиты РФ", "http://www.rosmintrud.ru/"),
        ("Минфин России Мобильный", "http://minfin.ru/"),
        ("Министерство экономического развития", "http://economy.gov.ru/"),
        ("Минэнерго России", "http://minenergo.gov.ru/"),
        ("ФСВТС России", "http://www.fsvts.gov.ru/"),
        ("Федеральная службы по техническому и экспортному контролю", "http://www.fstec.ru/"),
        ("ФСИН России", "http://www.fsin.su"),
        ("Федеральная служба судебных приставов", "http://www.fssprus.ru/"),
        ("ГОСУДАРСТВЕННАЯ ФЕЛЬДЪЕГЕРСКАЯ СЛУЖБА РОССИЙСКОЙ ФЕДЕРАЦИИ".lowercased().capitalized, "http://gfs.gov.ru/"),
        ("Служба внешней разведки Российской Федерации", "http://svr.gov.ru/"),
        ("ФСБ России", "http://www.fsb.ru/"),
        ("Росгвардия", "http://rosgvard.ru/"),
        ("ФСО России", "http://www.fso.gov.ru/"),
        ("Федеральная служба по финансовому мониторингу", "http://www.fedsfm.ru/"),
        ("Росгидромет", "http://www.meteorf.ru/"),
        ("Росприроднадзор", "http://rpn.gov.ru/"),
        ("Россельхознадзор", "http://www.fsvps.ru/"),
        ("Ространснадзор", "http://www.rostransnadzor.ru/"),
        ("Государственная инспекция труда", "http://www.rostrud.ru/"),
        ("Министерство по налогам и сборам", "http://www.nalog.ru/"),
        ("Федеральная пробирная палата", "http://www.probpalata.ru"),
        ("Федеральная служба по регулированию алкогольного рынка", "http://fsrar.ru/"),
        ("Федеральная таможенная служба", "http://www.customs.gov.ru/"),
        ("Официальный сайт Казначейства России", "http://www.roskazna.ru/"),
        ("Роскомнадзор", "http://rkn.gov.ru/"),
        ("Федеральная служба по аккредитации", "http://www.fsa.gov.ru/"),
        ("Cбербанк", "https://www.sberbank.ru"),
        ("Банк ВТБ", "https://www.vtb.ru/")

    ].map { (name, url) -> (String, URL) in
        return (name, URL(string: url)!)
    }
    @UserDefault(key: "local_sites", defaultValue: [])
    static var localSites: [String]
}

@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    var container: UserDefaults = .standard

    var wrappedValue: Value {
        get {
            return container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            container.set(newValue, forKey: key)
        }
    }
}


