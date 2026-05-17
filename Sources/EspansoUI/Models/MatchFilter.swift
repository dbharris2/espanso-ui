enum MatchFilter: String, CaseIterable, Identifiable {
    case all
    case text
    case images

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all: "All"
        case .text: "Text"
        case .images: "Images"
        }
    }

    func includes(_ match: EspansoMatch) -> Bool {
        switch self {
        case .all: true
        case .text: !match.isImage
        case .images: match.isImage
        }
    }
}
