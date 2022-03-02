//
//  ViewController.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import UIKit

class ViewController: UIViewController {
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AvalibilityViewModel>
    typealias DataSource = UITableViewDiffableDataSource<Section, AvalibilityViewModel>

    @IBOutlet weak var titleTextLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var availiableSitesLabel: UILabel!
    var models = SitesList.sitesWithNames.map({
        AvalibilityViewModel(name: $0.0, url: $0.1, avaliable: false)})
        .sorted(by: { $0.name < $1.name })
    var local: [AvalibilityViewModel] = SitesList.localSites
        .map({ URL(string: $0)! })
        .map({ AvalibilityViewModel.init(name: $0.absoluteString, url: $0, avaliable: false)})
        .sorted(by: { $0.name < $1.name })
    
    enum Section {
        case local
        case main
    }
    
    private lazy var dataSource = makeDataSource()
    private var lock = NSLock()
    var timer: Timer?
    
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
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { (tableView, indexPath, model) ->
                UITableViewCell? in
                let cell = tableView.dequeueReusableCell(withIdentifier: "avalibilityCell", for: indexPath) as! AvalibilityTableViewCell
                cell.selectionStyle = .none
                cell.setupWith(model: model)
                return cell
            })
        return dataSource
    }
    
    func downloadLatestSiteToObserve() {
//        let url = URL(string: "https://raw.githubusercontent.com/hem017/cytro/master/targets_all.txt")
//        URLSession.shared.dataTask(with: url!) { [weak self] data, response, error in
//            let local = local
//            print(String(data: data!, encoding: .utf8))
//        }.resume()
    }
    
    func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.local, .main])
        snapshot.appendItems(local, toSection: .local)
        snapshot.appendItems(self.models.sorted(by: { $0.name < $1.name }), toSection: .main)
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
        
        queueTimer?.invalidate()
        queueTimer = nil
        operations.removeAll()
        operationQueue.cancelAllOperations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer?.invalidate()
        self.timer = .scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] _ in
            self?.checkAvalibility()
        })
    }
    
    var requests: [URLSessionDataTask] = []

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

        SitesList.localSites.insert(str, at: 0)
        local.insert(AvalibilityViewModel(name: str, url: URL(string: str)!, avaliable: true), at: 0)
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
                guard let modelIndex = this.models.firstIndex(of: model) else {
                    return
                }
                
                let model = this.models[modelIndex]
                
                if error != nil {
                    model.avaliable = false
                } else if let response = response as? HTTPURLResponse, 400..<599 ~= response.statusCode {
                    model.avaliable = false
                } else {
                    model.avaliable = true
                }
                
                var newSnapshot = this.dataSource.snapshot()
                newSnapshot.reloadItems([model])
                this.dataSource.apply(newSnapshot, animatingDifferences: false)
                this.reloadCounter()
                this.lock.unlock()
            }
            dataTask.resume()
            
            requests.append(dataTask)
        }

        for model in local {
            let request = URLRequest(url: model.url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            let dataTask = URLSession.session.dataTask(with: request) { [weak self] data, response, error in
                guard let this = self else { return }
                this.lock.lock()
                guard let modelIndex = this.models.firstIndex(of: model) else {
                    return
                }

                let model = this.models[modelIndex]

                if error != nil {
                    model.avaliable = false
                } else if let response = response as? HTTPURLResponse, 400..<599 ~= response.statusCode {
                    model.avaliable = false
                } else {
                    model.avaliable = true
                }

                var newSnapshot = this.dataSource.snapshot()
                newSnapshot.reloadItems([model])
                this.dataSource.apply(newSnapshot, animatingDifferences: false)
                this.reloadCounter()
                this.lock.unlock()
            }
            dataTask.resume()

            requests.append(dataTask)
        }
    }
    
    lazy var operationQueue = { () -> OperationQueue in
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = self.maxThreads
        return operationQueue
    }()
    let mapOperationsCount = 100
    let maxThreads = 10
    
    var queueTimer: Timer? {
        didSet {
             print("Did set timer")
        }
    }
    var operations: [Operation] = []
    let observingLock = NSRecursiveLock()
    let syncQueue = DispatchQueue(label: "sync.queue")
    
    func startObserving() {
        queueTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            guard let this = self else { return }
            guard this.operations.count < this.maxThreads * this.mapOperationsCount else { return }
            guard let model = this.models.first(where: \.avaliable) ?? this.local.first(where: \.avaliable) else { return }
            print("Start actively checking \(model.name)")
            for _ in 0..<this.maxThreads {
                var previousRequest: Operation?
                let queryComponents = URLQueryItem(name: UUID().uuidString, value: UUID().uuidString)
                var comonents = URLComponents(string: model.url.absoluteString)
                comonents?.queryItems = [queryComponents]
                let request = URLRequest(url: comonents!.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
                for _ in 0..<this.mapOperationsCount {                    
                    let operation = ObservedStatusOperation(request: request)
                    operation.onResult = { result in
                        this.syncQueue.async { [weak self] in
                            guard let this = self else { return }
                            
                            switch result {
                            case let .failure(error):
                                if case ObservedStatusOperation.RequestError.cancelled = error {
                                    this.updateModelAvailability(model: model, available: true)
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
                    }
                    this.operations.append(operation)
                    
                    if let previousRequest = previousRequest {
                        operation.addDependency(previousRequest)
                    }
                    let blockOperation = BlockOperation { [weak this] in
                        _ = this?.syncQueue.sync {
                            this?.operations.firstIndex(of: operation).flatMap { this?.operations.remove(at: $0) }
                        }
                    }
                    blockOperation.addDependency(operation)

                    this.operationQueue.addOperation(operation)
                    this.operationQueue.addOperation(blockOperation)

                    previousRequest = operation
                }
            }
        })
    }
    
    private func updateModelAvailability(model: AvalibilityViewModel, available: Bool) {
        if let index = models.firstIndex(of: model) {
            models[index].avaliable = available
        } else if let index = local.firstIndex(of: model) {
            models[index].avaliable = available
        }
        
        var newSnapshot = self.dataSource.snapshot()
        newSnapshot.reloadItems([model])
        self.dataSource.apply(newSnapshot, animatingDifferences: false)
        self.reloadCounter()
    }
    
    private func reloadCounter() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let countOfAvailiable = (self.models + self.local)
                .filter({ $0.avaliable == true })
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
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "observeVC") as! ObservingViewController
        vc.model = (model.name, model.url)
        vc.avalibility = model.avaliable
        navigationController?.pushViewController(vc, animated: false)
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}
