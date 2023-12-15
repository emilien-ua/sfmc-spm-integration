//
//  Logger.swift
//  sfmc-spm-integration
//
//  Created by Émilien Roussel on 15/12/2023.
//

import Foundation

enum LoggerScope {
    case appDelegate
    case contentView

    var value: String {
        switch self {
        case .appDelegate: "AppDelegate"
        case .contentView: "ContentView"
        }
    }
}

struct Logger {
    static func print(_ scope: LoggerScope, _ text: String) {
        Swift.print("[App][\(scope.value)] - \(text)")
    }
}
