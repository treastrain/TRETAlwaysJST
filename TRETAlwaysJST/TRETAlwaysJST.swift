//
//  TRETAlwaysJST.swift
//  TRETAlwaysJST
//
//  Created by treastrain on 2018/11/03.
//  Copyright © 2018 treastrain / Tanaka Ryoga. All rights reserved.
//

import Foundation

public final class AlwaysJST {
    
    public final var difference: TimeInterval!
    
    public final func now() -> Date {
        return Date(timeIntervalSinceNow: difference)
    }
    
    public init() throws {
        let start = Date()
        
        do {
            var jstDate = try getJST(serverUrl: JSTServerURL.b1)
            let elapsed = Date().timeIntervalSince(start)
            jstDate = Date(timeInterval: elapsed, since: jstDate)
            self.difference = -Date().timeIntervalSince(jstDate)
        } catch {
            do {
                var jstDate = try getJST(serverUrl: JSTServerURL.a1)
                let elapsed = Date().timeIntervalSince(start)
                jstDate = Date(timeInterval: elapsed, since: jstDate)
                self.difference = -Date().timeIntervalSince(jstDate)
            } catch {
                throw error
            }
        }
    }
    
    private func getJST(serverUrl: URL) throws -> Date {
        let jstString = try String(contentsOf: serverUrl)
        
        if let jstDate = jstDate(from: jstString) {
            return jstDate
        } else {
            throw NSError()
        }
    }
    
    /// Gets the current Japan Standard Time asynchronously from NICT's server.
    ///
    /// - Parameters:
    ///   - completionHandler: The completion handler to call when the get JST is complete. This completion handler takes the following parameters:
    ///   - success: A Boolean value indicating whether the time was acquired from the NICT's server.
    ///   - date: A date value initialized to the current date and time by NICT's Japan Standard Time timestamp, or initialized to the current date and time **by the device if the request was unsuccessful**.
    ///   - error: An error object that indicates why the request failed, or nil if the request was successful.
    public final func getJST(completionHandler: @escaping (_ success: Bool, _ date: Date, _ error: Error?) -> Void) {
        func getJST(url: URL, completionHandler: @escaping (Bool, Date, Error?) -> Void) {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let data = data, let jstString = String(data: data, encoding: .utf8), let date = self.jstDate(from: jstString) {
                    completionHandler(true, date, nil)
                } else {
                    completionHandler(false, Date(), error)
                }
            }
            task.resume()
        }
        
        getJST(url: JSTServerURL.b1) { (success, date, error) in
            if error != nil {
                getJST(url: JSTServerURL.a1, completionHandler: { (success, date, error) in
                    completionHandler(success, date, error)
                })
            } else {
                completionHandler(success, date, nil)
            }
        }
    }
    
    private func jstDate(from jstString: String) -> Date? {
        let dateFormater = DateFormatter()
        dateFormater.locale = Locale(identifier: "en_US_POSIX")
        dateFormater.dateFormat = "E MMM dd HH:mm:ss yyyy' JST '"
        return dateFormater.date(from: jstString)
    }
}

private struct JSTServerURL {
    static let a1 = URL(string: "https://ntp-a1.nict.go.jp/cgi-bin/time")!
    static let b1 = URL(string: "https://ntp-b1.nict.go.jp/cgi-bin/time")!
}
