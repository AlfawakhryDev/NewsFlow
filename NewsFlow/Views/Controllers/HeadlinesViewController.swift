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
        tv.separatorStyle  = .none
        tv.backgroundColor = .systemGroupedBackground
        tv.rowHeight       = UITableView.automaticDimension
        tv.estimatedRowHeight = Constants.UI.cellHeight + 12
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

        categoryCollectionView.register(CategoryCollectionViewCell.self,
                                         forCellWithReuseIdentifier: CategoryCollectionViewCell.reuseID)
        categoryCollectionView.dataSource = self
        categoryCollectionView.delegate   = self
        categoryCollectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: [])

        tableView.register(FeaturedArticleCell.self, forCellReuseIdentifier: FeaturedArticleCell.reuseID)
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
            switch cell {
            case let c as FeaturedArticleCell:
                c.alpha = 0; c.transform = CGAffineTransform(translationX: 0, y: 30)
                UIView.animate(withDuration: 0.5, delay: 0,
                               usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                    c.alpha = 1; c.transform = .identity
                }
            case let c as ArticleTableViewCell:
                c.animateIn(delay: Double(index) * 0.04)
            default: break
            }
        }
    }

    // MARK: - Easter egg badge style
    private func badgeInfo(for article: Article) -> (text: String, color: UIColor) {
        if article.url == HeadlinesViewModel.easterEgg.url {
            return ("🚨 BREAKING", .systemRed)
        }
        return ("FEATURED", Constants.UI.primaryColor)
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

        let article = displayedArticles[indexPath.row]

        // First article → hero featured card
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: FeaturedArticleCell.reuseID,
                                                     for: indexPath) as! FeaturedArticleCell
            let badge = badgeInfo(for: article)
            cell.configure(with: article, badge: badge.text, badgeColor: badge.color,
                           isBookmarked: viewModel.isBookmarked(article))
            cell.onBookmarkTap = { [weak self] in self?.viewModel.toggleBookmark(for: article) }
            return cell
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleTableViewCell.reuseID,
                                                  for: indexPath) as! ArticleTableViewCell
        cell.configure(with: article, isBookmarked: viewModel.isBookmarked(article))
        cell.onBookmarkTap = { [weak self] in self?.viewModel.toggleBookmark(for: article) }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !isLoading && indexPath.row == 0 { return FeaturedArticleCell.rowHeight }
        return Constants.UI.cellHeight + 12
    }
}

// MARK: - UITableViewDelegate
extension HeadlinesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isLoading else { return }
        let detail = ArticleDetailViewController(article: displayedArticles[indexPath.row])
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.reuseID,
                                                       for: indexPath) as! CategoryCollectionViewCell
        let cat = Constants.Categories.all[indexPath.item]
        cell.configure(title: cat.title, icon: cat.icon)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension HeadlinesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.load(category: Constants.Categories.all[indexPath.item].value)
    }
}
