import Foundation

struct Article: Codable, Hashable {
    let source: Source
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?

    struct Source: Codable, Hashable {
        let id: String?
        let name: String
    }

    // Stable identity across API responses and Core Data
    func hash(into hasher: inout Hasher) { hasher.combine(url) }
    static func == (lhs: Article, rhs: Article) -> Bool { lhs.url == rhs.url }
}

struct NewsResponse: Codable {
    let status: String
    let totalResults: Int?
    let articles: [Article]
    let message: String?     // present when status == "error"
}
