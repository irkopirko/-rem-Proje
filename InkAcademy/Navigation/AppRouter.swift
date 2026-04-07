import SwiftUI

@Observable
final class AppRouter {
    private let authKey = "InkAcademy.isAuthenticated"

    var isAuthenticated: Bool {
        didSet {
            UserDefaults.standard.set(isAuthenticated, forKey: authKey)
        }
    }

    init() {
        self.isAuthenticated = UserDefaults.standard.bool(forKey: authKey)
    }
}
