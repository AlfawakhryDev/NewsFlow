import UIKit

final class SearchViewController: UIViewController {

    // MARK: - UI
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = .systemGroupedBackground
        tv.rowHeight = Constants.UI.cellHeight + 12
        tv.keyboardDismissMode = .onDrag
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyStateLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 15)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder = "Search articles…"
        return sc
    }()

    // MARK: - State
    private let viewModel = SearchViewModel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        bindViewModel()
    }

    // MARK: - Layout
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        tableView.register(ArticleTableViewCell.self, forCellReuseIdentifier: ArticleTableViewCell.reuseID)
        tableView.dataSource = self
        tableView.delegate   = self
    }

    // MARK: - Bind
    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            switch state {
            case .idle:
                self.activityIndicator.stopAnimating()
                self.tableView.isHidden    = false
                self.emptyStateLabel.isHidden = true
                self.tableView.reloadData()
            case .loading:
                self.activityIndicator.startAnimating()
                self.emptyStateLabel.isHidden = true
            case .loaded:
                self.activityIndicator.stopAnimating()
                self.tableView.isHidden = false
                self.emptyStateLabel.isHidden = true
                self.tableView.reloadData()
            case .empty:
                self.activityIndicator.stopAnimating()
                self.tableView.isHidden = true
                self.emptyStateLabel.text = "No results for \"\(self.viewModel.lastQuery)\""
                self.emptyStateLabel.isHidden = false
            case .error(let msg):
                self.activityIndicator.stopAnimating()
                self.showAlert(title: "Search Error", message: msg)
            }
        }
    }
}

// MARK: - UISearchResultsUpdating
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(performSearch), with: nil, afterDelay: 0.5)
    }

    @objc private func performSearch() {
        viewModel.search(query: searchController.searchBar.text ?? "")
    }
}

// MARK: - UITableViewDataSource
extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleTableViewCell.reuseID, for: indexPath) as! ArticleTableViewCell
        let article = viewModel.articles[indexPath.row]
        cell.configure(with: article, isBookmarked: viewModel.isBookmarked(article))
        cell.onBookmarkTap = { [weak self] in self?.viewModel.toggleBookmark(for: article) }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detail = ArticleDetailViewController(article: viewModel.articles[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Paginate near the end
        if indexPath.row == viewModel.articles.count - 5 {
            viewModel.loadNextPage()
        }
    }
}
