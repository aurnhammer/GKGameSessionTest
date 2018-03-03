//
//  GameSessionURLProvider.swift
//  District1
//
//  Created by Bill A on 3/12/17.
//  Copyright © 2017 beaconcrawl.com. All rights reserved.
//

import UIKit
import GameKit


class GameSessionURLProvider: UIActivityItemProvider {
    
    private var url: URL?
    private var gameSession: GKGameSession!
    private var transitioningDelegate: BC_NotificationTransitioningDelegate?
	private var loadingViewController: UIViewController!
	
    public init(placeholderItem: AnyObject, gameSession: GKGameSession) {
        super.init(placeholderItem: placeholderItem)
        self.gameSession = gameSession
		self.loadingViewController = createLoadingViewController()
    }
    
    override public var item: Any {
        
		
		let group = DispatchGroup()
		group.enter()

        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            self.gameSession.getShareURL(completionHandler: { [weak self] (url, error) in
                self?.url = url
				if self?.activityType == UIActivityType.airDrop {
					self?.loadingViewController.dismiss(animated: true, completion: {
						group.leave()
					})
				}
				else {
					group.leave()
				}
			})
		}
		DispatchQueue.main.async {
			var rootViewController: UIViewController?
			if let
				appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
				let window = appDelegate.window {
				rootViewController = window!.rootViewController
			}
            if nil != rootViewController?.presentedViewController {
				rootViewController!.presentedViewController!.present(self.loadingViewController, animated: true, completion:nil)
            }
            else {
				rootViewController?.present(self.loadingViewController, animated: true, completion:nil)
            }
        }
        _ = group.wait(timeout: .distantFuture)

        return url as Any
    }
    
    func createLoadingViewController() -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "LoadingViewController")
        self.transitioningDelegate = BC_NotificationTransitioningDelegate()
        transitioningDelegate?.isFlipView = true
        controller.transitioningDelegate = transitioningDelegate
        controller.modalPresentationStyle = UIModalPresentationStyle.custom;
        return controller
    }
}

