//
//  ViewController.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 26.02.2022.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var models = SitesList.sites.map({ AvalibilityViewModel.init(name: $0.absoluteString, url: $0, avaliable: true)}).sorted(by: { $0.name < $1.name })
    
    enum Section {
        case main
    }
    
    private lazy var dataSource = makeDataSource()
    private var lock = NSLock()
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, AvalibilityViewModel>
    typealias DataSource = UITableViewDiffableDataSource<Section, AvalibilityViewModel>
    
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = dataSource
        checkAvalibility()
    }
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { (tableView, indexPath, model) ->
                UITableViewCell? in
                let cell = tableView.dequeueReusableCell(withIdentifier: "avalibilityCell", for: indexPath) as! AvalibilityTableViewCell
                cell.setupWith(model: model)
                return cell
            })
        return dataSource
    }
    
    func applySnapshot(animatingDifferences: Bool = true) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(models.sorted(by: { $0.name < $1.name }))
        dataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
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
        for model in models {
            let request = URLRequest(url: model.url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            let dataTask = URLSession.session.dataTask(with: request) { [weak self] data, response, error in
                guard let this = self else { return }
                this.lock.lock()
                guard let index = this.models.firstIndex(of: model) else {
                    return
                }
                this.models.remove(at: index)
                
                if error != nil {
                    this.models.append(.init(name: model.name, url: model.url, avaliable: false))
                } else if let response = response as? HTTPURLResponse, 400..<599 ~= response.statusCode {
                    print(response.statusCode)
                    this.models.append(.init(name: model.name, url: model.url, avaliable: false))
                } else {
                    this.models.append(.init(name: model.name, url: model.url, avaliable: true))
                }
                this.applySnapshot()
                this.lock.unlock()
            }
            dataTask.resume()
            
            requests.append(dataTask)
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        
        let vc = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "observeVC") as! ObservingViewController
        vc.url = model.url
        vc.avalibility = model.avaliable
        navigationController?.pushViewController(vc, animated: false)
    }
    
}
