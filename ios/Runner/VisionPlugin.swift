import Flutter
import UIKit
import Vision
import CoreImage

/// iOS 온디바이스 비전: 명함 사각형 검출(자동 촬영용), 원근 보정 크롭, 텍스트 인식(한/영).
/// Google ML Kit 대신 Apple Vision 사용 — 추가 pod 없음, 시뮬레이터 arm64 지원.
final class VisionPlugin {
  static let channelName = "bizkeep/vision"
  private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
  private let queue = DispatchQueue(label: "bizkeep.vision", qos: .userInitiated)

  static func register(with messenger: FlutterBinaryMessenger) {
    let plugin = VisionPlugin()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in plugin.handle(call, result: result) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "args", message: "arguments required", details: nil)); return
    }
    switch call.method {
    case "detectRect":
      guard let data = args["bytes"] as? FlutterStandardTypedData,
            let w = args["width"] as? Int, let h = args["height"] as? Int,
            let bpr = args["bytesPerRow"] as? Int else { result(nil); return }
      queue.async {
        let r = self.detectRect(bytes: data.data, width: w, height: h, bytesPerRow: bpr)
        DispatchQueue.main.async { result(r) }
      }
    case "cropCard":
      guard let path = args["path"] as? String else { result(nil); return }
      let quad = args["quad"] as? [Double]
      queue.async {
        let out = self.cropCard(path: path, quad: quad)
        DispatchQueue.main.async { result(out) }
      }
    case "recognizeText":
      guard let path = args["path"] as? String else { result(""); return }
      queue.async {
        let text = self.recognizeText(path: path)
        DispatchQueue.main.async { result(text) }
      }
    case "recognizeLines":
      guard let path = args["path"] as? String else { result([]); return }
      queue.async {
        let lines = self.recognizeLines(path: path)
        DispatchQueue.main.async { result(lines) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - 사각형 검출 (BGRA 프레임)
  /// 반환: [x0,y0, x1,y1, x2,y2, x3,y3, confidence] — Vision 정규화 좌표(좌하단 원점). 없으면 nil.
  private func detectRect(bytes: Data, width: Int, height: Int, bytesPerRow: Int) -> [Double]? {
    var pb: CVPixelBuffer?
    let attrs: [CFString: Any] = [kCVPixelBufferIOSurfacePropertiesKey: [:]]
    guard CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pb) == kCVReturnSuccess, let buf = pb else { return nil }
    CVPixelBufferLockBaseAddress(buf, [])
    defer { CVPixelBufferUnlockBaseAddress(buf, []) }
    guard let base = CVPixelBufferGetBaseAddress(buf) else { return nil }
    let dstBpr = CVPixelBufferGetBytesPerRow(buf)
    bytes.withUnsafeBytes { src in
      guard let s = src.baseAddress else { return }
      if dstBpr == bytesPerRow {
        memcpy(base, s, min(bytes.count, dstBpr * height))
      } else {
        for y in 0..<height { memcpy(base + y * dstBpr, s + y * bytesPerRow, min(bytesPerRow, dstBpr)) }
      }
    }
    let req = VNDetectRectanglesRequest()
    req.minimumAspectRatio = 0.45   // 명함 5:9 ≈ 0.56
    req.maximumAspectRatio = 0.75
    req.minimumSize = 0.25
    req.minimumConfidence = 0.6
    req.maximumObservations = 1
    req.quadratureTolerance = 20
    // 센서는 가로(landscape right). 세로로 든 기기 기준 .right
    let handler = VNImageRequestHandler(cvPixelBuffer: buf, orientation: .right, options: [:])
    do { try handler.perform([req]) } catch { return nil }
    guard let o = req.results?.first else { return nil }
    return [o.topLeft.x, o.topLeft.y, o.topRight.x, o.topRight.y, o.bottomRight.x, o.bottomRight.y, o.bottomLeft.x, o.bottomLeft.y, Double(o.confidence)]
  }

  // MARK: - 원근 보정 크롭 → 같은 경로에 덮어쓰기 (JPEG, 긴 변 1280)
  private func cropCard(path: String, quad: [Double]?) -> String? {
    guard let ui = UIImage(contentsOfFile: path), let cg = ui.cgImage else { return nil }
    var ci = CIImage(cgImage: cg).oriented(forExifOrientation: Int32(ui.imageOrientation.exifValue))
    let ext = ci.extent
    if let q = quad, q.count >= 8 {
      // 촬영 사진에서 다시 검출 (프레임과 사진 좌표계 차이 방지)
      if let o = detectOnImage(ci) {
        ci = perspective(ci, o, ext)
      } else {
        let pts = stride(from: 0, to: 8, by: 2).map { CGPoint(x: q[$0] * ext.width, y: q[$0 + 1] * ext.height) }
        ci = ci.applyingFilter("CIPerspectiveCorrection", parameters: [
          "inputTopLeft": CIVector(cgPoint: pts[0]), "inputTopRight": CIVector(cgPoint: pts[1]),
          "inputBottomRight": CIVector(cgPoint: pts[2]), "inputBottomLeft": CIVector(cgPoint: pts[3])])
      }
    } else if let o = detectOnImage(ci) {
      ci = perspective(ci, o, ext)
    }
    // 리사이즈
    let longest = max(ci.extent.width, ci.extent.height)
    if longest > 1280 {
      let s = 1280 / longest
      ci = ci.transformed(by: CGAffineTransform(scaleX: s, y: s))
    }
    guard let out = ciContext.createCGImage(ci, from: ci.extent) else { return nil }
    guard let data = UIImage(cgImage: out).jpegData(compressionQuality: 0.85) else { return nil }
    do { try data.write(to: URL(fileURLWithPath: path), options: .atomic) } catch { return nil }
    return path
  }

  private func detectOnImage(_ ci: CIImage) -> VNRectangleObservation? {
    let req = VNDetectRectanglesRequest()
    req.minimumAspectRatio = 0.45; req.maximumAspectRatio = 0.75
    req.minimumSize = 0.3; req.minimumConfidence = 0.6; req.maximumObservations = 1
    let h = VNImageRequestHandler(ciImage: ci, options: [:])
    try? h.perform([req])
    return req.results?.first
  }

  private func perspective(_ ci: CIImage, _ o: VNRectangleObservation, _ ext: CGRect) -> CIImage {
    func p(_ pt: CGPoint) -> CIVector { CIVector(x: pt.x * ext.width, y: pt.y * ext.height) }
    return ci.applyingFilter("CIPerspectiveCorrection", parameters: [
      "inputTopLeft": p(o.topLeft), "inputTopRight": p(o.topRight),
      "inputBottomRight": p(o.bottomRight), "inputBottomLeft": p(o.bottomLeft)])
  }

  // MARK: - 텍스트 인식 (한국어·영어, 정확도 우선)
  private func observations(path: String) -> [VNRecognizedTextObservation] {
    guard let ui = UIImage(contentsOfFile: path), let cg = ui.cgImage else { return [] }
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = .accurate
    req.usesLanguageCorrection = false
    req.recognitionLanguages = ["ko-KR", "en-US"]
    let handler = VNImageRequestHandler(cgImage: cg, orientation: CGImagePropertyOrientation(ui.imageOrientation), options: [:])
    do { try handler.perform([req]) } catch { return [] }
    return req.results ?? []
  }

  /// 줄별 [text, x, y, w, h] — 좌상단 원점 정규화 좌표. 행 합치기·글자 크기 판단은 Dart(OcrParser)에서.
  private func recognizeLines(path: String) -> [[Any]] {
    return observations(path: path).compactMap { o in
      guard let c = o.topCandidates(1).first else { return nil }
      let b = o.boundingBox
      return [c.string, Double(b.minX), Double(1 - b.maxY), Double(b.width), Double(b.height)]
    }
  }

  private func recognizeText(path: String) -> String {
    let obs = observations(path: path)
    if obs.isEmpty { return "" }
    // 위→아래, 왼→오른쪽 순으로 줄 정렬 (Vision 좌표는 좌하단 원점)
    let sorted = obs.sorted { a, b in
      let ay = a.boundingBox.midY, by = b.boundingBox.midY
      if abs(ay - by) > 0.015 { return ay > by }
      return a.boundingBox.minX < b.boundingBox.minX
    }
    return sorted.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
  }
}

private extension UIImage.Orientation {
  var exifValue: Int {
    switch self {
    case .up: return 1; case .upMirrored: return 2; case .down: return 3; case .downMirrored: return 4
    case .leftMirrored: return 5; case .right: return 6; case .rightMirrored: return 7; case .left: return 8
    @unknown default: return 1
    }
  }
}

private extension CGImagePropertyOrientation {
  init(_ o: UIImage.Orientation) {
    switch o {
    case .up: self = .up; case .upMirrored: self = .upMirrored; case .down: self = .down; case .downMirrored: self = .downMirrored
    case .left: self = .left; case .leftMirrored: self = .leftMirrored; case .right: self = .right; case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
