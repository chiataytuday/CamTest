//
//  TemporaryFileURL.swift
//  Flaneur
//
//  Created by debavlad on 05.04.2020.
//  Copyright © 2020 debavlad. All rights reserved.
//

import Foundation

public final class TemporaryFileURL: ManagedURL {
    
    public let contentURL: URL
    
    public init(extension ext: String) {
        contentURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
		print("CREATED \(contentURL.lastPathComponent) FILE")
    }
    
    deinit {
        DispatchQueue.global(qos: .utility).async { [contentURL = self.contentURL] in
			do {
				try FileManager.default.removeItem(at: contentURL)
				print("REMOVED \(contentURL.lastPathComponent) FILE")
			} catch {
				print("File not found")
			}
//            try? FileManager.default.removeItem(at: contentURL)
//			print("REMOVED \(contentURL.lastPathComponent) FILE")
        }
    }
}

public protocol ManagedURL {
    var contentURL: URL { get }
    func keepAlive()
}

public extension ManagedURL {
    func keepAlive() { }
}

extension URL: ManagedURL {
    public var contentURL: URL { return self }
}
