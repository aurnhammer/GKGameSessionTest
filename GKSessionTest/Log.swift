//
//  ErrorHandling.swift
//  Notifications
//
//  Created by Bill A on 7/17/16.
//  Copyright © 2016 beaconcrawl.com. All rights reserved.
//

import Foundation

public struct Log {
    
    public static func error(with lineNumber: Int, functionName: String, error: Error?, enabled: Bool = true) {
        #if DEBUG
            if enabled == true {
				if let error = error as NSError? {
                    var messageString: String = "ERROR [\(error.domain): \(error.code) \(error.localizedDescription)]"
                    if error.localizedFailureReason != nil {
                        messageString.append(" \(error.localizedFailureReason!)")
                    }
                    if error.userInfo[NSUnderlyingErrorKey] != nil {
                        messageString.append(" \(error.userInfo[NSUnderlyingErrorKey]!)")
                    }
                    if error.localizedRecoverySuggestion != nil {
                        messageString.append(" \(error.localizedRecoverySuggestion!)")
                    }
                    messageString.append(" \(functionName) — \(lineNumber)]\n")
                    message(messageString)
                }
            }
        #endif
    }
    
    public static func message(_ string:String, enabled: Bool = true) {
        #if DEBUG
            if enabled == true {
                let dateFormatter: DateFormatter = DateFormatter()
                dateFormatter.dateFormat = "h:mm:ss.SSS"
                let dateString = dateFormatter.string(from: Date())
                print ("\n\(dateString) — \(string)")
            }
        #endif
    }
}

