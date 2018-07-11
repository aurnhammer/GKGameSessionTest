//
//  ViewController.swift
//  GKGameSessionTest
//
//  Created by Bill A on 3/14/17.
//  Copyright © 2017 aurnhammer. All rights reserved.
//

import UIKit
import GameKit


class ViewController: UIViewController {

    var data: Data?
	var gameSessionManager: GameSessionsManager?
	var localPlayer: GKCloudPlayer?
    var gameSession: GKGameSession? {
        didSet {
            inviteButton.isEnabled = gameSession != nil
        }
    }
    
    var accountManager: AccountManager!

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var inviteButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        Log.message("\((#file as NSString).lastPathComponent): " + #function)
    }
    
    deinit {
        stopListening()
        Log.message("\((#file as NSString).lastPathComponent): " + #function)
    }
    
    func setup() {
        accountManager = AccountManager()
		accountManager.isGameCenterAccountAvailable { (isAvailable, error) in
			self.gameSessionManager = GameSessionsManager.shared
			self.startListening()
			//self.gameSessionManager?.loadSessions()
//			self.gameSessionManager?.loadSessions(completionHandler: { [weak self] (sessions, error) in
//				if let sessions = sessions, !sessions.isEmpty {
//					self?.gameSession = sessions.first
//				}
//			})

		}
    }

    @IBAction func createSession(_ sender: UIButton) {
		GameSessionsManager.shared.createSession(with: "Title", andMaxPlayerCount: 16, completionHandler: { [weak self] (gameSession, error) in
               self?.gameSession = gameSession
        })
    }
	
	@IBAction func removeCurrentSessions(_ sender: UIButton) {
		if let gameSession = self.gameSession	{
			GKGameSession.remove(withIdentifier: gameSession.identifier, completionHandler: { (error) in
				Log.error(with: #line, functionName: #function, error: error)
				self.gameSession = nil
				if let displayName = self.localPlayer?.displayName {
					self.textView.text = "\(displayName) removed from session\n"
				}
			})
		}
	}

	@IBAction func removeAllSessions(_ sender: UIButton) {
		self.gameSessionManager?.removeAll()
		self.gameSession = nil
	}


    @IBAction func inviteOthers(_ sender: UIButton) {
        guard let gameSession = gameSession else {
            Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
            return
        }
		DispatchQueue.main.async {
			let urlProvider = GameSessionURLProvider(placeholderItem: URL(string:"http://disctrictapp.com") as AnyObject, gameSession:gameSession)
			
			GameSessionsManager.shared.invitePlayer(withActivityItems: [urlProvider]){ (activityType, success, items, error) in
				//let successText = success == true ? "Success" : " Cancelled"
				//self.textView.text = "Invited Players to \(gameSession.title) \(successText)"
			}
		}
     }
    
    
    @IBAction func loadData(_ sender: UIButton) {
        self.gameSession?.loadData { (data, error) in
            self.data = data
            if let data = data {
                guard let string = String(data: data, encoding: .utf8) else {
                    Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
                    return
                }
				let playerNames =  self.gameSession?.players.compactMap(){$0.displayName}
                self.textView.text = "LoadedData \(string) for " + "session \(playerNames!) players)"
            }
        }
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
					if let playerNames = self?.gameSession?.players.compactMap({$0.displayName}) {
						self?.textView.text = "Save Data \(text) for " + "session \(playerNames) players)"
					}
				})
			}
		}))
		self.present(alert, animated: true, completion: nil)
     }
	
	func save(data: Data, completionHandler:(() -> Swift.Void)?) {
		self.gameSession?.save(data, completionHandler: { (confictingData, error) in
			Log.error(with: #line, functionName: #function, error: error)
			// Handle error
			if nil == error {
				completionHandler?()
			}
			else {
				//if let confictingData = confictingData {
					self.save(data: data, completionHandler: { () in
						completionHandler?()
					})
				//}
			}
		})
	}
    
    @IBAction func sendMessage(_ sender: UIButton) {
		let alert = UIAlertController(title: "Send Message", message: "Enter text", preferredStyle: .alert)
		alert.addTextField()
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] (_) in
			if let text = alert?.textFields?[0].text, let players = self?.gameSession?.players {
				self?.gameSession?.sendMessage(withLocalizedFormatKey: "%@", arguments: [text], data: nil, to: players, badgePlayers: false) { (error) in
					Log.error(with: #line, functionName: #function, error: error)
					if nil == error, let playerNames = self?.gameSession?.players.compactMap({$0.displayName}) {
						self?.textView.text = "Send Message \(text) for " + "session \(playerNames) players)"
					}
				}
			}
		}))
		self.present(alert, animated: true, completion: nil)
    }
	
    @IBAction func sendData(_ sender: UIButton) {
		let alert = UIAlertController(title: "Send Data", message: "Enter text", preferredStyle: .alert)
		alert.addTextField()
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] (_) in
			if let text = alert?.textFields?[0].text {
				self?.gameSession?.sendData(text, completionHandler: { (error) in
					Log.error(with: #line, functionName: #function, error: error)
					if nil == error, let playerNames = self?.gameSession?.players.compactMap({$0.displayName}) {
						self?.textView.text = "Send Data \(text) for " + "session \(playerNames) players)"
					}
				})
			}
		}))
		self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func connectToSession(_ sender: UIButton) {
        gameSession?.setConnectionState(GKConnectionState.connected, completionHandler: { (error) in
            Log.error(with: #line, functionName: #function, error: error)
            if error != nil {
                self.textView.text = "\(error.debugDescription)"
            }
            else {
                self.textView.text = "Connection Succesful"
            }
        })
    }
    
    @IBAction func showConnected(_ sender: UIButton) {
		if let players = self.gameSession?.players(with: GKConnectionState.connected), !players.isEmpty {
			let playerNames = players.compactMap({$0.displayName})
			self.textView.text = "Connected \(playerNames)\n"
		}
		else {
			self.textView.text = "No one is connected\n"
		}
    }
    
    
    @IBAction func showLoadingView(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "LoadingViewController")

        var rootViewController: UIViewController?
        if let
            appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
            let window = appDelegate.window {
            rootViewController = window!.rootViewController
            let presentationController = NotificationPresentationController(presentedViewController: controller, presenting: rootViewController)
            
            controller.transitioningDelegate = presentationController
            rootViewController?.present(controller, animated: true, completion:nil)

        }
    }
	
	
    
}

extension GKGameSession {
    
    func sendData(_ string: String, completionHandler: @escaping (_ error:Error?) -> Void) {
        if let data = string.data(using: String.Encoding.utf8) {
            self.send(data, with: GKTransportType.unreliable) { (error) in
                Log.error(with: #line, functionName: #function, error: error)
                completionHandler(error)
            }
        }
        else {
            Log.message("No Data")
        }
    }

    func loadInitialState() {
        let initialGameState = "var adventureData = {\"adventureRecordName\":\" \"TestSession\"};"
        guard let data = initialGameState.data(using: String.Encoding.utf8) else {
            Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
            return
        }
        self.save(data, completionHandler: { (conflictingData, error) in
            if error != nil {
                // handle conflicting data here
                Log.error(with: #line, functionName: #function, error: error)
            }
        })
    }
}

extension ViewController: GKGameSessionEventListener {
    
    func startListening() {
        GKGameSession.add(listener: self)
    }
    
    func stopListening() {
        GKGameSession.remove(listener: self)
    }
    
	public func session(_ session: GKGameSession, didAdd cloudPlayer: GKCloudPlayer) {
		if accountManager.cloudPlayer == session.owner {
			Log.message("This is the Owner")
		}
		if let displayName = cloudPlayer.displayName {
			// Adding when the local user is added
			self.textView.text = "\(displayName) added to \(session.title)\n"
			self.gameSession = session
			self.localPlayer = cloudPlayer
		}
		else {
			let dispatchGroup = DispatchGroup()
			dispatchGroup.enter()
			DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
				if nil == self.gameSession?.players {
					self.gameSessionManager?.loadSessions(completionHandler: { (error) in
						dispatchGroup.leave()
					})
				}
				else {
					dispatchGroup.leave()
				}
			}
			
			dispatchGroup.notify(queue: .main) {
				if let previousPlayers = self.gameSession?.players {
					let playerAdded = session.players.filter ({!previousPlayers.contains($0)}).first
					self.gameSession = session
					if let displayName = playerAdded?.displayName {
						self.textView.text = "\(displayName) added to \(session.title)\n"
					}
				}
			}
		}
    }
    
    public func session(_ session: GKGameSession, didRemove player: GKCloudPlayer) {
		let playerRemoved = self.gameSession?.players.filter ({!session.players.contains($0)}).first
		if accountManager.cloudPlayer == session.owner {
			Log.message("This is the Owner")
			if playerRemoved == session.owner {
				self.gameSession = session
				return
			}
		}
        self.gameSession = session
        if let displayName = playerRemoved?.displayName {
            self.textView.text = "\(displayName) removed from session\n"
        }
    }
    
    public func session(_ session: GKGameSession, didReceiveMessage message: String, with data: Data, from cloudPlayer: GKCloudPlayer) {
        self.gameSession = session
        if let player = session.players.filter({$0.playerID == cloudPlayer.playerID}).first,
            let displayName = player.displayName {
            Log.message("did recieve \(message) from player \(displayName)\n")
            self.textView.text = "did recieve \(message) from player \(displayName)\n"
        }
    }

    public func session(_ session: GKGameSession, player: GKCloudPlayer, didChange state: GKConnectionState) {
        self.gameSession = session
        if let displayName = player.displayName {
			self.textView.text = "\(displayName) didChange state: \(state.rawValue == 0 ? "Disconected" : "Connected"), for \(session.title)"
        }
        else {
            self.textView.text = "Connection Unkown"
        }
    }
    
    public func session(_ session: GKGameSession, player: GKCloudPlayer, didSave data: Data) {
		self.gameSession = session
        Log.message("\(player) \(session) \(data)\n")
		if let displayName = player.displayName, let string = String(data: data, encoding:.utf8) {
            self.textView.text = "Did save \(string) from player \(displayName)\n"
        }
    }
    
    public func session(_ session: GKGameSession, didReceive data: Data, from cloudPlayer: GKCloudPlayer) {
		self.gameSession = session
		if let  string = String(data: data, encoding: .utf8) {
			if let displayName = cloudPlayer.displayName {
				self.textView.text = "Did recieve \(string) from player \(displayName)\n"
			} else if let player = session.players.filter({$0.playerID == cloudPlayer.playerID}).first,
				let displayName = player.displayName {
				self.textView.text = "Did recieve \(string) from player \(displayName)\n"
			}
			else {
				self.textView.text = "Did recieve \(string)"
			}
		}
	}
 }


