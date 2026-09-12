import Foundation
import SwiftData

@Model
final class WebTab: Identifiable {
    @Attribute(.unique) var id: UUID
    var urlString: String
    var customTitle: String?
    var order: Int
    var isPinned: Bool
    var faviconURLString: String?
    var createdAt: Date
    
    init(url: URL, order: Int) {
        self.id = UUID()
        self.urlString = url.absoluteString
        self.order = order
        self.isPinned = false
        self.createdAt = Date()
    }
    
    var url: URL { URL(string: urlString)! }
    var host: String { url.host ?? urlString }
    var firstLetter: String { String(host.prefix(1)).uppercased() }
}

enum WindowMode: String, Codable, CaseIterable {
    case attached
    case detached
}
