//
//  OnboardingViewController.swift
//  RussianSiteChecker
//
//  Created by Dmytro Rebenko on 27.02.2022.
//

import Foundation
import UIKit

class OnboardingViewController: UIViewController {
    private var pageController: UIPageViewController?
    private lazy var controllers = ["OnboardingFirst", "OnboardingSecond"]
        .map { self.storyboard!.instantiateViewController(withIdentifier: $0) }
    @IBOutlet weak var continueButton: UIButton!
    private var currentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
        self.pageController = pageController
        addChild(pageController)
        let pageView = pageController.view!
        pageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageView)
        
        NSLayoutConstraint.activate([
            pageView.topAnchor.constraint(equalTo: view.topAnchor),
            pageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageView.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20)
        ])
        pageController.dataSource = self
        pageController.delegate = self
        pageController.setViewControllers([controllers[0]], direction: .forward, animated: false, completion: nil)
        
        
        var appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor(red: 0.88, green: 0.88, blue: 0.895, alpha: 1)
        
        appearance.currentPageIndicatorTintColor = UIColor(red: 0.027, green: 0.231, blue: 0.624, alpha: 1)
        
        pageController.didMove(toParent: self)
    }
    
    @IBAction func `continue`(_ sender: Any) {
        
        guard let pageController = pageController else {
            return
        }

        guard let currentViewController = pageController.viewControllers?.first else { return }
        
        guard let nextViewController = pageViewController(pageController, viewControllerAfter: currentViewController) else {
            showMainScreen()
            return
        }
        
        if controllers.count < currentIndex + 1 {
            currentIndex += 1
        }
        
        pageController.setViewControllers([nextViewController], direction: .forward, animated: false, completion: nil)
    }
    
    @IBAction func skip(_ sender: Any) {
        showMainScreen()
    }
    
    private func showMainScreen() {
        Storage.shared.onboardingPassed()
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SitesListViewController")
        view.window?.rootViewController = vc
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return controllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if controllers.count < currentIndex - 1 {
            currentIndex -= 1
        }
        return controllers.firstIndex(of: viewController)
            .flatMap { controllers[safe: $0 - 1] }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if controllers.count < currentIndex + 1 {
            currentIndex += 1
        }

        return controllers.firstIndex(of: viewController)
            .flatMap { controllers[safe: $0 + 1] }
    }
}

extension Array {
    public subscript(safe index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }

        return self[index]
    }
}
