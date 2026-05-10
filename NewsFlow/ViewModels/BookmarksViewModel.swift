import Foundation

final class BookmarksViewModel {
    private(set) var articles: [Article] = []

    func reload() {
        articles = CoreDataManager.shared.fetchAllSaved().map { $0.toArticle() }
    }

    func removeArticle(at index: Int) {
        let article = articles[index]
        CoreDataManager.shared.removeArticle(article)
        articles.remove(at: index)
    }
}
