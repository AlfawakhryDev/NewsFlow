import Foundation

@MainActor
final class HeadlinesViewModel {
    // MARK: - State
    enum State {
        case idle, loading, loaded([Article]), error(String)
    }

    var onStateChange: ((State) -> Void)?

    private(set) var articles: [Article] = []
    private(set) var selectedCategory: String = "general"
    private var currentTask: Task<Void, Never>?

    // MARK: - Easter egg — pinned as the featured article
    static let easterEgg = Article(
        source: Article.Source(id: nil, name: "Cairo Tech Daily 🗞"),
        author: "Newsroom",
        title: "Breaking: iOS Developer Abdelrahman Alfawakhry Applies to BlackStone eIT — Insiders Say It's a Perfect Match",
        description: """
        Cairo, Egypt — In a move that has the local tech scene buzzing, iOS developer \
        Abdelrahman Alfawakhry has officially applied for the iOS Developer position at \
        BlackStone eIT. Known for shipping full-stack Swift projects from scratch — \
        including this very app you're reading on — industry insiders are calling it \
        "a perfect match." BlackStone eIT, a leading IT services firm, is reportedly \
        reviewing the application with great interest. The position covers UIKit, \
        Core Data, and RESTful API integration — skills Alfawakhry has already \
        demonstrated in production. Watch this space.
        """,
        url: "https://github.com/AlfawakhryDev/NewsFlow",
        urlToImage: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Camponotus_flavomarginatus_ant.jpg/640px-Camponotus_flavomarginatus_ant.jpg",
        publishedAt: ISO8601DateFormatter().string(from: Date()),
        content: nil
    )

    // MARK: - Load
    func load(category: String? = nil) {
        let cat = category ?? selectedCategory
        selectedCategory = cat
        currentTask?.cancel()
        onStateChange?(.loading)

        currentTask = Task {
            do {
                var result = try await NewsAPIService.shared.fetchTopHeadlines(category: cat)
                guard !Task.isCancelled else { return }
                // Pin easter egg as the hero article on General tab only
                if cat == "general" {
                    result.insert(HeadlinesViewModel.easterEgg, at: 0)
                }
                articles = result
                onStateChange?(.loaded(result))
            } catch is CancellationError {
                return
            } catch {
                onStateChange?(.error(error.localizedDescription))
            }
        }
    }

    // MARK: - Bookmark toggle
    func toggleBookmark(for article: Article) -> Bool {
        let cd = CoreDataManager.shared
        if cd.isSaved(article) {
            cd.removeArticle(article)
            return false
        } else {
            cd.saveArticle(article)
            return true
        }
    }

    func isBookmarked(_ article: Article) -> Bool {
        CoreDataManager.shared.isSaved(article)
    }
}
