import Foundation

final class MockEcosystemCatalogService: EcosystemCatalogServing, @unchecked Sendable {

    func fetchProducts() async -> [InkProduct] {
        try? await Task.sleep(for: .milliseconds(150))
        return TattooProductCatalog.all
    }

    func fetchPracticeTasks() async -> [PracticeTask] {
        try? await Task.sleep(for: .milliseconds(120))
        return [
            PracticeTask(
                id: "prac_stencil_1",
                title: "Stencil hizalama",
                description: "Kağıt stencil ile vücut eğrisi hizalaması.",
                type: .stencil,
                relatedModuleId: ProfileDemoCatalog.modStencil,
                requiredUploadType: "Fotoğraf",
                xpReward: 60,
                status: .pending
            ),
            PracticeTask(
                id: "prac_linework_1",
                title: "Linework çizgisi",
                description: "Fake skin üzerinde düz çizgi seti.",
                type: .drawing,
                relatedModuleId: ProfileDemoCatalog.modLinework,
                requiredUploadType: "Fotoğraf veya kısa video",
                xpReward: 70,
                status: .submitted
            ),
            PracticeTask(
                id: "prac_shade_1",
                title: "Packing alanı",
                description: "Küçük kare packing egzersizi.",
                type: .shading,
                relatedModuleId: ProfileDemoCatalog.modShading,
                requiredUploadType: "Fotoğraf",
                xpReward: 80,
                status: .reviewed
            )
        ]
    }

    func fetchLiveSessions() async -> [LiveSession] {
        try? await Task.sleep(for: .milliseconds(100))
        let soon = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return [
            LiveSession(
                id: "live_1",
                title: "Canlı: Packing soruları",
                description: "Usta eğitmenle canlı soru-cevap ve demo.",
                startDate: soon,
                instructorName: "Usta Deniz",
                meetingURL: URL(string: "https://example.com/live"),
                isReplayAvailable: false,
                replayURL: nil
            )
        ]
    }

    func fetchCertificates() async -> [Certificate] {
        try? await Task.sleep(for: .milliseconds(80))
        return [
            Certificate(
                id: "cert_level_exam",
                title: "Seviye Atlama Sınavı",
                issuedDate: nil,
                level: "Kalfa",
                certificateCode: "INK-CERT-KALFA-2026",
                isUnlocked: false
            ),
            Certificate(
                id: "cert_hygiene",
                title: "Hijyen Uygunluk",
                issuedDate: Date(),
                level: "Acemi",
                certificateCode: "INK-CERT-HYG-001",
                isUnlocked: true
            )
        ]
    }

    func fetchSampleQuizzes() async -> [Quiz] {
        try? await Task.sleep(for: .milliseconds(80))
        return [
            Quiz(
                id: "quiz_hygiene_mock",
                lessonId: ProfileDemoCatalog.lesHygiene,
                questions: [
                    Question(id: "qh1", text: "Eldiven ne zaman değiştirilmelidir?", options: ["Her müşteri sonrası", "Günde bir kez", "Haftada bir"], correctOptionIndex: 0, type: .multipleChoice),
                    Question(id: "qh2", text: "Yüzey dezenfeksiyonu yapılmadan stencil uygulanabilir.", options: ["Doğru", "Yanlış"], correctOptionIndex: 1, type: .trueFalse)
                ],
                passingScore: 2
            ),
            Quiz(
                id: "quiz_needle_mock",
                lessonId: ProfileDemoCatalog.lesLinework,
                questions: [
                    Question(id: "qn1", text: "0807RL kodunda 08 neyi ifade eder?", options: ["Çap", "Taper", "Dönum hızı", "Renk"], correctOptionIndex: 0, type: .needleCodeReading)
                ],
                passingScore: 1
            ),
            Quiz(
                id: "quiz_visual_mock",
                lessonId: ProfileDemoCatalog.lesShade,
                questions: [
                    Question(id: "qv1", text: "Görseldeki packing hatası hangisi?", options: ["Düzensiz nokta", "İdeal packing", "Çok açık açı"], correctOptionIndex: 0, type: .imageErrorFind)
                ],
                passingScore: 1
            ),
            Quiz(
                id: "quiz_level_mock",
                lessonId: "level_gate",
                questions: [
                    Question(id: "ql1", text: "Kartuş iğne hangi parçaya bağlanır?", options: ["Grip", "Pedal", "Power supply", "Stencil"], correctOptionIndex: 0, type: .equipmentMatching),
                    Question(id: "ql2", text: "Stencil transfer öncesi cilt yağlı olmalıdır.", options: ["Doğru", "Yanlış"], correctOptionIndex: 1, type: .trueFalse)
                ],
                passingScore: 2
            )
        ]
    }
}
