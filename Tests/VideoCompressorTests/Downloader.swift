//
//  Downloader.swift
//  
//
//  Created by kun on 2024/6/24.
//

import Foundation
@testable import VideoCompressor

class Video {
    internal init(remoteUrl: String) {
        self.urlString = remoteUrl
        self.remoteUrl = URL(string: remoteUrl)

        self.localURL = FileManager.tempDirectory(with: "UnitTestSampleVideo").appendingPathComponent("\(self.remoteUrl!.lastPathComponent)")
        self.compressedURL = nil
    }
    
    let urlString: String
    let remoteUrl: URL?
    var localURL: URL?
    var compressedURL: URL?
}

class Downloader {
    
    var tasks: [String: URLSessionDataTask] = [:]
    
    var videos: [Video] = []
    
    func clear() {
        tasks.values.forEach {
            $0.cancel()
        }
        videos.forEach {
            if let local = $0.localURL {
                try? FileManager.default.removeItem(at:local)
            }
            
            if let compressed = $0.compressedURL {
                try? FileManager.default.removeItem(at: compressed)
            }
        }
    }
    
    func setupSampleVideoPath(url: [String]) {
        for ulrItem in url {
            videos.append(Video(remoteUrl: ulrItem))
        }
    }
    
    func downloadSampleVideo(_ url: String, _ completion: @escaping ((Result<URL, Error>) -> Void)) {
        let video = videos.first(where: { $0.urlString == url })
        guard let sampleVideoCachedURL = video?.localURL else { return }
        if FileManager.default.fileExists(atPath: sampleVideoCachedURL.path) {
            completion(.success(sampleVideoCachedURL))
        } else {
            request(url) { result in
                switch result {
                case .success(let data):
                    do {
                        try (data as NSData).write(to: sampleVideoCachedURL, options: NSData.WritingOptions.atomic)
                        completion(.success(sampleVideoCachedURL))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    
    
    func request(_ url: String, completion: @escaping ((Result<Data, Error>) -> Void)) {
        tasks[url]?.cancel()
        print("Donwloading \(url)")
        let task = URLSession.shared.dataTask(with: URL(string: url)!) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                self.tasks[url] = nil
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.tasks[url] = nil
                return
            }

            if (200...299).contains(httpResponse.statusCode) {
                if let data = data {
                    DispatchQueue.main.async {
                        self.tasks[url] = nil
                        completion(.success(data))
                    }
                }
            } else {
                let domain = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                let error = NSError(domain: domain, code: httpResponse.statusCode, userInfo: nil)
                DispatchQueue.main.async {
                    self.tasks[url] = nil
                    completion(.failure(error))
                }
            }
        }
        task.resume()
        self.tasks[url] = task
    }
}
