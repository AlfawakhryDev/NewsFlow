import UIKit
import SafariServices

final class ArticleDetailViewController: UIViewController {

    private let article: Article

    // MARK: - Subviews
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let metaLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let readMoreButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Read Full Article"
        config.image = UIImage(systemName: "arrow.up.right")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.cornerStyle = .large
        config.baseBackgroundColor = Constants.UI.primaryColor
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var bookmarkBarButton = UIBarButtonItem(
        image: nil, style: .plain, target: self, action: #selector(bookmarkTapped)
    )

    // MARK: - Init
    init(article: Article) {
        self.article = article
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        setupUI()
        configure()
        updateBookmarkButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runEntryAnimation()
    }

    // MARK: - Layout
    private func setupUI() {
        navigationItem.rightBarButtonItem = bookmarkBarButton
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        [titleLabel, metaLabel, descriptionLabel, readMoreButton].forEach { contentStack.addArrangedSubview($0) }
        contentStack.setCustomSpacing(24, after: metaLabel)
        contentStack.setCustomSpacing(32, after: descriptionLabel)

        // Add padding view
        let paddingView = UIView(); paddingView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        contentStack.addArrangedSubview(paddingView)

        NSLayoutConstraint.activate([
            heroImageView.heightAnchor.constraint(equalToConstant: 220),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])

        // Insert hero image outside the horizontal insets
        scrollView.insertSubview(heroImageView, belowSubview: contentStack)
        NSLayoutConstraint.activate([
            heroImageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heroImageView.heightAnchor.constraint(equalToConstant: 220),
        ])
        // Push the stack below the hero
        contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 228).isActive = true

        readMoreButton.addTarget(self, action: #selector(openInSafari), for: .touchUpInside)
    }

    // MARK: - Configure
    private func configure() {
        titleLabel.text = article.title
        heroImageView.loadImage(from: article.urlToImage)

        var meta = article.source.name
        if let author = article.author, !author.isEmpty { meta += " · \(author)" }
        meta += "\n\(article.publishedAt.formattedPublishDate)"
        metaLabel.text = meta

        descriptionLabel.text = article.description ?? article.content ?? "No description available."
    }

    // MARK: - Core Animation entry
    private func runEntryAnimation() {
        let views: [UIView] = [titleLabel, metaLabel, descriptionLabel, readMoreButton]
        views.enumerated().forEach { index, view in
            view.alpha = 0
            view.transform = CGAffineTransform(translationX: 0, y: 30)
            UIView.animate(withDuration: 0.5,
                           delay: Double(index) * 0.08,
                           usingSpringWithDamping: 0.85,
                           initialSpringVelocity: 0.4,
                           options: .curveEaseOut) {
                view.alpha = 1
                view.transform = .identity
            }
        }

        // Parallax-style hero fade
        heroImageView.alpha = 0
        UIView.animate(withDuration: 0.4) { self.heroImageView.alpha = 1 }
    }

    // MARK: - Actions
    @objc private func openInSafari() {
        guard let url = URL(string: article.url) else { return }
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }

    @objc private func bookmarkTapped() {
        let cd = CoreDataManager.shared
        if cd.isSaved(article) {
            cd.removeArticle(article)
        } else {
            cd.saveArticle(article)
            // Pulse animation on bookmark success
            let pulse = CASpringAnimation(keyPath: "transform.scale")
            pulse.fromValue = 1.3
            pulse.toValue = 1.0
            pulse.stiffness = 250
            pulse.damping = 10
            pulse.duration = 0.5
            navigationItem.rightBarButtonItem?.customView?.layer.add(pulse, forKey: "pulse")
        }
        updateBookmarkButton()
    }

    private func updateBookmarkButton() {
        let name = CoreDataManager.shared.isSaved(article) ? "bookmark.fill" : "bookmark"
        bookmarkBarButton.image = UIImage(systemName: name)
    }
}
