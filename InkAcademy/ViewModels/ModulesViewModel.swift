import Foundation

@Observable
final class ModulesViewModel {
    var modules: [TrainingModule] = []
    var searchText = ""
    var isLoading = false
    var errorMessage: String?
    var showQRScanner = false

    let moduleService: ModuleServiceProtocol
    let qrService: QRServiceProtocol
    let assignmentService: AssignmentServiceProtocol
    private let accessManager: AccessManager

    init(
        moduleService: ModuleServiceProtocol,
        qrService: QRServiceProtocol,
        assignmentService: AssignmentServiceProtocol,
        accessManager: AccessManager
    ) {
        self.moduleService = moduleService
        self.qrService = qrService
        self.assignmentService = assignmentService
        self.accessManager = accessManager
    }

    var filteredModules: [TrainingModule] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return modules }

        return modules.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query)
        }
    }

    var displayedModules: [TrainingModule] {
        accessManager.displayedModules(from: filteredModules)
    }

    var unlockedModules: [TrainingModule] {
        displayedModules.filter { !$0.isLocked }
    }

    var lockedModules: [TrainingModule] {
        displayedModules.filter(\.isLocked)
    }

    var completedLessonsCount: Int {
        modules.reduce(0) { $0 + $1.completedLessonsCount }
    }

    var overallProgress: Double {
        let allLessons = modules.reduce(0) { $0 + $1.lessons.count }
        guard allLessons > 0 else { return 0 }
        return Double(completedLessonsCount) / Double(allLessons)
    }

    func loadModules() async {
        isLoading = true
        errorMessage = nil

        do {
            modules = try await moduleService.fetchModules()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
