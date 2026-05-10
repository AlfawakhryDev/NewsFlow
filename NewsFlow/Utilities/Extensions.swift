import UIKit

// MARK: - UIImageView async image loading
extension UIImageView {
    private static var taskKey = 0
    private static var urlKey = 0

    private var currentTask: URLSessionDataTask? {
        get { objc_getAssociatedObject(self, &UIImageView.taskKey) as? URLSessionDataTask }
        set { objc_setAssociatedObject(self, &UIImageView.taskKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private var loadedURL: String? {
        get { objc_getAssociatedObject(self, &UIImageView.urlKey) as? String }
        set { objc_setAssociatedObject(self, &UIImageView.urlKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func loadImage(from urlString: String?, placeholder: UIImage? = UIImage(systemName: "photo")) {
        self.image = placeholder
        guard let urlString, let url = URL(string: urlString) else { return }
        if loadedURL == urlString { return }
        currentTask?.cancel()
        loadedURL = urlString

        if let cached = ImageCache.shared.image(for: urlString) {
            self.image = cached
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else { return }
            ImageCache.shared.store(image, for: urlString)
            DispatchQueue.main.async {
                guard self.loadedURL == urlString else { return }
                UIView.transition(with: self, duration: 0.2, options: .transitionCrossDissolve) {
                    self.image = image
                }
            }
        }
        currentTask = task
        task.resume()
    }
}

// MARK: - Simple in-memory image cache
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    func image(for key: String) -> UIImage? { cache.object(forKey: key as NSString) }
    func store(_ image: UIImage, for key: String) { cache.setObject(image, forKey: key as NSString) }
}

// MARK: - UIView shake / fade helpers
extension UIView {
    func fadeIn(duration: TimeInterval = Constants.UI.animationDuration) {
        alpha = 0
        UIView.animate(withDuration: duration) { self.alpha = 1 }
    }

    func shake() {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration = 0.5
        anim.values = [-12, 12, -10, 10, -6, 6, -4, 4, 0]
        layer.add(anim, forKey: "shake")
    }
}

// MARK: - Date formatting
extension String {
    var formattedPublishDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: self) else { return self }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - UIViewController helpers
extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
