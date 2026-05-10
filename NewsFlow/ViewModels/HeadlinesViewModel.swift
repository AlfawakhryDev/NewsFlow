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

    // MARK: - Load
    func load(category: String? = nil) {
        let cat = category ?? selectedCategory
        selectedCategory = cat
        currentTask?.cancel()
        onStateChange?(.loading)

        currentTask = Task {
            do {
                let result = try await NewsAPIService.shared.fetchTopHeadlines(category: cat)
                guard !Task.isCancelled else { return }
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
