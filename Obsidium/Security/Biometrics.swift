//
//  Biometrics.swift
//  Obsidium
//
//  A thin wrapper over LocalAuthentication used to gate sensitive actions
//  (delete, export). Falls back to the device passcode when biometrics aren't
//  enrolled, via `.deviceOwnerAuthentication`.
//

import Foundation
import LocalAuthentication

enum Biometrics {

    /// Whether the device can evaluate biometrics or a passcode.
    static var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    /// Prompt the user; returns true only on success.
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
