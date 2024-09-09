import Foundation

class GitHubUpdateChecker {
    let owner: String
    let repo: String
    
    init(owner: String, repo: String) {
        self.owner = owner
        self.repo = repo
    }
    
    func checkForUpdates(completion: @escaping (Bool, String?) -> Void) {
        let urlString = "https://api.github.com/repos/\(owner)/\(repo)/releases/latest"
        guard let url = URL(string: urlString) else {
            print("Debug: Invalid URL - \(urlString)")
            completion(false, nil)
            return
        }
        
        print("Debug: Checking for updates from URL - \(urlString)")
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Debug: Error checking for updates - \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            guard let data = data else {
                print("Debug: No data received from GitHub API")
                completion(false, nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
                    
                    print("Debug: Latest version from GitHub - \(latestVersion)")
                    print("Debug: Current local version - \(currentVersion)")
                    
                    let updateAvailable = self.isVersionNewer(latestVersion, thanCurrent: currentVersion)
                    
                    print("Debug: Update available - \(updateAvailable)")
                    
                    completion(updateAvailable, latestVersion)
                } else {
                    print("Debug: Failed to parse JSON or extract version information")
                    completion(false, nil)
                }
            } catch {
                print("Debug: JSON parsing error - \(error.localizedDescription)")
                completion(false, nil)
            }
        }.resume()
    }
    
    private func isVersionNewer(_ version: String, thanCurrent current: String) -> Bool {
        let vComponents = version.split(separator: ".").compactMap { Int($0) }
        let cComponents = current.split(separator: ".").compactMap { Int($0) }
        
        for (v, c) in zip(vComponents, cComponents) {
            if v > c {
                return true
            } else if v < c {
                return false
            }
        }
        
        return vComponents.count > cComponents.count
    }
}
