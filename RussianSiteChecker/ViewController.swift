//
//  ViewController.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import UIKit

struct ControlResponse: Codable {
    let models: [AvalibilityViewModel]
    let targetURLs: [URL]
}

class ViewController: UIViewController {
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AvalibilityViewModel>
    private typealias DataSource = UITableViewDiffableDataSource<Section, AvalibilityViewModel>
    
    @IBOutlet weak var titleTextLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var availiableSitesLabel: UILabel!
    
    private lazy var dataSource = makeDataSource()
    private var lock = NSLock()
    private var timer: RepeatingTimer?
    private var models: [AvalibilityViewModel] =
    (SitesList.sitesWithNames.map({
        AvalibilityViewModel(name: $0.0, url: $0.1, available: false) } ) +
     SitesList.localSites)
        .sorted(by: { $0.name < $1.name })
    private var targetURLs: [URL] = SitesList.target
    
    
    private lazy var operationQueue = { () -> OperationQueue in
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = self.maxThreads
        return operationQueue
    }()
    private let mapOperationsCount = 100
    private let maxThreads = 10
    private var queueTimer: RepeatingTimer?
    private var donwloadLatestUpdated: RepeatingTimer?
    private let operations = SynchronizedArray<Operation>()
    private var selectedIndexPath: IndexPath?

    
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = dataSource
        applySnapshot()
        checkAvalibility()
        downloadLatestSiteToObserve()
        titleTextLabel.text = NSLocalizedString("website.list.text", comment: "")
    }
    
    private func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { [weak self] (tableView, indexPath, model) ->
                UITableViewCell? in
                let cell = tableView.dequeueReusableCell(withIdentifier: "avalibilityCell", for: indexPath) as! AvalibilityTableViewCell
                cell.selectionStyle = .none
                cell.accessoryType = indexPath == self?.selectedIndexPath ? .checkmark : .none
                cell.setupWith(model: model)
                return cell
            })
        return dataSource
    }
    
    
    func downloadLatestSiteToObserve() {
        donwloadLatestUpdated?.suspend()
        let timer = RepeatingTimer(timeInterval: 60)
        timer.eventHandler = { [weak self] in
            self?.downloadLatestSites()
        }
        timer.resume()
        self.donwloadLatestUpdated = timer
    }
    
    private func downloadLatestSites() {
        let url = URL(string: "https://raw.githubusercontent.com/secwow/sitechecker/main/SitesToCheck")
        URLSession.shared.dataTask(with: url!) { [weak self] data, response, error in
            guard let data = data,
                  let response = try? JSONDecoder().decode(ControlResponse.self, from: data),
                  let local = self?.models else {
                      return
                  }
            var needToAdd = [AvalibilityViewModel]()
            self?.targetURLs = response.targetURLs

            for model in response.models {
                guard local.contains(where: { $0.url == model.url }) == false else {
                    continue
                }
                
                needToAdd.append(model)
                SitesList.localSites.append(model)
            }
            
            guard needToAdd.isEmpty == false else {
                return
            }
            
            let result = (self?.models ?? []) + needToAdd.sorted(by: { response.targetURLs.contains($0.url) && !response.targetURLs.contains($1.url) })
            var snapshot = Snapshot()
            snapshot.appendSections([.main])
            snapshot.appendItems(result, toSection: .main)
            self?.dataSource.apply(snapshot, animatingDifferences: false)
            self?.reloadCounter()
        }.resume()
    }
    
    func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(self.models, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    
    @IBAction func addButtonTouched(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("add.website.title", comment: ""),
                                      message: NSLocalizedString("add.website.message", comment: ""),
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "rkn.gov.ru"
        }
        
        let addAction = UIAlertAction(title: NSLocalizedString("add.website.add.button", comment: ""),
                                      style: .default) { [weak self]_ in
            guard let textField = alert.textFields?.first else { return }
            self?.addWebsite(textField.text ?? "")
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("add.website.add.cancel", comment: ""),
                                         style: .cancel, handler: nil)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        startObserving()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        queueTimer?.suspend()
        queueTimer = nil
        operations.removeAll()
        operationQueue.cancelAllOperations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer?.suspend()
        let timer = RepeatingTimer(timeInterval: 5)
        timer.eventHandler = { [weak self] in
            self?.checkAvalibility()
        }
        timer.resume()
        self.timer = timer
    }
    
    private var requests: [URLSessionDataTask] = []
    
    func addWebsite(_ str: String) {
        guard str.hasPrefix("https://") || str.hasPrefix("http://")
                && (str.hasSuffix(".ru") || str.hasSuffix(".ru/"))
        else {
            let alert = UIAlertController(title: NSLocalizedString("add.website.failure.title", comment: ""),
                                          message: NSLocalizedString("add.website.failure.message", comment: ""),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        
        let model = AvalibilityViewModel(name: str, url: URL(string: str)!, available: true)
        models.append(model)
        SitesList.localSites.append(model)
        applySnapshot()
        checkAvalibility()
    }
    
    func checkAvalibility() {
        resetRequests()
        
        for model in self.models {
            let request = URLRequest(url: model.url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            let dataTask = URLSession.session.dataTask(with: request) { [weak self] data, response, error in
                guard let this = self else { return }
                this.lock.lock()
                defer {
                    this.lock.unlock()
                }
                guard let modelIndex = this.models.firstIndex(of: model) else {
                    return
                }
                
                let model = this.models[modelIndex]
                let isAvailable: Bool
                if error != nil {
                    isAvailable = false
                } else if let response = response as? HTTPURLResponse, 400..<599 ~= response.statusCode {
                    isAvailable = false
                } else {
                    isAvailable = true
                }
                guard model.available != isAvailable else { return }
                model.available = isAvailable
                
                var newSnapshot = this.dataSource.snapshot()
                newSnapshot.reloadItems([model])
                
                this.dataSource.apply(newSnapshot, animatingDifferences: false)
                this.reloadCounter()
            }
            dataTask.resume()
            
            requests.append(dataTask)
        }
    }
    
    func startObserving() {
        reloadCounter()
        let timer = RepeatingTimer(timeInterval: 0.1)
        timer.eventHandler = { [weak self] in
            guard let this = self else { return }
            guard this.operations.count < this.maxThreads * this.mapOperationsCount else { return }
            guard let model = (
                this.models.filter({ this.targetURLs.contains($0.url) }).first(where: \.available) ??
                this.models.first(where: \.available))
            else {
                return
            }
            
            if let indexPath = this.dataSource.indexPath(for: model) {
                this.selectedIndexPath = indexPath
            }
            
            print("Start actively checking \(model.name)")
            for _ in 0..<this.maxThreads {
                var previousRequest: Operation?
                
                let request = this.createRequest(model: model)
                
                for _ in 0..<this.mapOperationsCount {
                    let operation = ObservedStatusOperation(request: request)
                    operation.onResult = { result in
                        guard let this = self else { return }
                        
                        switch result {
                        case let .failure(error):
                            if case ObservedStatusOperation.RequestError.cancelled = error {
                                this.updateModelAvailability(model: model, available: false)
                                return
                            }
                        default:
                            break
                        }
                        
                        
                        if (try? result.get()) == nil {
                            this.updateModelAvailability(model: model, available: false)
                            this.operations.removeAll()
                            this.operationQueue.cancelAllOperations()
                        } else {
                            this.updateModelAvailability(model: model, available: true)
                        }
                    }
                    this.operations.append(operation)
                    
                    if let previousRequest = previousRequest {
                        operation.addDependency(previousRequest)
                    }
                    let blockOperation = BlockOperation { [weak this] in
                        this?.operations.firstIndex(where: { $0 == operation})
                            .flatMap { this?.operations.remove(at: $0) }
                    }
                    blockOperation.addDependency(operation)
                    
                    this.operationQueue.addOperation(operation)
                    this.operationQueue.addOperation(blockOperation)
                    
                    previousRequest = operation
                }
            }
        }
        
        queueTimer = timer
        timer.resume()
    }
    
    private func updateModelAvailability(model: AvalibilityViewModel, available: Bool) {
        if let index = models.firstIndex(of: model) {
            models[index].available = available
        }
        
        var newSnapshot = self.dataSource.snapshot()
        newSnapshot.reloadItems([model])
        self.dataSource.apply(newSnapshot, animatingDifferences: false)
        self.reloadCounter()
    }
    
    private func reloadCounter() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let countOfAvailiable = self.models
                .filter({ $0.available == true })
                .count
            self.availiableSitesLabel.text = String(format: NSLocalizedString("active.websites.number.text", comment: ""), "\(countOfAvailiable)", "\(self.models.count)")
        }
    }
    
    private func resetRequests() {
        for request in requests {
            request.cancel()
        }
        
        self.requests = []
    }
    
    private func createRequest(model: AvalibilityViewModel, initialDefinition: Bool = true) -> URLRequest {
        guard model.method == nil else {
            let queryComponents = URLQueryItem(name: UUID().uuidString, value: UUID().uuidString)
            var comonents = URLComponents(string: model.url.absoluteString)
            comonents?.queryItems = [queryComponents]
            let request = URLRequest(url: comonents!.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            return request
        }
        
        var URLString = model.url.absoluteString.replacingOccurrences(of: "%@", with: UUID().uuidString)
        if URLString == model.url.absoluteString {
            let queryComponents = URLQueryItem(name: UUID().uuidString, value: UUID().uuidString)
            var comonents = URLComponents(string: model.url.absoluteString)
            comonents?.queryItems = [queryComponents]
            URLString = (comonents?.url!.absoluteString)!
        }
        
        var request = URLRequest(url: URL(string: URLString)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = model.method ?? "GET"
        
        
        return request
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "observeVC") as! ObservingViewController
        vc.model = (model.name, model.url)
        vc.avalibility = model.available
        navigationController?.pushViewController(vc, animated: false)
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}
