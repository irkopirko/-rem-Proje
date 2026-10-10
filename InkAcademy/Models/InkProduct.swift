import Foundation

enum InkProductCategory: String, CaseIterable, Codable, Hashable {
    case needle = "İğne"
    case machine = "Makine"
    case ink = "Boya"
    case hygiene = "Hijyen"
    case stencil = "Stencil"
    case powerSupply = "Güç Kaynağı"
    case aftercare = "Bakım"
    case accessories = "Aksesuar"
}

struct InkProduct: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var category: InkProductCategory
    var description: String
    var imageName: String
    var relatedLessonIds: [String]
    var usageTips: [String]
    var commonMistakes: [String]
    var techniqueTags: [String]
}

// MARK: - Realistic tattoo equipment catalog

enum TattooProductCatalog {
    private static func item(
        id: String,
        name: String,
        category: InkProductCategory,
        icon: String
    ) -> InkProduct {
        InkProduct(
            id: id,
            name: name,
            category: category,
            description: "",
            imageName: icon,
            relatedLessonIds: [],
            usageTips: [],
            commonMistakes: [],
            techniqueTags: []
        )
    }

    static let all: [InkProduct] = {
        let needleIcon = "dot.circle.and.hand.point.up.left.fill"
        let machineIcon = "bolt.horizontal.fill"
        let inkIcon = "paintpalette.fill"
        let hygieneIcon = "cross.case.fill"
        let stencilIcon = "square.on.square.dashed"
        let powerIcon = "bolt.circle.fill"
        let aftercareIcon = "bandage.fill"
        let accessoriesIcon = "tray.2.fill"

        var products: [InkProduct] = []

        let needles: [(String, String)] = [
            ("0807rl", "0807RL Kartuş İğne"),
            ("1207m1", "1207M1 Magnum Kartuş")
        ]
        products += needles.map { item(id: "prod_needle_\($0.0)", name: $0.1, category: .needle, icon: needleIcon) }

        let machines: [(String, String)] = [
            ("rotary_pen", "Rotary Pen Makine"),
            ("coil", "Bobin Makine")
        ]
        products += machines.map { item(id: "prod_machine_\($0.0)", name: $0.1, category: .machine, icon: machineIcon) }

        let inks: [(String, String)] = [
            ("black", "Siyah Boya"),
            ("gray_wash_set", "Gray Wash Set")
        ]
        products += inks.map { item(id: "prod_ink_\($0.0)", name: $0.1, category: .ink, icon: inkIcon) }

        let hygiene: [(String, String)] = [
            ("nitrile_gloves", "Nitril Eldiven"),
            ("surface_disinfectant", "Yüzey Dezenfektanı")
        ]
        products += hygiene.map { item(id: "prod_hygiene_\($0.0)", name: $0.1, category: .hygiene, icon: hygieneIcon) }

        let stencils: [(String, String)] = [
            ("thermal_paper", "Termal Stencil Kağıdı"),
            ("stencil_primer", "Stencil Primer")
        ]
        products += stencils.map { item(id: "prod_stencil_\($0.0)", name: $0.1, category: .stencil, icon: stencilIcon) }

        let power: [(String, String)] = [
            ("power_supply", "Güç Kaynağı"),
            ("wireless_battery", "Kablosuz Batarya")
        ]
        products += power.map { item(id: "prod_power_\($0.0)", name: $0.1, category: .powerSupply, icon: powerIcon) }

        let aftercare: [(String, String)] = [
            ("aftercare_balm", "Bakım Kremi"),
            ("protective_film", "Koruyucu Film")
        ]
        products += aftercare.map { item(id: "prod_aftercare_\($0.0)", name: $0.1, category: .aftercare, icon: aftercareIcon) }

        let accessories: [(String, String)] = [
            ("ink_cups", "Mürekkep Kabı"),
            ("grip_tape", "Grip Bandı")
        ]
        products += accessories.map { item(id: "prod_accessory_\($0.0)", name: $0.1, category: .accessories, icon: accessoriesIcon) }

        return products
    }()
}
