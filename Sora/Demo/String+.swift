import SwiftUI
import Foundation

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    func isValidURL() async -> Bool {
        guard let url = URL(string: self) else {
            return false
        }
        
        guard url.scheme == "http" || url.scheme == "https" else {
            return false
        }
        
        guard url.host != nil else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return (200...399).contains(httpResponse.statusCode)
            }
            return false
        } catch {
            return false
        }
    }
}
