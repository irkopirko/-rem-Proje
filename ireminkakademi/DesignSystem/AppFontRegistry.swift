import CoreText
import Foundation
import UIKit

/// Registers bundled OFL fonts at launch. Neue Montreal is commercial and is
/// not shipped; `AppTypography` resolves it only if the licensee adds the files.
enum AppFontRegistry {
    private static var didRegister = false

    static func registerIfNeeded() {
        guard !didRegister else { return }
        didRegister = true

        let extensions = ["ttf", "otf"]
        for ext in extensions {
            guard let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) else { continue }
            for url in urls {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static func firstAvailable(_ names: [String]) -> String? {
        names.first { name in
            UIFont(name: name, size: 12) != nil
        }
    }
}
