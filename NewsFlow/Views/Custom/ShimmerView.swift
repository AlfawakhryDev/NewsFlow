import UIKit

/// A shimmering placeholder used while content loads — demonstrates Core Animation layer manipulation.
final class ShimmerView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGray5
        layer.cornerRadius = 6
        clipsToBounds = true
        setupGradient()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor,
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    func startAnimating() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue   = [1.0,  1.5,  2.0]
        animation.duration  = 1.4
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(animation, forKey: "shimmer")
    }

    func stopAnimating() {
        gradientLayer.removeAnimation(forKey: "shimmer")
    }
}

// MARK: - A full-row shimmer placeholder cell
final class ShimmerCell: UITableViewCell {
    static let reuseID = "ShimmerCell"

    private let thumbnailShimmer = ShimmerView()
    private let titleShimmer1    = ShimmerView()
    private let titleShimmer2    = ShimmerView()
    private let subtitleShimmer  = ShimmerView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        [thumbnailShimmer, titleShimmer1, titleShimmer2, subtitleShimmer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            thumbnailShimmer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailShimmer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailShimmer.widthAnchor.constraint(equalToConstant: 80),
            thumbnailShimmer.heightAnchor.constraint(equalToConstant: 80),

            titleShimmer1.leadingAnchor.constraint(equalTo: thumbnailShimmer.trailingAnchor, constant: 12),
            titleShimmer1.topAnchor.constraint(equalTo: thumbnailShimmer.topAnchor, constant: 8),
            titleShimmer1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleShimmer1.heightAnchor.constraint(equalToConstant: 14),

            titleShimmer2.leadingAnchor.constraint(equalTo: titleShimmer1.leadingAnchor),
            titleShimmer2.topAnchor.constraint(equalTo: titleShimmer1.bottomAnchor, constant: 6),
            titleShimmer2.widthAnchor.constraint(equalTo: titleShimmer1.widthAnchor, multiplier: 0.7),
            titleShimmer2.heightAnchor.constraint(equalToConstant: 14),

            subtitleShimmer.leadingAnchor.constraint(equalTo: titleShimmer1.leadingAnchor),
            subtitleShimmer.topAnchor.constraint(equalTo: titleShimmer2.bottomAnchor, constant: 10),
            subtitleShimmer.widthAnchor.constraint(equalTo: titleShimmer1.widthAnchor, multiplier: 0.4),
            subtitleShimmer.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        [thumbnailShimmer, titleShimmer1, titleShimmer2, subtitleShimmer].forEach {
            newSuperview == nil ? $0.stopAnimating() : $0.startAnimating()
        }
    }
}
