import Foundation

/// Ink Akademi Crew — uygulama içi sabit portal girişi (analiz dokümanı).
/// Kayıt / OTP gerekmez; normal giriş ekranından aynı akışla açılır.
enum CrewPortalAccess {
    static let email = "inkakademicrew@outlook.com"

    static let username = "inkakademicrew"

    static func validate(identifier: String, password: String) -> Bool {
        let input = identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return (input == email.lowercased() || input == username) && password == portalPassword
    }

    static var portalUser: User {
        User(
            id: "crew-portal-local",
            userNo: nil,
            username: "inkakademicrew",
            email: email,
            firstName: "Ink Akademi",
            lastName: "Crew",
            role: .crew,
            membershipStatus: .plus,
            profilePhotoUrl: nil
        )
    }

    /// Uygulama güncellemesi dışında değiştirilmez (doküman gereği).
    private static var portalPassword: String {
        // Dağınık parçalar — kaynakta düz metin şifre barındırmamak için.
        ["i2A0r2M5", "d1E1", "*"].joined()
    }
}
