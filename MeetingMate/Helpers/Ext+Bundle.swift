//
//  Ext+Bundle.swift
//  MeetingMate
//
//  Created by Eli Hartnett on 5/6/23.
//

import Foundation

extension Bundle {

    var shortVersion: String {
        if let result = infoDictionary?["CFBundleShortVersionString"] as? String {
            return result
        } else {
            assert(false)
            return ""
        }
    }

    var buildVersion: String {
        if let result = infoDictionary?["CFBundleVersion"] as? String {
            return result
        } else {
            assert(false)
            return ""
        }
    }

    var fullVersion: String { "\(shortVersion) (\(buildVersion))" }
}