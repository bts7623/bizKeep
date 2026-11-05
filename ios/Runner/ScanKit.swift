import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

/// 스캔 질감 처리 — 스캔뿅 앱과 공유하는 핵심 파이프라인 (순수 Core Image/Vision, UI 없음).
///   detectDocument : 문서/명함 영역 사각형 (세그멘테이션 → 사각 검출)
///   perspective    : 꼭짓점 4개로 원근 보정
///   enhance        : 조명 평탄화 → 종이 톤 → 샤픈. strength 0~1 로 원본과 섞음. mode: color | gray | bw
/// 검증: tools/scan_proto.swift (픽스처 명함 5장). CIDocumentEnhancer 는 잘라낸 이미지에서 동작하지 않는 경우가 있어 쓰지 않는다.
enum ScanKit {
  struct Quad {
    var topLeft: CGPoint, topRight: CGPoint, bottomRight: CGPoint, bottomLeft: CGPoint
  }

  /// 이미지 좌표(좌하단 원점)의 문서 사각형. minAspect/maxAspect 는 짧은변/긴변 비율 제한 (명함 0.45~0.75, 문서는 nil).
  static func detectDocument(_ ci: CIImage, minAspect: Float? = nil, maxAspect: Float? = nil) -> Quad? {
    let ext = ci.extent
    func scale(_ o: VNRectangleObservation) -> Quad {
      func p(_ pt: CGPoint) -> CGPoint { CGPoint(x: ext.origin.x + pt.x * ext.width, y: ext.origin.y + pt.y * ext.height) }
      return Quad(topLeft: p(o.topLeft), topRight: p(o.topRight), bottomRight: p(o.bottomRight), bottomLeft: p(o.bottomLeft))
    }
    func aspectOK(_ o: VNRectangleObservation) -> Bool {
      guard let lo = minAspect, let hi = maxAspect else { return true }
      let w = o.boundingBox.width * ext.width, h = o.boundingBox.height * ext.height
      let r = Float(min(w, h) / max(w, h))
      return r >= lo && r <= hi
    }
    let handler = VNImageRequestHandler(ciImage: ci, options: [:])
    if #available(iOS 15.0, *) {
      let seg = VNDetectDocumentSegmentationRequest()
      try? handler.perform([seg])
      if let o = seg.results?.first, o.confidence > 0.6, aspectOK(o) { return scale(o) }
    }
    let rect = VNDetectRectanglesRequest()
    rect.minimumSize = 0.15; rect.minimumConfidence = 0.5; rect.maximumObservations = 1
    if let lo = minAspect, let hi = maxAspect { rect.minimumAspectRatio = lo; rect.maximumAspectRatio = hi }
    try? handler.perform([rect])
    if let o = rect.results?.first { return scale(o) }
    return nil
  }

  static func perspective(_ ci: CIImage, _ q: Quad) -> CIImage {
    let f = CIFilter.perspectiveCorrection()
    f.inputImage = ci
    f.topLeft = q.topLeft; f.topRight = q.topRight; f.bottomRight = q.bottomRight; f.bottomLeft = q.bottomLeft
    return f.outputImage ?? ci
  }

  /// 조명 평탄화: 큰 블러로 종이 밝기를 추정해 원본을 나눈다 → 그림자·누런 끼 제거, 종이는 흰색.
  static func flatten(_ img: CIImage, radiusRatio: CGFloat = 0.04) -> CIImage {
    let r = max(8, img.extent.width * radiusRatio)
    let blur = CIFilter.gaussianBlur()
    blur.inputImage = img.clampedToExtent()
    blur.radius = Float(r)
    guard let bg = blur.outputImage?.cropped(to: img.extent) else { return img }
    // 검정 바탕 명함에서 나눗셈 폭주 방지용 바닥값
    let lifted = bg.applyingFilter("CIColorMatrix", parameters: ["inputBiasVector": CIVector(x: 0.08, y: 0.08, z: 0.08, w: 0)])
    let div = CIFilter.divideBlendMode()   // 실측: background / input
    div.inputImage = lifted
    div.backgroundImage = img
    return div.outputImage?.cropped(to: img.extent) ?? img
  }

  static func paperTone(_ img: CIImage) -> CIImage {
    let tc = CIFilter.toneCurve()
    tc.inputImage = img
    tc.point0 = CGPoint(x: 0, y: 0); tc.point1 = CGPoint(x: 0.25, y: 0.21); tc.point2 = CGPoint(x: 0.5, y: 0.52)
    tc.point3 = CGPoint(x: 0.75, y: 0.86); tc.point4 = CGPoint(x: 0.92, y: 1.0)
    let cc = CIFilter.colorControls()
    cc.inputImage = tc.outputImage
    cc.saturation = 1.05; cc.contrast = 1.05; cc.brightness = 0
    return cc.outputImage ?? img
  }

  static func sharpen(_ img: CIImage) -> CIImage {
    let f = CIFilter.unsharpMask(); f.inputImage = img; f.radius = 1.5; f.intensity = 0.4
    return f.outputImage ?? img
  }

  /// 스캔 질감. strength 1 = 완전 적용, 0 = 원본.
  static func enhance(_ img: CIImage, strength: Double = 1.0, mode: String = "color") -> CIImage {
    var out = sharpen(paperTone(flatten(img)))
    switch mode {
    case "gray":
      out = out.applyingFilter("CIPhotoEffectMono")
    case "bw":
      let t = CIFilter.colorThreshold(); t.inputImage = out.applyingFilter("CIPhotoEffectMono"); t.threshold = 0.55
      out = t.outputImage ?? out
    default: break
    }
    if strength < 0.999 {
      let mix = CIFilter.mix()
      mix.inputImage = out; mix.backgroundImage = img; mix.amount = Float(max(0, strength))
      out = mix.outputImage ?? out
    }
    return out.cropped(to: img.extent)
  }
}
