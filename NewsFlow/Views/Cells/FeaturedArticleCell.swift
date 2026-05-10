import UIKit

final class FeaturedArticleCell: UITableViewCell {
    static let reuseID   = "FeaturedArticleCell"
    static let rowHeight: CGFloat = 252

    // MARK: - Shadow wrapper (no clipsToBounds) + inner card (clipsToBounds)
    private let shadowWrapper: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.16
        v.layer.shadowRadius  = 14
        v.layer.shadowOffset  = CGSize(width: 0, height: 4)
        v.layer.cornerRadius  = 18
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let cardView: UIView = {
        let v = UIView()
        v.layer.cornerRadius  = 18
        v.clipsToBounds       = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = UIColor(red: 0.28, green: 0.25, blue: 0.75, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Gradient overlay using CAGradientLayer
    private let gradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.15).cgColor,
            UIColor.black.withAlphaComponent(0.72).cgColor,
        ]
        g.locations = [0, 0.45, 1]
        return g
    }()

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font            = .systemFont(ofSize: 11, weight: .heavy)
        l.textColor       = .white
        l.textAlignment   = .center
        l.layer.cornerRadius   = 6
        l.layer.masksToBounds  = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font         = .systemFont(ofSize: 19, weight: .bold)
        l.textColor    = .white
        l.numberOfLines = 3
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let sourceLabel: UILabel = {
        let l = UILabel()
        l.font      = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = UIColor.white.withAlphaComponent(0.80)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let bookmarkButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.tintColor  = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    var onBookmarkTap: (() -> Void)?
    private var isBookmarked = false

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle  = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        buildLayout()
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    private func buildLayout() {
        // Tree: contentView → shadowWrapper → cardView → hero/gradient/labels
        contentView.addSubview(shadowWrapper)
        shadowWrapper.addSubview(cardView)
        cardView.addSubview(heroImageView)
        cardView.layer.addSublayer(gradientLayer)

        [badgeLabel, titleLabel, sourceLabel, bookmarkButton].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            shadowWrapper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            shadowWrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            shadowWrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            shadowWrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            cardView.topAnchor.constraint(equalTo: shadowWrapper.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: shadowWrapper.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: shadowWrapper.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: shadowWrapper.bottomAnchor),

            heroImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            heroImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            heroImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            heroImageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            badgeLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            badgeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            badgeLabel.heightAnchor.constraint(equalToConstant: 24),

            bookmarkButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            bookmarkButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 36),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 36),

            sourceLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            sourceLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            sourceLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),

            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -52),
            titleLabel.bottomAnchor.constraint(equalTo: sourceLabel.topAnchor, constant: -8),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = cardView.bounds
    }

    // MARK: - Configure
    func configure(with article: Article, badge: String, badgeColor: UIColor, isBookmarked: Bool) {
        self.isBookmarked   = isBookmarked
        titleLabel.text     = article.title
        sourceLabel.text    = article.source.name
        badgeLabel.text     = "  \(badge)  "
        badgeLabel.backgroundColor = badgeColor

        heroImageView.loadImage(from: article.urlToImage,
                                 placeholder: UIImage(systemName: "newspaper.fill")?
                                    .withTintColor(.white.withAlphaComponent(0.3),
                                                   renderingMode: .alwaysOriginal))
        updateBookmarkIcon(animated: false)

        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.8; pulse.toValue = 1.0
        pulse.stiffness = 220; pulse.damping = 10; pulse.duration = 0.45
        badgeLabel.layer.add(pulse, forKey: nil)
    }

    // MARK: - Press feedback
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
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
        let name  = isBookmarked ? "bookmark.fill" : "bookmark"
        let image = UIImage(systemName: name)
        guard animated else { bookmarkButton.setImage(image, for: .normal); return }
        UIView.transition(with: bookmarkButton, duration: 0.2, options: .transitionCrossDissolve) {
            self.bookmarkButton.setImage(image, for: .normal)
        }
        let bounce = CASpringAnimation(keyPath: "transform.scale")
        bounce.fromValue = 0.6; bounce.toValue = 1.0
        bounce.stiffness = 320; bounce.damping = 12; bounce.duration = 0.4
        bookmarkButton.imageView?.layer.add(bounce, forKey: nil)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        heroImageView.image = nil
        onBookmarkTap = nil
    }
}
