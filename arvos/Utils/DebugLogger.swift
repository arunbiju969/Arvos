//
//  DebugLogger.swift
//  arvos
//
//  Debug logging utility that only prints in DEBUG builds
//

import Foundation

struct DebugLogger {
    /// Log a debug message (only in DEBUG builds)
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] \(function) - \(message)")
        #endif
    }

    /// Log an error message (only in DEBUG builds)
    static func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            print("❌ [\(fileName):\(line)] \(function) - \(message): \(error.localizedDescription)")
        } else {
            print("❌ [\(fileName):\(line)] \(function) - \(message)")
        }
        #endif
    }

    /// Log a warning message (only in DEBUG builds)
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("⚠️ [\(fileName):\(line)] \(function) - \(message)")
        #endif
    }

    /// Log a success message (only in DEBUG builds)
    static func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("✅ [\(fileName):\(line)] \(function) - \(message)")
        #endif
    }

    /// Log network activity (only in DEBUG builds)
    static func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("📡 [\(fileName):\(line)] \(function) - \(message)")
        #endif
    }
}
