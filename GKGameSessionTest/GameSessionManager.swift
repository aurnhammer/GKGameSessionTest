//
//  GameSessionManager.swift
//  BeaconCrawl
//
//  Created by Bill A on 3/4/17.
//  Copyright © 2017 beaconcrawl.com. All rights reserved.
//

import GameKit
import CloudKit
import UserNotifications

open class GameSessionsManager: NSObject {
	
	var repeatCount: Int = 0

    public struct Container {
        public static let ID = "iCloud.com.beaconcrawl.District1"
    }
    
    public static let container = CKContainer(identifier: GameSessionsManager.Container.ID)

    open static let shared = GameSessionsManager()
	var accountManager: AccountManager!

    var gameSessions: [GKGameSession]! = []
    
    public override init() {
        super.init()
        Log.message("\((#file as NSString).lastPathComponent): " + #function)
		setup()
    }
	
	func setup() {
		setupAccountManager()
		setupUserNotfications()
	}
	
	func setupAccountManager() {
		accountManager = AccountManager()
		accountManager.isGameCenterAccountAvailable { [weak self] (isAvailable, error) in
			self?.startListening()
		}
	}
	
	func setupUserNotfications() {
		UNUserNotificationCenter.current().requestAuthorization(options:  [.alert, .sound, .badge], completionHandler: { [weak self](sucess, error) in
			self?.setupNotficationManagerDelegate()
		})
	}

    deinit {
		stopListening()
        Log.message("\((#file as NSString).lastPathComponent): " + #function)
    }
	
    func loadSessions() {
		loadSessions(completionHandler: nil)
    }
	
	func loadSessions(completionHandler:((Error?) -> Swift.Void?)?) {
		GKGameSession.loadSessions(inContainer: Container.ID) {[weak self] (gameSessions, error) in
			Log.error(with: #line, functionName: #function, error: error)
			self?.gameSessions = gameSessions
			completionHandler?(error)
		}
	}
    
    func removeAll() {
        if let gameSessions = self.gameSessions {
            for gameSession in gameSessions {
                GKGameSession.remove(withIdentifier: gameSession.identifier, completionHandler: { (error) in
                    Log.error(with: #line, functionName: #function, error: error)
                })
            }
            self.gameSessions = nil
        }
    }

    
	open func createSession(with title: String, andMaxPlayerCount maxPlayersCount: NSInteger, completionHandler:@escaping (_ session: GKGameSession, _ error: Error?) -> Void) {
        GKGameSession.createSession(inContainer: Container.ID, withTitle: title, maxConnectedPlayers: maxPlayersCount) { (gameSession, error) in
            Log.error(with: #line, functionName: #function, error: error)
			if let gameSession = gameSession {
				self.gameSessions.append(gameSession)
            	completionHandler(gameSession, error)
			}
        }
    }

    open func cancelGameSession(_ gameSession: GKGameSession, completionHandler:@escaping (_ error: Error?) -> Void) {
		if let index = gameSessions.index(of: gameSession) {
			gameSessions.remove(at: index)
		}
        let identifier = gameSession.identifier
        GKGameSession.remove(withIdentifier: identifier) { (error) in
            completionHandler(error)
        }
    }
    
	open func loadData(for gameSession: GKGameSession, completionHandler:@escaping (_ data: Data?,_ error:Error?) -> Void) {
		gameSession.loadData { (data, error) in
			completionHandler(data, error)
		}
	}

    open func save(_ data: Data, for gameSession: GKGameSession, completionHandler: @escaping (_ conflictingData: Data?,_ error:Error?) -> Void) {
        gameSession.save(data) { (conflictingData, error) in
            Log.message("Conflicting Data")
            completionHandler(conflictingData, error)
        }
    }
    
    open func invitePlayer(withActivityItems activityItems: [UIActivityItemProvider], completionHandler:@escaping (UIActivityType?, Bool, [Any]?, Error?) -> Void) {
		
		let activityViewController : UIActivityViewController = UIActivityViewController(
			activityItems: activityItems, applicationActivities: nil)
		
		activityViewController.completionWithItemsHandler = {
			(string, success, items, error) in
			completionHandler(string, success, items, error)
		}
		
		activityViewController.excludedActivityTypes = [UIActivityType.print, UIActivityType.addToReadingList, UIActivityType.openInIBooks]
		if let
			appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
			let window = appDelegate.window,
			let rootViewController = window!.rootViewController {
			rootViewController.present(activityViewController, animated: true) {
				Log.message("Done")
			}
		}
	}
}

extension GameSessionsManager: GKGameSessionEventListener {
	
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
		
		// Warning Unexpected Behavior
		// cloudPlayer had a different type of playerID (CloudKit?) and no Display Name when it is not the current user.
		// Workaround
		
		// Get the last known players
		var previousPlayers = [GKCloudPlayer]()
		let group = DispatchGroup()
		group.enter()
		// Retrieve the previous Players for the gameSession
		if let previousGameSession = gameSessions.filter ({$0.identifier == session.identifier}).first {
			group.leave()
			previousPlayers = previousGameSession.players
		}
		
		group.enter()
		if cloudPlayer.displayName != nil {
			// If there is a cloudPlayer.displayName then this is the local GKCloudPlayer.
			// This could change if Apple fixes these callbacks.
			group.leave()
		}
		else {
			// Recursively search for the added player
			getPlayerAdded(to: previousPlayers, in: session) { [weak self] (player, error) in
				if let player = player, let displayName = player.displayName {
					// Notify that the player has been added with a local notification.
					let content = UNMutableNotificationContent()
					content.sound = UNNotificationSound.default()
					content.title = "Game Session Test"
					content.body = "Added Participant \(displayName) to Session. Repeated \(self?.repeatCount ?? 0) times."
					let trigger = UNTimeIntervalNotificationTrigger(timeInterval:0.1, repeats: false)
					let notificationInfoToSend = UNNotificationRequest(identifier: "GKSessionTest", content: content, trigger: trigger)
					DispatchQueue.main.async {
						UNUserNotificationCenter.current().add(notificationInfoToSend) { (error : Error?) in
							if let error = error {
								Log.error(with: #line, functionName: #function, error: error)
							}
						}
					}
				}
				group.leave()
			}
		}
		
		group.notify(queue: .main) {
			Log.message("Finished")
		}
		
		loadSessions()
	}
	
	public func session(_ session: GKGameSession, didRemove cloudPlayer: GKCloudPlayer) {
		// Get the last known players
		var previousPlayers = [GKCloudPlayer]()
		let group = DispatchGroup()
		group.enter()
		// Retrieve the previous Players for the gameSession
		if let previousGameSession = gameSessions.filter ({$0.identifier == session.identifier}).first {
			group.leave()
			previousPlayers = previousGameSession.players
		}
		
		group.enter()
		// Recursively search for the removed player
		getPlayerRemoved(from: previousPlayers, in: session) { [weak self] (player, error) in
			if let player = player, let displayName = player.displayName {
				// Notify that the player has been added with a local notification.
				let content = UNMutableNotificationContent()
				content.sound = UNNotificationSound.default()
				content.title = "Game Session Test"
				content.body = "Removed Participant \(displayName) to Session. Repeated \(self?.repeatCount ?? 0) times."
				let trigger = UNTimeIntervalNotificationTrigger(timeInterval:0.1, repeats: false)
				let notificationInfoToSend = UNNotificationRequest(identifier: "GKSessionTest", content: content, trigger: trigger)
				DispatchQueue.main.async {
					UNUserNotificationCenter.current().add(notificationInfoToSend) { (error : Error?) in
						if let error = error {
							Log.error(with: #line, functionName: #function, error: error)
						}
					}
				}
			}
			group.leave()
		}

		group.notify(queue: .main) {
			Log.message("Finished")
		}
		loadSessions()
	}
	
	public func session(_ session: GKGameSession, didReceiveMessage message: String, with data: Data, from player: GKCloudPlayer) {
		
	}
	
	public func session(_ session: GKGameSession, player: GKCloudPlayer, didChange state: GKConnectionState) {
		Log.message("Player \(player ) Changed State to \(state)")
	}
	
	public func session(_ session: GKGameSession, player: GKCloudPlayer, didSave data: Data) {
		Log.message("Player \(player ) Did Save Data \(data)")
	}
	
	public func session(_ session: GKGameSession, didReceive data: Data, from cloudPlayer: GKCloudPlayer) {
		Log.message("Player \(cloudPlayer ) Did Recieve Data \(data)")
	}
}

extension GameSessionsManager: UNUserNotificationCenterDelegate {
	
	func setupNotficationManagerDelegate() {
		let center = UNUserNotificationCenter.current()
		center.delegate = self
	}
	
	// The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
	public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Swift.Void) {
		completionHandler([.sound, .alert])
	}
}

extension GameSessionsManager {
	/// Use to work around a bug where the added Players are not immediately availble via the callback
	func getPlayerAdded(to previousPlayers: [GKCloudPlayer], in session: GKGameSession, completionHandler:@escaping (_ player: GKCloudPlayer?, Error?) -> Void) {
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
			GKGameSession.load(withIdentifier: session.identifier, completionHandler: { [weak self] (session, error) in
				if let session = session {
					let playerAdded = session.players.filter ({!previousPlayers.contains($0)}).first
					if let player = playerAdded, player.displayName != nil {
						completionHandler(playerAdded, error)
					}
					else {
						self?.repeatCount += 1
						self?.getPlayerAdded(to: previousPlayers, in: session, completionHandler: { (player, error) in
							completionHandler(player, error)
						})
					}
				}
			})
		})
	}
	
	/// Use to work around a bug where the removed Players are not immediately availble via the callback
	func getPlayerRemoved(from previousPlayers: [GKCloudPlayer], in session: GKGameSession, completionHandler:@escaping (_ player: GKCloudPlayer?, Error?) -> Void) {
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
			GKGameSession.load(withIdentifier: session.identifier, completionHandler: { [weak self] (session, error) in
				if let session = session {
					let playerRemoved = previousPlayers.filter ({!session.players.contains($0)}).first
					if let player = playerRemoved, player.displayName != nil {
						completionHandler(playerRemoved, error)
					}
					else {
						self?.repeatCount += 1
						self?.getPlayerRemoved(from: previousPlayers, in: session, completionHandler: { (player, error) in
							completionHandler(player, error)
						})
					}
				}
			})
		})
	}
}

