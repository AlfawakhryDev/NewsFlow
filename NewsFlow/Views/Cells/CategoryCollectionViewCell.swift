import UIKit

final class CategoryCollectionViewCell: UICollectionViewCell {
    static let reuseID = "CategoryCollectionViewCell"

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 18
        layer.borderWidth = 1.5
        clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel])
        stack.spacing = 5
        stack.axis = .horizontal
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, icon: String) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: icon)
    }

    private func updateAppearance() {
        UIView.animate(withDuration: 0.2) {
            self.backgroundColor      = self.isSelected ? Constants.UI.primaryColor : .secondarySystemGroupedBackground
            self.layer.borderColor    = self.isSelected ? Constants.UI.primaryColor.cgColor : UIColor.separator.cgColor
            self.titleLabel.textColor = self.isSelected ? .white : .label
            self.iconImageView.tintColor = self.isSelected ? .white : Constants.UI.primaryColor
            self.transform = self.isSelected ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
        }
    }
}
