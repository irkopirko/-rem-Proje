import Foundation

enum TattooMistakeChallengeCatalog {
    /// Ana oyun: görselde 2 eğitim amaçlı hata bulunur.
    static let mainChallenge = TattooMistakeChallenge(
        id: UUID(uuidString: "A1000001-0000-4000-8000-000000000001")!,
        imageName: "TattooMistakeCat",
        title: "Geometrik Kedi Kompozisyonu",
        instruction: "Görseldeki 2 hatalı bölgeyi bul.",
        timeLimit: 60,
        difficulty: .easy,
        mistakes: [
            TattooMistake(
                id: UUID(uuidString: "B1000001-0000-4000-8000-000000000001")!,
                title: "Blowout hatası",
                shortExplanation: "Sol çerçeve kenarında mürekkep cilt altına taşmış; kenar bulanık ve gri halo oluşmuş. İğne derinliği fazla olduğunda blowout görülür.",
                normalizedX: 0.305,
                normalizedY: 0.525,
                normalizedWidth: 0.09,
                normalizedHeight: 0.16
            ),
            TattooMistake(
                id: UUID(uuidString: "B1000002-0000-4000-8000-000000000002")!,
                title: "Çizgi kalınlığının aniden incelmesi",
                shortExplanation: "Yıldız geometrisindeki çizgi bir noktada kalın akıştan aniden ince geçişe düşmüş. Tutarlı baskı ve hız kontrolü bu hatayı önler.",
                normalizedX: 0.47,
                normalizedY: 0.44,
                normalizedWidth: 0.08,
                normalizedHeight: 0.10
            )
        ]
    )

    static let all: [TattooMistakeChallenge] = [mainChallenge]

    static func randomChallenge(excluding lastID: UUID?) -> TattooMistakeChallenge {
        mainChallenge
    }
}
