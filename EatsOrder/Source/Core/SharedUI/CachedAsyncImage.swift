//
//  CachedAsyncImage.swift
//  EatsOrder
//
//  Created by 한수빈 on 5/22/25.
//

import SwiftUI

// MARK: - Actor-based Image Cache Manager with Headers with ETag support
actor ImageCacheManager {
  static let shared = ImageCacheManager()
  
  private let memoryCache = NSCache<NSString, CacheEntry>()
  private let fileManager = FileManager.default
  private let cacheDirectory: URL
  private let metadataDirectory: URL
  private var downloadTasks: [String: Task<UIImage, Error>] = [:]
  
  private init() {
    // 디스크 캐시 디렉토리 설정
    let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
    cacheDirectory = paths[0].appendingPathComponent("ImageCache")
    metadataDirectory = paths[0].appendingPathComponent("ImageCacheMetadata")
    
    // 캐시 디렉토리 생성
    try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    try? fileManager.createDirectory(at: metadataDirectory, withIntermediateDirectories: true)
    
    // 메모리 캐시 설정
    memoryCache.countLimit = 100 // 최대 100개 이미지
    memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    
    // 메모리 경고 시 캐시 정리
    Task { @MainActor in
      NotificationCenter.default.addObserver(
        forName: UIApplication.didReceiveMemoryWarningNotification,
        object: nil,
        queue: .main
      ) { _ in
        Task {
          await self.clearMemoryCache()
        }
      }
    }
  }
  
  // 이미지 로드 (메모리 -> 디스크 -> 네트워크 순서)
  func loadImage(from urlString: String) async throws -> UIImage {
    let cacheKey = urlString.safeFilename
    
    // 1. 메모리 캐시 확인
    if let cachedEntry = memoryCache.object(forKey: NSString(string: cacheKey)) {
      // 캐시된 항목이 너무 오래되었는지 확인 (예: 1일)
      if Date().timeIntervalSince(cachedEntry.cachedDate) < 24 * 60 * 60 {
        return cachedEntry.image
      } else {
        // 오래된 캐시는 조건부 요청으로 검증
        memoryCache.removeObject(forKey: NSString(string: cacheKey))
      }
    }
    
    // 2. 진행 중인 다운로드 확인
    if let existingTask = downloadTasks[cacheKey] {
      return try await existingTask.value
    }
    
    // 3. 새로운 다운로드 태스크 생성
    let downloadTask = Task<UIImage, Error> {
      // 디스크 캐시 확인 및 조건부 요청
      let diskEntry = try await loadFromDisk(cacheKey: cacheKey)
      
      if let entry = diskEntry {
        // 조건부 요청으로 서버에서 검증
        if let validatedImage = try await validateWithServer(
          urlString: urlString,
          etag: entry.etag,
          lastModified: entry.lastModified,
          currentImage: entry.image
        ) {
          storeInMemory(entry: CacheEntry(
            image: validatedImage,
            etag: entry.etag,
            lastModified: entry.lastModified
          ), key: cacheKey)
          return validatedImage
        }
      }
      
      // 네트워크에서 다운로드
      let (networkImage, etag, lastModified) = try await downloadFromNetwork(urlString: urlString)
      let newEntry = CacheEntry(image: networkImage, etag: etag, lastModified: lastModified)
      storeEntry(newEntry, key: cacheKey)
      return networkImage
    }
    
    downloadTasks[cacheKey] = downloadTask
    
    do {
      let image = try await downloadTask.value
      downloadTasks.removeValue(forKey: cacheKey)
      return image
    } catch {
      downloadTasks.removeValue(forKey: cacheKey)
      throw error
    }
  }
  
  // 메모리에 캐시 엔트리 저장
  private func storeInMemory(entry: CacheEntry, key: String) {
    let cost = Int(entry.image.size.width * entry.image.size.height * 4)
    memoryCache.setObject(entry, forKey: NSString(string: key), cost: cost)
  }
  
  // 캐시 엔트리 저장 (메모리 + 디스크)
  private func storeEntry(_ entry: CacheEntry, key: String) {
    // 메모리에 저장
    storeInMemory(entry: entry, key: key)
    
    // 디스크에 저장
    Task.detached(priority: .utility) {
      await self.saveToDisk(entry, key: key)
    }
  }
  
  // 디스크에서 캐시 엔트리 로드
  private func loadFromDisk(cacheKey: String) async throws -> CacheEntry? {
    let imageURL = cacheDirectory.appendingPathComponent(cacheKey)
    let metadataURL = metadataDirectory.appendingPathComponent(cacheKey + ".json")
    
    return try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .utility).async {
        do {
          // 이미지 파일 확인
          guard self.fileManager.fileExists(atPath: imageURL.path) else {
            continuation.resume(returning: nil)
            return
          }
          
          // 이미지 로드
          let imageData = try Data(contentsOf: imageURL)
          guard let image = UIImage(data: imageData) else {
            continuation.resume(returning: nil)
            return
          }
          
          // 메타데이터 로드
          var etag: String?
          var lastModified: String?
          
          if self.fileManager.fileExists(atPath: metadataURL.path) {
            let metadataData = try Data(contentsOf: metadataURL)
            if let metadata = try? JSONSerialization.jsonObject(with: metadataData) as? [String: String] {
              etag = metadata["etag"]
              lastModified = metadata["lastModified"]
            }
          }
          
          let entry = CacheEntry(image: image, etag: etag, lastModified: lastModified)
          continuation.resume(returning: entry)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  // 디스크에 캐시 엔트리 저장
  private func saveToDisk(_ entry: CacheEntry, key: String) {
    let imageURL = cacheDirectory.appendingPathComponent(key)
    let metadataURL = metadataDirectory.appendingPathComponent(key + ".json")
    
    // 이미지 저장
    guard let imageData = entry.image.jpegData(compressionQuality: 0.8) else { return }
    try? imageData.write(to: imageURL)
    
    // 메타데이터 저장
    var metadata: [String: String] = [:]
    if let etag = entry.etag {
      metadata["etag"] = etag
    }
    if let lastModified = entry.lastModified {
      metadata["lastModified"] = lastModified
    }
    
    if !metadata.isEmpty,
       let metadataData = try? JSONSerialization.data(withJSONObject: metadata) {
      try? metadataData.write(to: metadataURL)
    }
  }
  
  // 서버와 조건부 요청으로 검증 (헤더 포함)
  private func validateWithServer(
    urlString: String,
    etag: String?,
    lastModified: String?,
    currentImage: UIImage
  ) async throws -> UIImage? {
    guard let url = URL(string: Environments.baseURLV1 + urlString) else {
      throw URLError(.badURL)
    }
    
    var request = URLRequest(url: url)
    
    // 인증 헤더 추가
    request.addValue(TokenManager().accessToken, forHTTPHeaderField: "Authorization")
    request.addValue(Environments.apiKey, forHTTPHeaderField: "SeSACKey")
    
    // 조건부 헤더 설정
    if let etag = etag {
      request.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }
    if let lastModified = lastModified {
      request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
    }
    
    // 기본 헤더 설정
    request.addValue("image/*", forHTTPHeaderField: "Accept")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }
    
    // 304 Not Modified - 캐시된 이미지가 여전히 유효
    if httpResponse.statusCode == 304 {
      return currentImage
    }
    
    // 200 OK - 새로운 이미지 데이터
    if httpResponse.statusCode == 200 {
      guard let newImage = UIImage(data: data) else {
        throw URLError(.cannotDecodeContentData)
      }
      return newImage
    }
    
    throw URLError(.badServerResponse)
  }
  
  // 네트워크에서 이미지 다운로드 (헤더 포함)
  private func downloadFromNetwork(urlString: String) async throws -> (UIImage, String?, String?) {
    guard let url = URL(string: Environments.baseURLV1 + urlString) else {
      throw URLError(.badURL)
    }
    
    // URLRequest 생성 및 헤더 설정
    var request = URLRequest(url: url)
    
    // 필요한 헤더 추가
    request.addValue(TokenManager().accessToken, forHTTPHeaderField: "Authorization")
    request.addValue(Environments.apiKey, forHTTPHeaderField: "SeSACKey")
    
    // 기본 헤더 설정
    request.addValue("image/*", forHTTPHeaderField: "Accept")
    request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
      throw URLError(.badServerResponse)
    }
    
    guard let image = UIImage(data: data) else {
      throw URLError(.cannotDecodeContentData)
    }
    
    // ETag와 Last-Modified 헤더 추출
    let etag = httpResponse.value(forHTTPHeaderField: "ETag")
    let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified")
    
    return (image, etag, lastModified)
  }
  
  // 다운로드 취소
  func cancelDownload(for urlString: String) {
    let cacheKey = urlString.safeFilename
    downloadTasks[cacheKey]?.cancel()
    downloadTasks.removeValue(forKey: cacheKey)
  }
  
  // 메모리 캐시 정리
  func clearMemoryCache() {
    memoryCache.removeAllObjects()
  }
  
  // 전체 캐시 정리
  func clearAllCache() {
    memoryCache.removeAllObjects()
    downloadTasks.values.forEach { $0.cancel() }
    downloadTasks.removeAll()
    
    Task.detached(priority: .utility) {
      try? FileManager.default.removeItem(at: self.cacheDirectory)
      try? FileManager.default.removeItem(at: self.metadataDirectory)
      try? FileManager.default.createDirectory(
        at: self.cacheDirectory,
        withIntermediateDirectories: true
      )
      try? FileManager.default.createDirectory(
        at: self.metadataDirectory,
        withIntermediateDirectories: true
      )
    }
  }
  
  // 캐시 크기 계산
  func getCacheSize() async -> String {
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .utility).async {
        do {
          // 이미지 캐시 크기
          let imageUrls = try self.fileManager.contentsOfDirectory(
            at: self.cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
          )
          
          let imageSize = imageUrls.compactMap { url in
            try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
          }.reduce(0, +)
          
          // 메타데이터 캐시 크기
          let metadataUrls = try self.fileManager.contentsOfDirectory(
            at: self.metadataDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
          )
          
          let metadataSize = metadataUrls.compactMap { url in
            try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
          }.reduce(0, +)
          
          let totalSize = imageSize + metadataSize
          let sizeString = ByteCountFormatter.string(
            fromByteCount: Int64(totalSize),
            countStyle: .file
          )
          
          continuation.resume(returning: sizeString)
        } catch {
          continuation.resume(returning: "0 bytes")
        }
      }
    }
  }
  
  // 활성 다운로드 수 확인
  func getActiveDownloadsCount() -> Int {
    return downloadTasks.count
  }
}

// MARK: - Cache Entry Model (클래스로 변경)
class CacheEntry {
  let image: UIImage
  let etag: String?
  let lastModified: String?
  let cachedDate: Date
  
  init(image: UIImage, etag: String? = nil, lastModified: String? = nil) {
    self.image = image
    self.etag = etag
    self.lastModified = lastModified
    self.cachedDate = Date()
  }
}

// MARK: - URL Extension for safe filename
extension String {
  var safeFilename: String {
    return self
      .addingPercentEncoding(withAllowedCharacters: .alphanumerics)?
      .replacingOccurrences(of: "%", with: "_") ??
    String(self.hashValue)
  }
}

// MARK: - Image Loading State
enum ImageLoadingState {
  case idle
  case loading
  case success(UIImage)
  case failure(Error)
}

// MARK: - ObservableObject-based Image Loader (iOS 16 호환)
@MainActor
final class ImageLoader: ObservableObject {
  @Published private(set) var state: ImageLoadingState = .idle
  private var currentTask: Task<Void, Never>?
  
  var image: UIImage? {
    if case .success(let image) = state {
      return image
    }
    return nil
  }
  
  var isLoading: Bool {
    if case .loading = state {
      return true
    }
    return false
  }
  
  var error: Error? {
    if case .failure(let error) = state {
      return error
    }
    return nil
  }
  
  func loadImage(from urlString: String) {
    // 현재 작업 취소
    currentTask?.cancel()
    
    // 빈 URL 체크
    guard !urlString.isEmpty else {
      state = .failure(URLError(.badURL))
      return
    }
    
    // 이미 같은 이미지가 로드된 경우
    if case .success(_) = state, currentTask == nil {
      return
    }
    
    state = .loading
    
    currentTask = Task {
      do {
        let image = try await ImageCacheManager.shared.loadImage(from: urlString)
        
        if !Task.isCancelled {
          await MainActor.run {
            self.state = .success(image)
          }
        }
      } catch {
        if !Task.isCancelled {
          await MainActor.run {
            self.state = .failure(error)
          }
        }
      }
    }
  }
  
  func cancel() {
    currentTask?.cancel()
    currentTask = nil
    
    if case .loading = state {
      state = .idle
    }
  }
  
  deinit {
    // deinit은 synchronous이므로 Task를 직접 취소
    currentTask?.cancel()
  }
}

// MARK: - CachedAsyncImage with iOS 16 compatibility
public struct CachedAsyncImage<Content: View, Placeholder: View, ErrorView: View>: View {
  private let url: String
  private let content: (Image) -> Content
  private let placeholder: () -> Placeholder
  private let errorView: (Error) -> ErrorView
  
  @StateObject private var loader = ImageLoader()
  
  init(
    url: String,
    @ViewBuilder content: @escaping (Image) -> Content,
    @ViewBuilder placeholder: @escaping () -> Placeholder,
    @ViewBuilder errorView: @escaping (Error) -> ErrorView
  ) {
    self.url = url
    self.content = content
    self.placeholder = placeholder
    self.errorView = errorView
  }
  
  public var body: some View {
    Group {
      switch loader.state {
      case .idle, .loading:
        placeholder()
      case .success(let uiImage):
        content(Image(uiImage: uiImage))
      case .failure(let error):
        errorView(error)
      }
    }
    .onAppear {
      loader.loadImage(from: url)
    }
    .onChange(of: url) { newUrl in
      loader.loadImage(from: newUrl)
    }
    .onDisappear {
      loader.cancel()
    }
  }
}

// MARK: - Convenience Initializers
extension CachedAsyncImage where ErrorView == AnyView {
  init(
    url: String,
    @ViewBuilder content: @escaping (Image) -> Content,
    @ViewBuilder placeholder: @escaping () -> Placeholder
  ) {
    self.init(
      url: url,
      content: content,
      placeholder: placeholder
    ) { error in
      AnyView(
        VStack {
          Image(systemName: "exclamationmark.triangle")
            .foregroundColor(.gray)
          Text("로드 실패")
            .font(.caption)
            .foregroundColor(.gray)
        }
      )
    }
  }
}

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView>, ErrorView == AnyView {
  init(
    url: String,
    @ViewBuilder content: @escaping (Image) -> Content
  ) {
    self.init(
      url: url,
      content: content
    ) {
      ProgressView()
    }
  }
}

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView>, ErrorView == AnyView {
  init(url: String) {
    self.init(url: url) { image in
      image
    }
  }
}
