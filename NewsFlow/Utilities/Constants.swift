import UIKit

enum Constants {
    enum API {
        // Get your free key at https://newsapi.org/register
        static let newsAPIKey = "YOUR_NEWS_API_KEY_HERE"
        static let baseURL = "https://newsapi.org/v2"
    }

    enum Categories {
        static let all: [(title: String, value: String, icon: String)] = [
            ("General",       "general",       "newspaper"),
            ("Technology",    "technology",    "cpu"),
            ("Business",      "business",      "chart.line.uptrend.xyaxis"),
            ("Science",       "science",       "flask"),
            ("Health",        "health",        "heart.circle"),
            ("Sports",        "sports",        "sportscourt"),
            ("Entertainment", "entertainment", "film"),
        ]
    }

    enum UI {
        static let cornerRadius: CGFloat = 12
        static let cellHeight: CGFloat = 110
        static let categoryHeight: CGFloat = 36
        static let animationDuration: TimeInterval = 0.35
        static let primaryColor = UIColor.systemIndigo
    }
}
