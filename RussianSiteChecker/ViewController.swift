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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var availiableSitesLabel: UILabel!
    var models = SitesList.sites.map({
        AvalibilityViewModel.init(name: $0.absoluteString, url: $0, avaliable: true)})
        .sorted(by: { $0.name < $1.name })
    
    enum Section {
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
        tableView.backgroundColor = UIColor(red: 0.973, green: 0.974, blue: 0.977, alpha: 1)
        view.backgroundColor = UIColor(red: 0.973, green: 0.974, blue: 0.977, alpha: 1)
        applySnapshot()
        checkAvalibility()
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
    
    func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(models.sorted(by: { $0.name < $1.name }))
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetRequests()
        timer?.invalidate()
        timer = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.timer = .scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] _ in
            self?.checkAvalibility()
        })
    }
    
    var requests: [URLSessionDataTask] = []
    
    func checkAvalibility() {
        resetRequests()
        
        for model in models {
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
    
    private func reloadCounter() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let countOfAvailiable = self.models.filter({ $0.avaliable == true }).count
            self.availiableSitesLabel.text = "\(countOfAvailiable) из \(self.models.count) работает"
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
        vc.url = model.url
        vc.avalibility = model.avaliable
        navigationController?.pushViewController(vc, animated: false)
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}
