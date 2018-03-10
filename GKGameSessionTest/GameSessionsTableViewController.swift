//
//  GameSessionsTableViewController.swift
//  GKGameSessionTest
//
//  Created by Bill A on 3/4/18.
//  Copyright © 2018 aurnhammer. All rights reserved.
//

import UIKit
import GameKit

class GameSessionsTableViewController: UITableViewController {

	var gameSessionManager: GameSessionsManager!

    override func viewDidLoad() {
        super.viewDidLoad()
		setup()
    }
	
	deinit {
		stopListening()
	}
	
	func setup(){
		setupAppearance()
		setupGameSessionManager()
	}
	
	func setupAppearance() {
		if #available(iOS 11.0, *) {
			self.navigationController?.navigationBar.prefersLargeTitles = true
		}
	}
	
	fileprivate func reloadGameSessions() {
		gameSessionManager.loadSessions(completionHandler: { [weak self] (error) in
			self?.tableView.reloadData()
		})
	}
	
	func setupGameSessionManager() {
		self.gameSessionManager = GameSessionsManager.shared
		self.startListening()
		self.reloadGameSessions()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
		Log.message("\((#file as NSString).lastPathComponent): " + #function)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let gameSessions = gameSessionManager.gameSessions {
        	return gameSessions.count
		}
		else {
			return 0
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
		if let gameSessions = gameSessionManager.gameSessions {
			cell.textLabel?.text = gameSessions[indexPath.row].title
		}
        return cell
    }
	
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
		if let destinationViewController = segue.destination as? GameSessionDetailViewController, let row = tableView.indexPathForSelectedRow?.row {
			// Pass the gameSessionIdentifier to the new view controller.
			if let gameSessions = gameSessionManager.gameSessions {
				destinationViewController.gameSessionIdentifier = gameSessions[row].identifier
			}
		}
    }
    
	func createLoadingViewController() -> UIViewController {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let controller = storyboard.instantiateViewController(withIdentifier: "LoadingViewController")
		let transitioningDelegate: BC_NotificationTransitioningDelegate = BC_NotificationTransitioningDelegate()
		transitioningDelegate.isFlipView = true
		controller.transitioningDelegate = transitioningDelegate
		controller.modalPresentationStyle = UIModalPresentationStyle.custom;
		return controller
	}

	@IBAction func addSession(_ sender: UIBarButtonItem) {
		let alert = UIAlertController(title: "Name Session", message: "Enter text", preferredStyle: .alert)
		alert.addTextField()
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] (_) in
			if let text = alert?.textFields?[0].text, let loadingViewController = self?.createLoadingViewController() {
				self?.present(loadingViewController, animated: true, completion: nil)
				self?.gameSessionManager.createSession(with: text, andMaxPlayerCount: 16, completionHandler: { (gameSession, error) in
					DispatchQueue.main.async {
						self?.tableView.reloadData()
						loadingViewController.dismiss(animated: true, completion: {
							let urlProvider = GameSessionURLProvider(placeholderItem: URL(string:"http://disctrictapp.com") as AnyObject, gameSession:gameSession)
							self?.gameSessionManager.invitePlayer(withActivityItems: [urlProvider]) { (activityType, success, items, error) in
								
							}
						})
					}
					
				})
			}
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	@IBAction func unwind(_ segue: UIStoryboardSegue){
		reloadGameSessions()
	}
}

extension GameSessionsTableViewController: GKGameSessionEventListener {
	
	func startListening() {
		GKGameSession.add(listener: self)
	}
	
	func stopListening() {
		GKGameSession.remove(listener: self)
	}
	
	public func session(_ session: GKGameSession, didAdd cloudPlayer: GKCloudPlayer) {
		reloadGameSessions()
	}
	
	public func session(_ session: GKGameSession, didRemove player: GKCloudPlayer) {
		reloadGameSessions()
	}
}

