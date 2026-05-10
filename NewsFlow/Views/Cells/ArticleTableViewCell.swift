import UIKit

final class ArticleTableViewCell: UITableViewCell {
    static let reuseID = "ArticleTableViewCell"

    // MARK: - Subviews
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = Constants.UI.cornerRadius
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let sourceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = Constants.UI.primaryColor
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bookmarkButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.tintColor = Constants.UI.primaryColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - State
    var onBookmarkTap: (() -> Void)?
    private var isBookmarked = false

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    private func setupUI() {
        selectionStyle = .none
        let cardView = UIView()
        cardView.backgroundColor = .secondarySystemGroupedBackground
        cardView.layer.cornerRadius = Constants.UI.cornerRadius
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.06
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 6
        cardView.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, sourceLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(thumbnailImageView)
        cardView.addSubview(textStack)
        cardView.addSubview(bookmarkButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            thumbnailImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            thumbnailImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),

            textStack.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: bookmarkButton.leadingAnchor, constant: -4),
            textStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),

            bookmarkButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            bookmarkButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 28),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    // MARK: - Configure
    func configure(with article: Article, isBookmarked: Bool) {
        self.isBookmarked = isBookmarked
        titleLabel.text  = article.title
        sourceLabel.text = article.source.name
        dateLabel.text   = article.publishedAt.formattedPublishDate
        thumbnailImageView.loadImage(from: article.urlToImage)
        updateBookmarkIcon(animated: false)
    }

    // MARK: - Appear animation (Core Animation)
    func animateIn(delay: TimeInterval = 0) {
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.4, delay: delay, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    // MARK: - Highlight
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
            self.transform = highlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        }
    }

    // MARK: - Bookmark
    @objc private func bookmarkTapped() {
        isBookmarked.toggle()
        updateBookmarkIcon(animated: true)
        onBookmarkTap?()
    }

    private func updateBookmarkIcon(animated: Bool) {
        let name = isBookmarked ? "bookmark.fill" : "bookmark"
        let image = UIImage(systemName: name)
        if animated {
            UIView.transition(with: bookmarkButton, duration: 0.2, options: .transitionCrossDissolve) {
                self.bookmarkButton.setImage(image, for: .normal)
            }
            let bounce = CASpringAnimation(keyPath: "transform.scale")
            bounce.fromValue = 0.7
            bounce.toValue   = 1.0
            bounce.stiffness = 300
            bounce.damping   = 10
            bounce.duration  = 0.4
            bookmarkButton.layer.add(bounce, forKey: "bounce")
        } else {
            bookmarkButton.setImage(image, for: .normal)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = UIImage(systemName: "photo")
        thumbnailImageView.loadImage(from: nil)
        onBookmarkTap = nil
    }
}
