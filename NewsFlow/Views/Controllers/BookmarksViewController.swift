import UIKit

final class BookmarksViewController: UIViewController {

    // MARK: - UI
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = .systemGroupedBackground
        tv.rowHeight = Constants.UI.cellHeight + 12
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyStateView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        let icon = UIImageView(image: UIImage(systemName: "bookmark.slash"))
        icon.tintColor = .systemGray3
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "No bookmarks yet.\nTap the bookmark icon on any article."
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(stack)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 60),
            icon.heightAnchor.constraint(equalToConstant: 60),
            stack.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -40),
        ])
        return v
    }()

    // MARK: - State
    private let viewModel = BookmarksViewModel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
        tableView.reloadData()
        updateEmptyState()
    }

    // MARK: - Layout
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.register(ArticleTableViewCell.self, forCellReuseIdentifier: ArticleTableViewCell.reuseID)
        tableView.dataSource = self
        tableView.delegate   = self
    }

    private func updateEmptyState() {
        let isEmpty = viewModel.articles.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty

        if !isEmpty {
            // Staggered reveal on appear
            tableView.visibleCells.enumerated().forEach { index, cell in
                guard let c = cell as? ArticleTableViewCell else { return }
                c.animateIn(delay: Double(index) * 0.05)
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension BookmarksViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleTableViewCell.reuseID, for: indexPath) as! ArticleTableViewCell
        let article = viewModel.articles[indexPath.row]
        cell.configure(with: article, isBookmarked: true)
        cell.onBookmarkTap = { [weak self] in
            guard let self else { return }
            self.viewModel.removeArticle(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            self.updateEmptyState()
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension BookmarksViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detail = ArticleDetailViewController(article: viewModel.articles[indexPath.row])
        navigationController?.pushViewController(detail, animated: true)
    }

    // Swipe-to-delete
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, done in
            guard let self else { return }
            self.viewModel.removeArticle(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.updateEmptyState()
            done(true)
        }
        delete.image = UIImage(systemName: "bookmark.slash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
