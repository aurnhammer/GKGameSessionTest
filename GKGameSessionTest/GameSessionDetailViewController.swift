//
//  GameSessionDetailViewController.swift
//  GKGameSessionTest
//
//  Created by Bill A on 3/4/18.
//  Copyright © 2018 aurnhammer. All rights reserved.
//

import UIKit
import GameKit

class GameSessionDetailViewController: UITableViewController {

	@IBOutlet weak var owner: UILabel!
	@IBOutlet weak var currentParticipant: UILabel!
	@IBOutlet weak var participants: UILabel!
	@IBOutlet weak var statusView: UITextView!
	
	var gameSessionIdentifier: String!
	var gameSessionManager = GameSessionsManager.shared
	
	override func viewDidLoad() {
        super.viewDidLoad()
		setup()
    }
	
	override func willMove(toParentViewController parent: UIViewController?) {
		super.willMove(toParentViewController:parent)
		if parent == nil {
			// The back button was pressed or interactive gesture used
			stopListening()
		}
		else {
			startListening()
		}
	}
	
	deinit {
		Log.message("DeInit")
	}
	
	func setup() {
		setupNavigationBar()
		setupView()
	}
	
	func setupNavigationBar() {
		if #available(iOS 11.0, *) {
			self.navigationItem.largeTitleDisplayMode = .never
		}
		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { (session, error) in
			Log.error(with: #line, functionName: #function, error: error)
			DispatchQueue.main.async {
				self.navigationItem.title = session?.title
			}
		})
	}
		
	func setupView() {
		statusView.textContainerInset = UIEdgeInsetsMake(8.0, 8.0, 8.0, 8.0);

		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { (gameSession, error) in
			if let gameSession = gameSession, let displayName = gameSession.owner.displayName {
				self.owner.text = displayName
				GKCloudPlayer.getCurrentSignedInPlayer(forContainer: GameSessionsManager.Container.ID) { (player, error) in
					DispatchQueue.main.async {
						if let displayName = player?.displayName {
							self.currentParticipant.text = displayName
						}
						// Remove the current participant from the sessions list of participants
						let otherParticipants = gameSession.players.filter({$0.playerID != player?.playerID})
						self.participants.text = "\(otherParticipants.count)"
						self.tableView.reloadData()
					}
				}
			}
		})
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
		switch section {
		case 0:
			return 3
		default:
			return 0
		}
    }
		
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		if let destinationViewController = segue.destination as? ParticipantsTableViewController {
			destinationViewController.gameSessionIdentifier = gameSessionIdentifier
		}
	}

	@IBAction func shareSession(_ sender: UIButton) {
		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { [weak self] (gameSession, error) in
			if let gameSession = gameSession {
				let urlProvider = GameSessionURLProvider(placeholderItem: URL(string:"http://disctrictapp.com") as AnyObject, gameSession:gameSession)
				self?.gameSessionManager.invitePlayer(withActivityItems: [urlProvider]) { (activityType, success, items, error) in
					
				}
			}
		})
	}
	
	@IBAction func removeSession(_ sender: UIButton) {
		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { [weak self] (gameSession, error) in
			if let gameSession = gameSession {
				self?.gameSessionManager.cancelGameSession(gameSession) { [weak self] (error) in
					Log.error(with: #line, functionName: #function, error: error)
					self?.performSegue(withIdentifier: "toSessions", sender: self)
				}
			}
		})
	}
	
	@IBAction func saveData(_ sender: UIButton) {
		let alert = UIAlertController(title: "Save Data", message: "Enter text", preferredStyle: .alert)
		alert.addTextField()
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] (_) in
			if let text = alert?.textFields?[0].text {
				guard let data = text.data(using: String.Encoding.utf8) else {
					Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
					return
				}
				self?.save(data: data, completionHandler: { () in
					if let gameSessionIdentifier = self?.gameSessionIdentifier {
						GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { (session, error) in
							if let playerNames = session?.players.compactMap({$0.displayName}) {
								self?.statusView.text = "Save Data \(text) for " + "session \(playerNames) players)"
							}
						})
					}
				})
			}
		}))
		self.present(alert, animated: true, completion: nil)
	}

	func save(data: Data, completionHandler:(() -> Swift.Void)?) {
		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { (session, error) in
			Log.error(with: #line, functionName: #function, error: error)
			session?.save(data, completionHandler: { (confictingData, error) in
				Log.error(with: #line, functionName: #function, error: error)
				// Handle error
				if nil == error {
					completionHandler?()
				}
				else {
					self.save(data: data, completionHandler: { () in
						completionHandler?()
					})
				}
			})
		})
	}
	
	@IBAction func loadData(_ sender: UIButton) {
		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { (session, error) in
				session?.loadData { (data, error) in
				if let data = data {
					guard let string = String(data: data, encoding: .utf8) else {
						Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
						return
					}
					let playerNames =  session?.players.compactMap(){$0.displayName}
					self.statusView.text = "Loaded Data \(string) for " + "session \(playerNames!) players)"
				}
			}
		})
	}
	
	
	@IBAction func sendMessage(_ sender: UIButton) {
		let alert = UIAlertController(title: "Send Message", message: "Enter text", preferredStyle: .alert)
		alert.addTextField()
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] (_) in
			if let gameSessionIdentifier = self?.gameSessionIdentifier {
				GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { [weak self] (session, error) in
					session?.loadData { (data, error) in
						if let text = alert?.textFields?[0].text, let players = session?.players {
							session?.sendMessage(withLocalizedFormatKey: "%@", arguments: [text], data: nil, to: players, badgePlayers: false) { (error) in
								Log.error(with: #line, functionName: #function, error: error)
								if nil == error, let playerNames = session?.players.compactMap({$0.displayName}) {
									self?.statusView.text = "Send Message \(text) for " + "session \(playerNames) players)"
								}
							}
						}
					}
				})
			}
		}))
		self.present(alert, animated: true, completion: nil)
	}
	
	@IBAction func sendData(_ sender: UIButton) {
		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { [weak self] (session, error) in
			if let session = session {
				let players = session.players(with: GKConnectionState.connected)
				if !players.isEmpty {
					let alert = UIAlertController(title: "Send Data", message: "Enter text", preferredStyle: .alert)
					alert.addTextField()
					alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] (_) in
						if let text = alert?.textFields?[0].text {
							session.sendData(text, completionHandler: { (error) in
								Log.error(with: #line, functionName: #function, error: error)
								if nil == error {
									let playerNames = session.players.compactMap({$0.displayName}) 
									self?.statusView.text = "Send Data \(text) for " + "session \(playerNames) players)"
								}
								else {
									self?.statusView.text = error?.localizedDescription
								}
							})
						}
					}))
					self?.present(alert, animated: true, completion: nil)
				}
				else {
					self?.statusView.text = "There are no connected Players"
				}
			}
		})
	}

	@IBAction func connectToSession(_ sender: UIButton) {
		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { [weak self] (session, error) in
			if nil != error {
				self?.statusView.text = error.debugDescription
			}
			else {
				session?.setConnectionState(GKConnectionState.connected, completionHandler: { (error) in
					Log.error(with: #line, functionName: #function, error: error)
					if error != nil {
						self?.statusView.text = error?.localizedDescription
					}
					else {
						self?.statusView.text = "Connection Succesful"
					}
				})
			}
		})
	}
	
	@IBAction func showConnected(_ sender: UIButton) {
		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: { [weak self] (session, error) in
				if let players = session?.players(with: GKConnectionState.connected), !players.isEmpty {
				let playerNames = players.compactMap({$0.displayName})
				self?.statusView.text = "Connected \(playerNames)\n"
			}
			else {
				self?.statusView.text = "No one is connected\n"
			}
		})
	}

}

public protocol GameSessionEventListener: GKGameSessionEventListener {
	var gameSessionManager: GameSessionsManager { get }
}

extension GameSessionDetailViewController: GameSessionEventListener {
	
	func startListening() {
		GKGameSession.add(listener: self)
	}
	
	func stopListening() {
		GKGameSession.remove(listener: self)
	}
	
	public func session(_ session: GKGameSession, didAdd player: GKCloudPlayer) {
		// Reload the view.
		setupView()
	}
	
	public func session(_ session: GKGameSession, didRemove player: GKCloudPlayer) {
		// Reload the view.
		setupView()
	}
	
	public func session(_ session: GKGameSession, player: GKCloudPlayer, didSave data: Data) {
		// cloudPlayer has correct name here
		if let displayName = player.displayName, let string = String(data: data, encoding:.utf8) {
			statusView.text = "Did save \(string) from player \(displayName)\n"
		}
	}
	
	public func session(_ session: GKGameSession, didReceiveMessage message: String, with data: Data, from player: GKCloudPlayer) {
		// Warning Unexpected Behavior
		// cloudPlayer has correct type of playerID but no Display Name.
		// Workaround
		/// Get the player's name from the session.
		if let player = session.players.filter({$0.playerID == player.playerID}).first,
			let displayName = player.displayName {
			self.statusView.text = "Did recieve \(message) from player \(displayName)\n"
		}
	}
	
	public func session(_ session: GKGameSession, player: GKCloudPlayer, didChange state: GKConnectionState) {
		Log.message("Player \(player )Changed State to \(state.rawValue == 0 ? "left" : "joined")")
		if let displayName = player.displayName {
			self.statusView.text = "\(displayName) has \(state.rawValue == 0 ? "left" : "joined") the realtime match \(session.title)"
		}
		else {
			self.statusView.text = "Connection Unkown"
		}
	}
	
	public func session(_ session: GKGameSession, didReceive data: Data, from cloudPlayer: GKCloudPlayer) {
		if let  string = String(data: data, encoding: .utf8) {
			if let displayName = cloudPlayer.displayName {
				self.statusView.text = "Did recieve \(string) from player \(displayName)\n"
			} else if let player = session.players.filter({$0.playerID == cloudPlayer.playerID}).first,
				let displayName = player.displayName {
				self.statusView.text = "Did recieve \(string) from player \(displayName)\n"
			}
			else {
				self.statusView.text = "Did recieve \(string)"
			}
		}
	}
}
