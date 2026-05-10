import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let headlines  = makeNav(root: HeadlinesViewController(),
                                  title: "Headlines", icon: "newspaper")
        let search     = makeNav(root: SearchViewController(),
                                  title: "Search",    icon: "magnifyingglass")
        let bookmarks  = makeNav(root: BookmarksViewController(),
                                  title: "Bookmarks", icon: "bookmark")

        viewControllers = [headlines, search, bookmarks]

        tabBar.tintColor = Constants.UI.primaryColor
        if #available(iOS 15, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            tabBar.standardAppearance  = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func makeNav(root: UIViewController, title: String, icon: String) -> UINavigationController {
        root.tabBarItem = UITabBarItem(title: title,
                                       image: UIImage(systemName: icon),
                                       selectedImage: UIImage(systemName: "\(icon).fill"))
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.tintColor = Constants.UI.primaryColor
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            nav.navigationBar.standardAppearance   = appearance
            nav.navigationBar.scrollEdgeAppearance = appearance
        }
        return nav
    }
}
