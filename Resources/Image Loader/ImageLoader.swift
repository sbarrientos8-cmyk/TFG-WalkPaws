//
//  ImageLoader.swift
//  WalkPaws
//
//  Created by Sofia Barrientos Raszkowska on 19/2/26.
//

import UIKit
import SDWebImage

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private init() {}

    func load(_ url: URL, completion: @escaping (UIImage?) -> Void) {
        let key = url.absoluteString as NSString

        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            self.cache.setObject(image, forKey: key)
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
}

func configureSDWebImageForSupabase() {

    let key = "sb_publishable_3UHnHjCDgviDJP2GfsrRHg_SxIlrW_A"

    SDWebImageDownloader.shared.requestModifier = SDWebImageDownloaderRequestModifier { request in
        var r = request
        r.setValue(key, forHTTPHeaderField: "apikey")
        r.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        r.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
        return r
    }
}
