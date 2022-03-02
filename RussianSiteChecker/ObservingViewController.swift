//
//  ObservingViewController.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import UIKit
import OSLog

class ObservedStatusOperation: ChainedAsyncResultOperation<Void, Int, ObservedStatusOperation.RequestError> {
    public enum RequestError: Swift.Error {
        case error, cancelled
    }
    
    private var dataTask: URLSessionTask?
    private let request: URLRequest
    public init(request: URLRequest) {
        self.request = request
        super.init()
    }
    
    override final public func main() {
//        guard input != nil else { return finish(with: .failure(RequestError.error)) }
        
        dataTask = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (_, response, error) in
            print(error)
            print(response?.url)
            if error != nil {
                self?.finish(with: .failure(RequestError.error))
                return
            }
            
            guard let this = self else {
                self?.finish(with: .failure(RequestError.error))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                this.finish(with: .failure(RequestError.error))
                return
            }
            
            if 304..<599 ~= response.statusCode && response.statusCode != 404 {
                this.finish(with: .failure(RequestError.error))
            } else {
                this.finish(with: .success(response.statusCode))
            }
        })
        dataTask?.resume()
    }
    
    override final public func cancel() {
        dataTask?.cancel()
        cancel(with: RequestError.cancelled)
    }
}

class ObservingViewController: UIViewController {
    @IBOutlet weak var siteName: UILabel!
    @IBOutlet weak var availibilityView: UIView!
    @IBOutlet weak var avalibilityLabel: UILabel!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    @IBOutlet weak var siteURLLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var model: (String, URL)! {
        didSet {
            guard isViewLoaded else { return }
            siteURLLabel.text = model.1.absoluteString
            siteName.text = model.0
        }
    }
    
    private var lock = NSLock()
    var avalibility: Bool = false
    
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
        siteURLLabel.text = model.1.absoluteString
        siteName.text = model.0
        setAvailiable(_avalibility)
        let layer0 = checkAvailibilityButton.layer
        layer0.shadowColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.33).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 35.89
        layer0.shadowOffset = CGSize(width: 0.6, height: 8.38)
        availibilityView.layer.cornerRadius = 8
        setReloadingState(checkingAvailibility)
        _avalibility = avalibility
        let backButton = UIBarButtonItem()
        backButton.title = NSLocalizedString("back.button", comment: "")
        lastUpdateLabel.text = NSLocalizedString("not.updated.text", comment: "")
        avalibilityLabel.text = NSLocalizedString("sending.request.text", comment: "")
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func copyTapped(_ sender: Any) {
        UIPasteboard.general.string = model.1.absoluteString
    }
    
    var animation: UIViewPropertyAnimator?
    @IBAction func didObserveClicked(_ sender: Any) {
        checkingAvailibility.toggle()
        setReloadingState(checkingAvailibility)
        
        if checkingAvailibility == true {
            updateLastUpdate()
            observe()
        } else {
            lastUpdateLabel.text = NSLocalizedString("less.than.second.ago.text", comment: "")
            stopTimer()
            stopCountdown()
        }
    }
    
    func setReloadingState(_ on: Bool) {
        animation?.stopAnimation(false)
        let image: UIImage?
        
        if on {
            image = .init(named: "loading")
            loadingIndicator.startAnimating()

        } else {
            image = .init(named: "load")
            loadingIndicator.stopAnimating()
        }
        
        animation = .init(duration: 0.25, curve: .easeInOut, animations: { [weak self] in
            self?.checkAvailibilityButton.setImage(image, for: .normal)
        })
        animation?.startAnimation()
    }
    
    private func setAvailiable(_ on: Bool) {
        availibilityView.backgroundColor = on ? UIColor.green : UIColor(red: 0.8, green: 0.173, blue: 0.149, alpha: 1)
        avalibilityLabel.text = on
        ? NSLocalizedString("available.text", comment: "")
        : NSLocalizedString("not.available.text", comment: "")
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
        var request: URLRequest = URLRequest(url: model.1, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
        
        let group = DispatchGroup()
        
        var countOfFailed: Int = 0
        let totalRequests: Int = 1000
        
        for i in 0..<totalRequests {
            group.enter()
            if i % 10 == 0 {
                let queryComponents = URLQueryItem(name: UUID().uuidString, value: UUID().uuidString)
                var comonents = URLComponents(string: model.1.absoluteString)
                comonents?.queryItems = [queryComponents]
                request =  URLRequest(url: comonents!.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
            }
            
            let dataTask = URLSession.session.dataTask(with: request) { [weak self] data, response, error in
                self?.lock.lock()
                if error != nil {
                    countOfFailed += 1
                } else if let response = response as? HTTPURLResponse, 304..<599 ~= response.statusCode {
                    countOfFailed += 1
                }
                self?.lock.unlock()
                print("Request number \(i) completed")
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
            
            print("Total request \(totalRequests) failed \(countOfFailed)")

            self?.observe()
        }
    }
    
    var timer: Timer?
    var lastUpdateDate = Date()
    
    func updateLastUpdate()  {
        stopTimer()
        let timeInterval = arc4random() % 15
        timer = .scheduledTimer(withTimeInterval: TimeInterval(timeInterval), repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.startCountdown()
            self.lastUpdateDate = Date()
            self.updateLastUpdate()
        })
    }
    
    var countdownTimer: Timer?

    func startCountdown() {
        stopCountdown()
        countdownTimer = .scheduledTimer(withTimeInterval: TimeInterval(0.5), repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            let calendar = Calendar.current
            let components = calendar.dateComponents([.minute, .second], from: self.lastUpdateDate, to: Date())
            let second = components.second ?? 0

            let resultString: String

            if second > 1 {
                resultString = String(format: NSLocalizedString("update.n.seconds.ago.text", comment: ""), "\(second)")
            } else {
                resultString = NSLocalizedString("less.than.second.ago.text", comment: "")
            }

            self.lastUpdateLabel.text = resultString
            self.setAvailiable(self.avalibility)
            self.updateLastUpdate()
        })
    }
    
    func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.navigationController?.topViewController != self {
            shouldStopObserving = true
            resetRequests()
        }
        stopTimer()
        stopCountdown()
    }
}
