import UIKit

final class ArticleTableViewCell: UITableViewCell {
    static let reuseID = "ArticleTableViewCell"

    // MARK: - Shadow wrapper (no clipsToBounds) + card (clipsToBounds)
    private let shadowWrapper: UIView = {
        let v = UIView()
        v.backgroundColor       = .clear
        v.layer.shadowColor     = UIColor.black.cgColor
        v.layer.shadowOpacity   = 0.08
        v.layer.shadowRadius    = 8
        v.layer.shadowOffset    = CGSize(width: 0, height: 2)
        v.layer.cornerRadius    = 14
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor   = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 14
        v.clipsToBounds      = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode      = .scaleAspectFill
        iv.backgroundColor  = .systemGray5
        iv.layer.cornerRadius = 10
        iv.clipsToBounds    = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font          = .systemFont(ofSize: 15, weight: .semibold)
        l.numberOfLines = 2
        l.textColor     = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let sourceLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = Constants.UI.primaryColor
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 11)
        l.textColor = .tertiaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bookmarkButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.tintColor = Constants.UI.primaryColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    var onBookmarkTap: (() -> Void)?
    private var isBookmarked = false

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle      = .none
        backgroundColor     = .clear
        contentView.backgroundColor = .clear
        buildLayout()
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    private func buildLayout() {
        contentView.addSubview(shadowWrapper)
        shadowWrapper.addSubview(cardView)

        [thumbnailImageView, titleLabel, sourceLabel, dateLabel, bookmarkButton]
            .forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            // shadowWrapper fills contentView with 6pt top/bottom, 16pt sides
            shadowWrapper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            shadowWrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            shadowWrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            shadowWrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // cardView fills shadowWrapper exactly
            cardView.topAnchor.constraint(equalTo: shadowWrapper.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: shadowWrapper.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: shadowWrapper.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: shadowWrapper.bottomAnchor),

            // Thumbnail: 80×80, 12pt from leading, vertically centred
            thumbnailImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            thumbnailImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),

            // Bookmark button: 28×28, 12pt from trailing, vertically centred
            bookmarkButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            bookmarkButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 28),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 28),

            // Title: from thumbnail trailing+12 to bookmark leading-8, top-aligned
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: bookmarkButton.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),

            // Source: below title
            sourceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            sourceLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            sourceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),

            // Date: below source
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 4),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -12),
        ])
    }

    // MARK: - Configure
    func configure(with article: Article, isBookmarked: Bool) {
        self.isBookmarked   = isBookmarked
        titleLabel.text     = article.title
        sourceLabel.text    = article.source.name
        dateLabel.text      = article.publishedAt.formattedPublishDate
        thumbnailImageView.loadImage(from: article.urlToImage)
        updateBookmarkIcon(animated: false)
    }

    // MARK: - Entry animation
    func animateIn(delay: TimeInterval = 0) {
        alpha     = 0
        transform = CGAffineTransform(translationX: 0, y: 16)
        UIView.animate(withDuration: 0.38, delay: delay,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4,
                       options: .curveEaseOut) {
            self.alpha     = 1
            self.transform = .identity
        }
    }

    // MARK: - Highlight
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.14) {
            self.shadowWrapper.transform = highlighted
                ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        }
    }

    // MARK: - Bookmark
    @objc private func bookmarkTapped() {
        isBookmarked.toggle()
        updateBookmarkIcon(animated: true)
        onBookmarkTap?()
    }

    private func updateBookmarkIcon(animated: Bool) {
        let img = UIImage(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
        guard animated else { bookmarkButton.setImage(img, for: .normal); return }
        UIView.transition(with: bookmarkButton, duration: 0.2, options: .transitionCrossDissolve) {
            self.bookmarkButton.setImage(img, for: .normal)
        }
        let bounce = CASpringAnimation(keyPath: "transform.scale")
        bounce.fromValue = 0.6; bounce.toValue = 1.0
        bounce.stiffness = 300; bounce.damping = 12; bounce.duration = 0.4
        bookmarkButton.imageView?.layer.add(bounce, forKey: nil)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        onBookmarkTap = nil
    }
}
