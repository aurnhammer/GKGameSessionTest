//
//  AccountManager.swift
//  GKGameSessionTest
//
//  Created by Bill A on 3/17/17.
//  Copyright © 2017 aurnhammer. All rights reserved.
//

import UIKit
import CloudKit
import GameKit

public class AccountManager: NSObject {
    
    open static let shared = AccountManager()

    var userRecordID: CKRecordID?
    var userIdentity: CKUserIdentity?
    var cloudPlayer: GKCloudPlayer?
    
    override init() {
        super.init()
        self.setup()
    }
    
    deinit {
        removeObservers()
        Log.message("\((#file as NSString).lastPathComponent): " + #function)
    }
    
    func setup() {
        setupObservers()
        checkAccountAvailabilty()
    }
    
    func setupObservers() {
        // listen for user login token changes so we can refresh and reflect our UI based on user login
        NotificationCenter.default.addObserver(forName: NSNotification.Name.CKAccountChanged, object: nil, queue: nil) { (notification:Notification) in
            self.checkAccountAvailabilty()
        }
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, forKeyPath: NSNotification.Name.CKAccountChanged.rawValue)
    }
    
    public func accountAvailable(_ completionHandler:@escaping (_ available:Bool) -> Void) {
        GameSessionsManager.container.accountStatus { (accountStatus, error) in
            Log.error(with: #line, functionName: #function, error: error)
            // back on the main queue, call our completion handler
            DispatchQueue.main.async{
                // note: accountStatus could be "CKAccountStatusAvailable", and at the same time there could be no network,
                // in this case the user should not be able to add, remove or modify records
                completionHandler(accountStatus == .available);
            }
        }
    }
    
    /// Check if there is an authenticated account. To do update UI
    func checkAccountAvailabilty() {
		let localPlayer = GKLocalPlayer.localPlayer()
		if localPlayer.isAuthenticated == false {
			GKLocalPlayer.localPlayer().authenticateHandler = { (viewController, error) in
				if viewController != nil {
					if let
						appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
						let window = appDelegate.window {
						let rootViewController = window!.rootViewController
						rootViewController?.present(viewController!, animated: true, completion: {
							Log.message("Test")
						})
					}
				}
				else {
					Log.message("test: \(localPlayer)")
				}
			}
		}
		else {
			Log.message("is Authenticated for Game Center")
		}
		
        self.accountAvailable { (status) in
            switch status {
            case true:
                self.fetchLoggedInUserRecord({ (ckRecordID) in
                    self.userRecordID = ckRecordID
                    if let ckRecordID = ckRecordID  {
                        CKContainer.default().discoverUserIdentity(withUserRecordID: ckRecordID, completionHandler: { (userID, error) in
                            self.userIdentity = userID
							if let userIdentity = self.userIdentity, let nameComponents = userIdentity.nameComponents {
								Log.message("CheckAccount Availablity: \(nameComponents)")
                            }
                        })
                    }
                })
            case false:
                self.alertPlayerNotSignedInToICloud()
            }
        }
    }
    
    func isGameCenterAccountAvailable(completion:@escaping (_ success: Bool?, _ error: Error?) -> Void) {
        GKCloudPlayer.getCurrentSignedInPlayer(forContainer: GameSessionsManager.Container.ID) {(signedInPlayer, error) in
            if signedInPlayer != nil {
                self.cloudPlayer = signedInPlayer
				Log.message("\(String(describing: signedInPlayer))")
                completion(true, error)
            }
            else {
                self.alertPlayerNotSignedInToGameCenter()
                completion(false, error)
            }
        }
    }
    
    func alertPlayerNotSignedInToICloud () {
        let title = "Enable iCloud"
        let message = "To save your games and to play games with others, please open iCloud in Settings and \"Sign In\"."
        let type = "CASTLE"
        alertPlayerNotSignedIn(title: title, message: message, type: type)
    }
    
    func alertPlayerNotSignedInToGameCenter () {
        let title = "Enable iCloud"
        let message = "To save your games and to play games with others, please open iCloud in Settings and \"Sign In\"."
        let type = "CASTLE"
        alertPlayerNotSignedIn(title: title, message: message, type: type)
    }
    
    func alertPlayerNotSignedIn (title: String, message: String, type: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert)
            
            let okay = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(okay)
            
            let openAction = UIAlertAction(title: "Open iCloud", style: .default) { (action) in
                if let url = URL(string:"App-Prefs:root=" + type) {
                    UIApplication.shared.open(url, options: [:], completionHandler:nil)
                }
            }
            alertController.addAction(openAction)
            if let
                appDelegate:UIApplicationDelegate = UIApplication.shared.delegate,
                let window = appDelegate.window,
                let rootViewController = window!.rootViewController {
                rootViewController.present(alertController, animated: true, completion: nil)
            }
        }
    }


    /// Asks for discoverability permission from the user. This will bring up an alert: "Allow people using "GKSessionTest" to look you up by email?", clicking "Don't Allow" will not make you discoverable. The first time you request a permission on any of the user’s devices, the user is prompted to grant or deny the request. Once the user grants or denies a permission, subsequent requests for the same permission (on the same or separate devices) do not prompt the user again.
    func requestDiscoverabilityPermission(_ completionHandler:@escaping (_ discoverable:Bool) -> Void) {
        
        let container = GameSessionsManager.container
        
        container.requestApplicationPermission(CKApplicationPermissions.userDiscoverability) { (applicationPermissionStatus: CKApplicationPermissionStatus, error: Error?) in
            Log.error(with: #line, functionName: #function, error: error)
            DispatchQueue.main.async {
                // back on the main queue, call our completion handler
                completionHandler(applicationPermissionStatus == .granted ? true : false)
            }
        }
    }
    
    
    /// Obtain information on all users in our Address Book
    func fetchAllUsers(_ completionHandler:@escaping (_ identities: [CKUserIdentity]?) -> Void) {
        // Find all discoverable users in the device's address book
        let operation: CKDiscoverAllUserIdentitiesOperation = CKDiscoverAllUserIdentitiesOperation()
        operation.queuePriority = Operation.QueuePriority.normal
        
        //This block is executed once for each identity that is discovered. Each time the block is executed, it is executed serially with respect to the other progress blocks of the operation.
        //If you intend to use this block to process results, set it before executing the operation or submitting the operation object to a queue.
        var identities: [CKUserIdentity]  = []
        operation.userIdentityDiscoveredBlock = { (identity:CKUserIdentity) -> Void in
            identities.append(identity)
        }
        
        // This block is executed only once and represents your last chance to process the operation results. It is executed after all of the individual progress blocks but before the operation’s completion block. The block is executed serially with respect to the other progress blocks of the operation. If you intend to use this block to process results, update the value of this property before executing the operation or submitting the operation object to a queue.
        operation.discoverAllUserIdentitiesCompletionBlock = { (error) -> Void in
            Log.error(with: #line, functionName: #function, error: error)
            DispatchQueue.main.async {
                completionHandler(identities)
            }
        }
        GameSessionsManager.container.add(operation)
    }
    
    
    func fetchLoggedInUserRecord(_ comletionHandler:@escaping (_ recordID: CKRecordID?) -> Void) {
        self.requestDiscoverabilityPermission { (discoverable: Bool) in
            if discoverable {
                let container = GameSessionsManager.container
                container.fetchUserRecordID(completionHandler: { (recordID: CKRecordID?, error:Error?) in
                    Log.error(with: #line, functionName: #function, error: error)
                    // back on the main queue, call our completion handler
                    DispatchQueue.main.async {
                        if let recordID = recordID {
                            comletionHandler(recordID)
                        }
                        else {
                            comletionHandler(nil)
                        }
                    }
                })
            }
            else {
                // can't discover user, return nil user recordID back on the main queue
                DispatchQueue.main.async(execute: {
                    comletionHandler(nil)
                })
                
            }
        }
    }
    
    func isMyRecord(_ recordID: CKRecordID) -> Bool {
        return recordID.recordName == CKCurrentUserDefaultName ? true: false
    }
    
    
    // Discover the given CKRecordID's user's info with CKDiscoverUserInfosOperation, return in its completion handler the last name and first name, if possible. Users of an app must opt in to discoverability before their user records can be accessed.
    func fetchUserName(from recordID: CKRecordID?, completionHandler: @escaping (_ givenName: String?, _ familyName: String?) -> Void) {
        
        guard let recordID: CKRecordID = recordID  else {
            fatalError ("Error fetchUserNameFromRecordID, incoming recordID is nil")
        }
        self.fetchLoggedInUserRecord { (loggedInUserRecordID: CKRecordID?) in
            var recordIDToUse: CKRecordID?
            // we found our login user recordID, is it our photo?
            if self.isMyRecord(recordID) {
                // we own this record, so look up our user name using our login recordID
                recordIDToUse = loggedInUserRecordID;
            }
            else {
                // this recordID is owned by another user, find its user info using the incoming "recordID" directly
                recordIDToUse = recordID;
            }
            if recordIDToUse != nil {
                let discoverOperation: CKDiscoverUserIdentitiesOperation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [CKUserIdentityLookupInfo(userRecordID: recordID)])
                
                var firstName: String?
                var lastName: String?
                discoverOperation.userIdentityDiscoveredBlock = { (userIdentity, userIdentityLookupInfo) -> Void in
                    if let nameComponents = userIdentity.nameComponents,
                        let givenName = nameComponents.givenName,
                        let familyName = nameComponents.familyName {
                        firstName = givenName
                        lastName = familyName
                    }
                }
                
                discoverOperation.discoverUserIdentitiesCompletionBlock = { (operationError) -> Void in
                    DispatchQueue.main.async {
                        Log.error(with: #line, functionName: #function, error: operationError)
                        completionHandler(firstName, lastName)
                    }
                }
                GameSessionsManager.container.add(discoverOperation)
            }
            else  {
                // Could not find our login user recordID (probably because we or the other user are not discoverable) report back with a generic name
                // back on the main queue, call our completion handler
                DispatchQueue.main.async(execute: {
                    completionHandler("Undetermined Login Name", nil)
                })
            }
        }
    }
    
    // Used to update our user information (in case user logged out/in or with a different account), typically you call this when the app becomes active from launch or from the background.
    func updateUserLogin(_ completionHandler:()) {
        // first ask for discoverability permission from the user
        self.requestDiscoverabilityPermission { (discoverable: Bool) in
            // Invoke our caller's completion handler indicating we are done
            if discoverable {
                // First obtain the CKRecordID of the logged in user (we use it to find the user's contact info)
                let container = GameSessionsManager.container
                container.fetchUserRecordID(completionHandler: { (recordID: CKRecordID?, error: Error?) in
                    if error != nil {
                        // no user information will be known at this time
                        self.userIdentity = nil;
                        self.userRecordID = nil;
                        Log.error(with: #line, functionName: #function, error: error)
                        // back on the main queue, call our completion handler
                        DispatchQueue.main.async(execute: {
                            completionHandler // no user information found, due to an error
                        })
                    }
                    else {
                        if let recordID = recordID {
                            self.userRecordID = recordID
                            // retrieve info about the logged in user using it's CKRecordID
                            let container = GameSessionsManager.container
                            container.discoverUserIdentity(withUserRecordID: recordID, completionHandler: { (userIdentity: CKUserIdentity?, error: Error?) in
                                if error != nil  {
                                    // no user information will be known at this time
                                    self.userRecordID = nil
                                    self.userIdentity = nil
                                    Log.error(with: #line, functionName: #function, error: error)
                                }
                                else {
                                    self.userIdentity = userIdentity
                                    guard let nameComponents = userIdentity?.nameComponents else {
                                        Log.message("Guard Failed: \((#file as NSString).lastPathComponent): \(#function)\n")
                                        return
                                    }
									Log.message("logged in as \(nameComponents.givenName ?? "") \(nameComponents.familyName ?? "")")
                                }
                                // back on the main queue, call our completion handler
                                DispatchQueue.main.async(execute: {
                                    completionHandler    // invoke our caller's completion handler indicating we are done
                                })
                                
                            })
                        }
                    }
                })
            }
            else {
                // User info is not discoverable. Back on the main queue, call our completion handler
                DispatchQueue.main.async(execute: {
                    completionHandler   // invoke our caller's completion handler indicating we are done
                })
            }
        }
    }
}
