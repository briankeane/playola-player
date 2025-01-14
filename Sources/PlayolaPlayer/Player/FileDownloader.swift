//
//  FileDownloader.swift
//  PlayolaPlayer
//
//  Created by Brian D Keane on 12/30/24.
//

import Foundation
import SwiftUI

@Observable
public final class FileDownloader: NSObject, @unchecked Sendable {
  var remoteUrl: URL!
  var localUrl: URL!
  var handleProgressBlock: ((Float) -> Void)?
  var handleCompletionBlock: ((FileDownloader) -> Void)?

  // MARK: - Properties
  private var configuration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundTasks")
  private var session: URLSession!

  public init(remoteUrl: URL,
              localUrl: URL,
              onProgress: ((Float) -> Void)?,
              onCompletion: ((FileDownloader) -> Void)?) {
    super.init()
    self.remoteUrl = remoteUrl
    self.localUrl = localUrl
    self.handleProgressBlock = onProgress
    self.handleCompletionBlock = onCompletion
    self.session = URLSession(configuration: .default,
                              delegate: self,
                              delegateQueue: .main)
    let task = session.downloadTask(with: remoteUrl)
    task.resume()
  }
}

extension FileDownloader: URLSessionDownloadDelegate {
  public func urlSession(_ session: URLSession,
                         downloadTask: URLSessionDownloadTask,
                         didWriteData bytesWritten: Int64,
                         totalBytesWritten: Int64,
                         totalBytesExpectedToWrite: Int64) {
    let totalDownloaded = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
    handleProgressBlock?(totalDownloaded)
  }

  public func urlSession(_ session: URLSession,
                         downloadTask: URLSessionDownloadTask,
                         didFinishDownloadingTo location: URL) {
    let manager = FileManager()
    guard !manager.fileExists(atPath: localUrl.path) else {
      print("file exists already at \(localUrl.path)")
      handleProgressBlock?(1.0)
      handleCompletionBlock?(self)
      self.handleProgressBlock = nil
      self.handleCompletionBlock = nil
      return
    }

    do {
      try manager.moveItem(at: location, to: localUrl)
    } catch let error {
      print("error moving file")
      print(error)
    }
    handleCompletionBlock?(self)
    self.handleProgressBlock = nil
    self.handleCompletionBlock = nil
  }
}
