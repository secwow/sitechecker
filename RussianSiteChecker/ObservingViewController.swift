//
//  ObservingViewController.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import UIKit
import OSLog

class ObservingViewController: UIViewController {
    @IBOutlet weak var siteName: UILabel!
    @IBOutlet weak var avalibilityLabel: UILabel!
    var url: URL! {
        didSet {
            guard isViewLoaded else { return }
            setName(url)
        }
    }
    private var lock = NSLock()
    var avalibility: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _avalibility
        }
        
        set {
            lock.lock()
            defer { lock.unlock() }
            _avalibility = newValue
        }
    }
    private var _avalibility: Bool = true {
        didSet {
            guard isViewLoaded else { return }
            DispatchQueue.main.async { [weak self] in
                self?.setAvailiable(self?._avalibility ?? false)
            }
        }
    }
    @IBOutlet weak var checkAvailibilityButton: UIButton!
    private var shouldStopObserving: Bool = false
    private var checkingAvailibility: Bool = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setName(url)
        setAvailiable(_avalibility)
        checkAvailibilityButton.setTitle(checkingAvailibility ? "Checking ..." : "Check Availibility", for: .normal)
    }
    
    @IBAction func didObserveClicked(_ sender: Any) {
        checkingAvailibility.toggle()
        let title = checkingAvailibility ? "Checking ..." : "Check Availibility"
        checkAvailibilityButton.setTitle(title, for: .normal)
        if checkingAvailibility == true {
            observe()
        }
    }
    
    private func setAvailiable(_ on: Bool) {
        avalibilityLabel.text = on ? "Available" : "Not Available"
        avalibilityLabel.textColor = on ? .green : .red
    }
    
    private func setName(_ url: URL) {
        siteName.text = url.absoluteString
    }
    
    var requests: [URLSessionDataTask] = []
    
    private func resetRequests() {
        for request in requests {
            request.cancel()
        }
        
        requests = []
    }
    
    func observe() {
        resetRequests()
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
        
        let group = DispatchGroup()
        
        var countOfFailed: Int = 0
        let totalRequests: Int = 1000
        
        for i in 0..<totalRequests {
            group.enter()
            let dataTask = URLSession.session.dataTask(with: request) { [weak self] data, response, error in
                self?.lock.lock()
                if error != nil {
                    countOfFailed += 1
                } else if let response = response as? HTTPURLResponse, 304..<599 ~= response.statusCode {
                    countOfFailed += 1
                }
                self?.lock.unlock()
                os_log("Request number \(i) completed")
                group.leave()
            }
            dataTask.resume()
            requests.append(dataTask)
        }
        
        group.notify(queue: .main) { [weak self] in
            if self?.shouldStopObserving == true {
                return
            }
            
            if countOfFailed == totalRequests {
                self?.avalibility = false
            }
            
            os_log("Total request \(totalRequests) failed \(countOfFailed)")

            self?.observe()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.navigationController?.topViewController != self {
            shouldStopObserving = true
            resetRequests()
        }
    }
}
