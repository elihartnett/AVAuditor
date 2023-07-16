//
// Enums.swift
// AVAuditor
//
// Created by Eli Hartnett on 5/21/23.
//

import Foundation

enum VideoGravity: Identifiable, CaseIterable {
    
    case fit
    case fill
    
    var title: String {
        switch self {
        case .fit:
            return Constants.scaleToFitTitle
        case .fill:
            return Constants.scaleToFillTitle
        }
    }
    
    var tag: String {
        switch self {
        case .fit:
            return Constants.scaleToFitTag
        case .fill:
            return Constants.scaleToFillTag
        }
    }
    
    var id: String {
        switch self {
        case .fit:
            return Constants.scaleToFitTag
        case .fill:
            return Constants.scaleToFillTag
        }
    }
}

enum NavigableViews: Hashable {
    case settings
}
