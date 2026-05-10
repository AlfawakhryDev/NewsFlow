import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed
    case apiError(String)
    case noInternet

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL."
        case .requestFailed(let c): return "Request failed (HTTP \(c))."
        case .decodingFailed:       return "Failed to parse server response."
        case .apiError(let msg):    return msg
        case .noInternet:           return "No internet connection."
        }
    }
}

final class NewsAPIService {
    static let shared = NewsAPIService()
    private init() {}

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    // MARK: - Top Headlines
    func fetchTopHeadlines(category: String = "general", country: String = "us") async throws -> [Article] {
        var components = URLComponents(string: "\(Constants.API.baseURL)/top-headlines")!
        components.queryItems = [
            .init(name: "country",  value: country),
            .init(name: "category", value: category),
            .init(name: "pageSize", value: "40"),
            .init(name: "apiKey",   value: Constants.API.newsAPIKey),
        ]
        return try await fetch(components: components)
    }

    // MARK: - Search
    func searchArticles(query: String, page: Int = 1) async throws -> [Article] {
        var components = URLComponents(string: "\(Constants.API.baseURL)/everything")!
        components.queryItems = [
            .init(name: "q",        value: query),
            .init(name: "sortBy",   value: "publishedAt"),
            .init(name: "pageSize", value: "30"),
            .init(name: "page",     value: "\(page)"),
            .init(name: "apiKey",   value: Constants.API.newsAPIKey),
        ]
        return try await fetch(components: components)
    }

    // MARK: - Private fetch
    private func fetch(components: URLComponents) async throws -> [Article] {
        guard let url = components.url else { throw APIError.invalidURL }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw APIError.noInternet
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.requestFailed(http.statusCode)
        }

        let decoded: NewsResponse
        do {
            decoded = try JSONDecoder().decode(NewsResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }

        if decoded.status == "error", let msg = decoded.message {
            throw APIError.apiError(msg)
        }

        return decoded.articles.filter { !$0.title.contains("[Removed]") }
    }
}
