//
//  ParticipantsTableViewController.swift
//  GKGameSessionTest
//
//  Created by Bill A on 3/5/18.
//  Copyright © 2018 aurnhammer. All rights reserved.
//

import UIKit
import GameKit

class ParticipantsTableViewController: UITableViewController {

	var gameSessionIdentifier: String!
	private var participants: [GKCloudPlayer]?
	
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

	func setup() {
		setupParticipants()
	}

	func setupParticipants() {
		GKGameSession.load(withIdentifier: gameSessionIdentifier, completionHandler: {(gameSession, error) in
			if let gameSession = gameSession {
				GKCloudPlayer.getCurrentSignedInPlayer(forContainer: GameSessionsManager.Container.ID) { (player, error) in
					let otherParticipants = gameSession.players.filter({$0.playerID != player?.playerID})
					self.participants = otherParticipants
					self.tableView.reloadData()
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
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let participants = participants {
			return participants.count
		}
		else {
			return 0
		}
	}

	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
		if let displayName = participants?[indexPath.row].displayName {
			cell.textLabel?.text = displayName
		}
		else {
			cell.textLabel?.text = "anonymous"
		}
        return cell
    }
 }

extension ParticipantsTableViewController: GameSessionEventListener {
	
	var gameSessionManager: GameSessionsManager {
		return GameSessionsManager.shared
	}
	
	func startListening() {
		GKGameSession.add(listener: self)
	}
	
	func stopListening() {
		GKGameSession.remove(listener: self)
	}
	
	public func session(_ session: GKGameSession, didAdd cloudPlayer: GKCloudPlayer) {
		setupParticipants()
	}
	
	public func session(_ session: GKGameSession, didRemove player: GKCloudPlayer) {
		setupParticipants()
	}
}
