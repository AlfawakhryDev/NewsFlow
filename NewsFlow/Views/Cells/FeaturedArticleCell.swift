import UIKit

final class FeaturedArticleCell: UITableViewCell {
    static let reuseID  = "FeaturedArticleCell"
    static let rowHeight: CGFloat = 260

    // MARK: - Subviews
    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = Constants.UI.primaryColor.withAlphaComponent(0.3)
        return iv
    }()

    private let gradientView = GradientOverlayView()

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .heavy)
        l.textColor = .white
        l.textAlignment = .center
        l.layer.cornerRadius = 6
        l.layer.masksToBounds = true
        l.contentMode = .center
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.textColor = .white
        l.numberOfLines = 3
        l.layer.shadowColor = UIColor.black.cgColor
        l.layer.shadowOpacity = 0.5
        l.layer.shadowOffset = CGSize(width: 0, height: 1)
        l.layer.shadowRadius = 3
        return l
    }()

    private let sourceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = UIColor.white.withAlphaComponent(0.85)
        return l
    }()

    private let bookmarkButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.tintColor = .white
        return btn
    }()

    var onBookmarkTap: (() -> Void)?
    private var isBookmarked = false

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupUI()
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    private func setupUI() {
        let card = UIView()
        card.layer.cornerRadius = 18
        card.clipsToBounds = true
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.18
        card.layer.shadowRadius = 12
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.translatesAutoresizingMaskIntoConstraints = false

        [heroImageView, gradientView, badgeLabel, titleLabel, sourceLabel, bookmarkButton]
            .forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                card.addSubview($0)
            }

        contentView.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            heroImageView.edgesConstraints(to: card),
            gradientView.edgesConstraints(to: card),

            badgeLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            badgeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            badgeLabel.heightAnchor.constraint(equalToConstant: 22),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            bookmarkButton.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            bookmarkButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 32),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -50),
            titleLabel.bottomAnchor.constraint(equalTo: sourceLabel.topAnchor, constant: -6),

            sourceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            sourceLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])
    }

    // MARK: - Configure
    func configure(with article: Article, badge: String, badgeColor: UIColor, isBookmarked: Bool) {
        self.isBookmarked = isBookmarked
        titleLabel.text  = article.title
        sourceLabel.text = "✦  \(article.source.name)"
        badgeLabel.text  = "  \(badge)  "
        badgeLabel.backgroundColor = badgeColor
        heroImageView.loadImage(from: article.urlToImage,
                                 placeholder: UIImage(systemName: "newspaper.fill"))
        updateBookmarkIcon(animated: false)

        // Pulse the badge
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.85; pulse.toValue = 1.0
        pulse.stiffness = 200; pulse.damping = 10; pulse.duration = 0.5
        badgeLabel.layer.add(pulse, forKey: nil)
    }

    // MARK: - Highlight
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.15) {
            self.contentView.alpha     = highlighted ? 0.85 : 1
            self.contentView.transform = highlighted
                ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
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
        if animated {
            UIView.transition(with: bookmarkButton, duration: 0.2, options: .transitionCrossDissolve) {
                self.bookmarkButton.setImage(img, for: .normal)
            }
            let bounce = CASpringAnimation(keyPath: "transform.scale")
            bounce.fromValue = 0.6; bounce.toValue = 1.0
            bounce.stiffness = 300; bounce.damping = 10; bounce.duration = 0.4
            bookmarkButton.imageView?.layer.add(bounce, forKey: nil)
        } else {
            bookmarkButton.setImage(img, for: .normal)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        heroImageView.image = nil
        onBookmarkTap = nil
    }
}

// MARK: - Gradient overlay (Core Animation CAGradientLayer)
private final class GradientOverlayView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.25).cgColor,
            UIColor.black.withAlphaComponent(0.75).cgColor,
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - UIView edges helper
private extension UIView {
    func edgesConstraints(to view: UIView) -> NSLayoutConstraint {
        // Returns a dummy constraint; activates all four edges internally
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        return heightAnchor.constraint(equalToConstant: 0) // dummy, not activated
    }
}
