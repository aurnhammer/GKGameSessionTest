//
//  GameSessionManager.swift
//  BeaconCrawl
//
//  Created by Bill A on 3/4/17.
//  Copyright © 2017 beaconcrawl.com. All rights reserved.
//

import GameKit
import CloudKit


open class GameSessionsManager: NSObject {
    
    public struct Container {
        public static let ID = "iCloud.com.districtapp.test"
    }
    
    public static let container = CKContainer(identifier: GameSessionsManager.Container.ID)

    open static let shared = GameSessionsManager()
    
    var gameSessions: [GKGameSession]?
    
    public override init() {
        super.init()
        Log.message("\((#file as NSString).lastPathComponent): " + #function)
    }
    
    deinit {
        Log.message("\((#file as NSString).lastPathComponent): " + #function)
    }
	
    func loadSessions() {
		GKGameSession.loadSessions(inContainer: Container.ID) { (gameSessions, error) in
            Log.error(with: #line, functionName: #function, error: error)
            self.gameSessions = gameSessions
        }
    }
	
	func loadSessions(completionHandler:@escaping ([GKGameSession]?, Error?) -> Swift.Void) {
		GKGameSession.loadSessions(inContainer: Container.ID) {[weak self] (gameSessions, error) in
			Log.error(with: #line, functionName: #function, error: error)
			self?.gameSessions = gameSessions
			completionHandler(gameSessions, error)
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

    
    open func createSession(withMaxPlayerCount maxPlayersCount: NSInteger, completionHandler:@escaping (_ session:GKGameSession?, _ error: Error?) -> Void) {
        GKGameSession.createSession(inContainer: Container.ID, withTitle: "Test Session", maxConnectedPlayers: maxPlayersCount) { (gameSession, error) in
            Log.error(with: #line, functionName: #function, error: error)
            completionHandler(gameSession, error)
        }
    }

    open func cancelGameSession(_ gameSession: GKGameSession, completionHandler:@escaping (_ error: Error?) -> Void) {
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
