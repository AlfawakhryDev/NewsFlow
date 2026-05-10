import Foundation

@MainActor
final class SearchViewModel {
    enum State { case idle, loading, loaded([Article]), empty, error(String) }
    var onStateChange: ((State) -> Void)?

    private var currentTask: Task<Void, Never>?
    private var currentPage = 1
    private(set) var articles: [Article] = []
    private(set) var lastQuery = ""

    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            articles = []
            onStateChange?(.idle)
            return
        }
        lastQuery = trimmed
        currentPage = 1
        currentTask?.cancel()
        onStateChange?(.loading)

        currentTask = Task {
            do {
                let result = try await NewsAPIService.shared.searchArticles(query: trimmed, page: 1)
                guard !Task.isCancelled else { return }
                articles = result
                onStateChange?(result.isEmpty ? .empty : .loaded(result))
            } catch is CancellationError {
                return
            } catch {
                onStateChange?(.error(error.localizedDescription))
            }
        }
    }

    func loadNextPage() {
        guard !lastQuery.isEmpty else { return }
        currentPage += 1
        currentTask = Task {
            guard let result = try? await NewsAPIService.shared.searchArticles(query: lastQuery, page: currentPage),
                  !Task.isCancelled else { return }
            articles += result
            onStateChange?(.loaded(articles))
        }
    }

    func isBookmarked(_ article: Article) -> Bool {
        CoreDataManager.shared.isSaved(article)
    }

    func toggleBookmark(for article: Article) -> Bool {
        let cd = CoreDataManager.shared
        if cd.isSaved(article) { cd.removeArticle(article); return false }
        cd.saveArticle(article); return true
    }
}
