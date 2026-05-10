import UIKit

final class HeadlinesViewController: UIViewController {

    // MARK: - UI
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = .systemGroupedBackground
        tv.rowHeight = Constants.UI.cellHeight + 12
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let refreshControl = UIRefreshControl()

    private let emptyStateView: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.text = "No articles found."
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: v.centerYAnchor),
        ])
        return v
    }()

    // MARK: - State
    private let viewModel = HeadlinesViewModel()
    private var isLoading = false
    private var displayedArticles: [Article] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Top Headlines"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        bindViewModel()
        viewModel.load()
    }

    // MARK: - Setup
    private func setupUI() {
        view.addSubview(categoryCollectionView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            categoryCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: Constants.UI.categoryHeight),

            tableView.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: tableView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
        ])

        // Category collection view
        categoryCollectionView.register(CategoryCollectionViewCell.self,
                                         forCellWithReuseIdentifier: CategoryCollectionViewCell.reuseID)
        categoryCollectionView.dataSource = self
        categoryCollectionView.delegate   = self
        categoryCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: [])

        // Table view
        tableView.register(ArticleTableViewCell.self, forCellReuseIdentifier: ArticleTableViewCell.reuseID)
        tableView.register(ShimmerCell.self, forCellReuseIdentifier: ShimmerCell.reuseID)
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self else { return }
            self.refreshControl.endRefreshing()
            switch state {
            case .idle: break
            case .loading:
                self.isLoading = true
                self.emptyStateView.isHidden = true
                self.tableView.reloadData()
            case .loaded(let articles):
                self.isLoading = false
                self.displayedArticles = articles
                self.emptyStateView.isHidden = !articles.isEmpty
                self.tableView.reloadData()
                self.animateVisibleCells()
            case .error(let message):
                self.isLoading = false
                self.tableView.reloadData()
                self.showAlert(title: "Error", message: message)
            }
        }
    }

    @objc private func refresh() { viewModel.load() }

    // MARK: - Core Animation: staggered cell entry
    private func animateVisibleCells() {
        tableView.visibleCells.enumerated().forEach { index, cell in
            guard let articleCell = cell as? ArticleTableViewCell else { return }
            articleCell.animateIn(delay: Double(index) * 0.04)
        }
    }
}

// MARK: - UITableViewDataSource
extension HeadlinesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isLoading ? 8 : displayedArticles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoading {
            return tableView.dequeueReusableCell(withIdentifier: ShimmerCell.reuseID, for: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleTableViewCell.reuseID, for: indexPath) as! ArticleTableViewCell
        let article = displayedArticles[indexPath.row]
        cell.configure(with: article, isBookmarked: viewModel.isBookmarked(article))
        cell.onBookmarkTap = { [weak self] in
            self?.viewModel.toggleBookmark(for: article)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HeadlinesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isLoading else { return }
        let article = displayedArticles[indexPath.row]
        let detail = ArticleDetailViewController(article: article)
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !isLoading, let articleCell = cell as? ArticleTableViewCell else { return }
        articleCell.animateIn(delay: 0)
    }
}

// MARK: - UICollectionViewDataSource
extension HeadlinesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Constants.Categories.all.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.reuseID, for: indexPath) as! CategoryCollectionViewCell
        let cat = Constants.Categories.all[indexPath.item]
        cell.configure(title: cat.title, icon: cat.icon)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HeadlinesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = Constants.Categories.all[indexPath.item].value
        viewModel.load(category: category)
    }
}
