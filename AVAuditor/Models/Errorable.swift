//
//  BaseManager.swift
// AVAuditor
//
//  Created by Eli Hartnett on 5/6/23.
//

import Foundation

class Errorable: NSObject, ObservableObject {
    @Published var errorMessage = Constants.emptyString
}
