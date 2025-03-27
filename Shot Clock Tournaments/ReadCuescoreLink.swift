import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    var onDataExtracted: (String?, String?) -> Void
    var onPageLoaded: (() -> Void)?

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url)) // Load the webpage once
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No need to reload the page here unless URL changes
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: WebView
    var isPageLoaded = false
    
    
    init(_ parent: WebView) {
        self.parent = parent
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isPageLoaded = false // Reset when a new page starts loading
        print("Page started loading")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        isPageLoaded = true
        
        if let onPageLoaded = parent.onPageLoaded {
                    onPageLoaded()
                }
        
        let script = """
                function extractData() {
                    if (typeof Scoreboard !== 'undefined' && Scoreboard.data) {
                        return {
                            tableId: Scoreboard.data.tableId,
                            code: Scoreboard.data.code
                        };
                    }
                    return { tableId: null, code: null };
                }
                extractData();
                """
        
        webView.evaluateJavaScript(script) { (result, error) in
            if let dict = result as? [String: Any] {
                let tableId = dict["tableId"] as? Int
                let code = dict["code"] as? String
                DispatchQueue.main.async {
                    self.parent.onDataExtracted(tableId?.description,code)
                }
            }
        }
        print("Page finished loading")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Handle any messages sent from JavaScript if needed
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Failed to load page: \(error.localizedDescription)")
        isPageLoaded = false
//        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Navigation failed: \(error.localizedDescription)")
        isPageLoaded = false
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            print("Web content process terminated")
            isPageLoaded = false
            DispatchQueue.main.async { // Reload gracefully after termination
                webView.reload()
            }
        }
}


class APIManager: ObservableObject {
    @Published var responseData: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    func sendAjaxRequest(tableId: String, code: String, completion: @escaping (Result<String, Error>) -> Void) {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "https://cuescore.com/ajax/scoreboard/") else {
            completion(.failure(URLError(.badURL)))
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/javascript, */*; q=0.01", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        let payload = "tableId=\(tableId)&code=\(code)&curVersion=0"
        request.httpBody = payload.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "NoDataError", code: 0, userInfo: nil)))
                    return
                }
                
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    let prettyPrintedData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                    
                    if let jsonString = String(data: prettyPrintedData, encoding: .utf8) {
                        completion(.success(jsonString))
                    } else {
                        completion(.failure(NSError(domain: "JSONStringConversionError", code: 0, userInfo: nil)))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

func extractMatchInfo(jsonString: String) -> (
    tournamentName: String?,
    playerALastName: String?,
    playerBLastName: String?,
    bestOfSets: Int?,
    frameScoreA: Int?,
    frameScoreB: Int?,
    setScoreA: Int?,
    setScoreB: Int?,
    raceTo: Int?
) {
    guard let data = jsonString.data(using: .utf8) else {
        print("Error: Could not convert string to data")
        return (nil, nil, nil, nil, nil, nil, nil, nil, nil)
    }
    
    do {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let match = json["match"] as? [String: Any] else {
            print("Error: Could not parse JSON or extract match")
            return (nil, nil, nil, nil, nil, nil, nil, nil, nil)
        }
        
        // Extract basic information
        let extractedTournamentName = json["tournamentName"] as? String ?? "Error, retry link"
        let extractedPlayerALastName = (match["playerA"] as? [String: Any])?["lastname"] as? String ?? "Error, retry link"
        let extractedPlayerBLastName = (match["playerB"] as? [String: Any])?["lastname"] as? String ?? "Error, retry link"
        let extractedBestOfSets = (match["bestOfSets"] as? Int) ?? 1
        let extractedRaceTo = match["raceTo"] as? Int ?? 0
        
        // Initialize score variables
        var extractedFrameScoreA: Int?
        var extractedFrameScoreB: Int?
        var extractedSetScoreA: Int?
        var extractedSetScoreB: Int?
        
        if extractedBestOfSets < 2 {
            // Extract scores from the last frame
            
            extractedFrameScoreA = match["scoreA"] as? Int
            extractedFrameScoreB = match["scoreB"] as? Int
            
            extractedSetScoreA = 0
            extractedSetScoreB = 0
            
        } else {
            // Extract scores from the last frame AND match-level scores
            
            print(extractedBestOfSets)
            
            if let sets = match["sets"] as? [[String: Any]],
               let frames = sets.last?["frames"] as? [[String: Any]],
               let lastFrame = frames.last {
                extractedFrameScoreA = lastFrame["scoreA"] as? Int
                extractedFrameScoreB = lastFrame["scoreB"] as? Int
            }
            
            // Match-level scores (set scores)
            extractedSetScoreA = match["scoreA"] as? Int
            extractedSetScoreB = match["scoreB"] as? Int
        }
        
        return (
            extractedTournamentName,
            extractedPlayerALastName,
            extractedPlayerBLastName,
            extractedBestOfSets,
            extractedFrameScoreA,
            extractedFrameScoreB,
            extractedSetScoreA,
            extractedSetScoreB,
            extractedRaceTo
        )
        
    } catch {
        print("JSON parsing error: \(error.localizedDescription)")
        return (nil, nil, nil, nil, nil, nil, nil, nil, nil)
    }
}
