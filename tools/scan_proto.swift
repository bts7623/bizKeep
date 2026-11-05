// 스캔 질감 파이프라인 프로토타입 (macOS에서 실행)
//   swift tools/scan_proto.swift <입력 폴더> <출력 폴더> [amount,amount,...]
// 각 이미지: 문서 영역 검출 → 원근 보정 → CIDocumentEnhancer(여러 강도) → 비교용 가로 이어붙인 PNG + 개별 JPG
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Vision

let args = CommandLine.arguments
guard args.count >= 3 else { print("usage: scan_proto.swift <in-dir> <out-dir> [amounts]"); exit(1) }
let inDir = args[1], outDir = args[2]
let amounts: [Double] = args.count > 3 ? args[3].split(separator: ",").compactMap { Double($0) } : [0.6, 1.0, 2.0]
let fm = FileManager.default
try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let ctx = CIContext(options: [.useSoftwareRenderer: false])

func load(_ path: String) -> CIImage? {
    guard let img = CIImage(contentsOf: URL(fileURLWithPath: path), options: [.applyOrientationProperty: true]) else { return nil }
    return img
}

/// 문서 영역 사각형 (이미지 좌표, 좌하단 원점). 세그멘테이션 → 사각 검출 → nil
func detectQuad(_ img: CIImage) -> (CGPoint, CGPoint, CGPoint, CGPoint, String)? {
    let w = img.extent.width, h = img.extent.height
    func pts(_ o: VNRectangleObservation) -> (CGPoint, CGPoint, CGPoint, CGPoint) {
        func s(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * w, y: p.y * h) }
        return (s(o.topLeft), s(o.topRight), s(o.bottomRight), s(o.bottomLeft))
    }
    let handler = VNImageRequestHandler(ciImage: img, options: [:])
    if #available(macOS 12.0, *) {
        let seg = VNDetectDocumentSegmentationRequest()
        try? handler.perform([seg])
        if let o = seg.results?.first, o.confidence > 0.5 {
            let p = pts(o); return (p.0, p.1, p.2, p.3, "seg \(String(format: "%.2f", o.confidence))")
        }
    }
    let rect = VNDetectRectanglesRequest()
    rect.minimumConfidence = 0.5; rect.minimumSize = 0.15; rect.maximumObservations = 1; rect.minimumAspectRatio = 0.3
    try? handler.perform([rect])
    if let o = rect.results?.first {
        let p = pts(o); return (p.0, p.1, p.2, p.3, "rect \(String(format: "%.2f", o.confidence))")
    }
    return nil
}

func perspective(_ img: CIImage, _ q: (CGPoint, CGPoint, CGPoint, CGPoint)) -> CIImage {
    let f = CIFilter.perspectiveCorrection()
    f.inputImage = img
    f.topLeft = q.0; f.topRight = q.1; f.bottomRight = q.2; f.bottomLeft = q.3
    return f.outputImage ?? img
}

func enhance(_ img: CIImage, amount: Double) -> CIImage {
    let f = CIFilter.documentEnhancer()
    f.inputImage = img
    f.amount = Float(amount)
    return f.outputImage ?? img
}

/// 조명 평탄화: 큰 블러로 배경(종이 밝기)을 추정하고 원본을 그걸로 나눠 종이를 흰색으로. 그림자·누런 끼 제거.
func flatten(_ img: CIImage, radiusRatio: CGFloat = 0.04) -> CIImage {
    let r = max(8, img.extent.width * radiusRatio)
    let blur = CIFilter.gaussianBlur()
    blur.inputImage = img.clampedToExtent()
    blur.radius = Float(r)
    guard let bg = blur.outputImage?.cropped(to: img.extent) else { return img }
    // 배경이 너무 어두운 곳(검정 바탕 명함)은 나눗셈이 폭주하므로 바닥값 보정
    let lifted = bg.applyingFilter("CIColorMatrix", parameters: ["inputBiasVector": CIVector(x: 0.08, y: 0.08, z: 0.08, w: 0)])
    // 실측: CIDivideBlendMode 는 background / input 이므로 원본을 background 에 둔다
    let div = CIFilter.divideBlendMode()
    div.inputImage = lifted
    div.backgroundImage = img
    return div.outputImage?.cropped(to: img.extent) ?? img
}

/// 종이 톤 마무리: 밝은 쪽을 흰색으로 밀고 대비 약간
func paperTone(_ img: CIImage) -> CIImage {
    let tc = CIFilter.toneCurve()
    tc.inputImage = img
    tc.point0 = CGPoint(x: 0, y: 0); tc.point1 = CGPoint(x: 0.25, y: 0.21); tc.point2 = CGPoint(x: 0.5, y: 0.52)
    tc.point3 = CGPoint(x: 0.75, y: 0.86); tc.point4 = CGPoint(x: 0.92, y: 1.0)
    let cc = CIFilter.colorControls()
    cc.inputImage = tc.outputImage
    cc.saturation = 1.05; cc.contrast = 1.05; cc.brightness = 0
    return cc.outputImage ?? img
}

func sharpen(_ img: CIImage) -> CIImage {
    let f = CIFilter.unsharpMask(); f.inputImage = img; f.radius = 1.5; f.intensity = 0.4
    return f.outputImage ?? img
}

func limit(_ img: CIImage, maxSide: CGFloat) -> CIImage {
    let s = min(1, maxSide / max(img.extent.width, img.extent.height))
    return s < 1 ? img.transformed(by: CGAffineTransform(scaleX: s, y: s)) : img
}

func save(_ img: CIImage, _ path: String, jpeg: Bool) {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let url = URL(fileURLWithPath: path)
    if jpeg { try? ctx.writeJPEGRepresentation(of: img, to: url, colorSpace: cs, options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.85]) }
    else { try? ctx.writePNGRepresentation(of: img, to: url, format: .RGBA8, colorSpace: cs) }
}

/// 가로로 이어붙이기 (높이 통일)
func hstack(_ imgs: [CIImage], height: CGFloat, gap: CGFloat = 16) -> CIImage {
    var x: CGFloat = 0
    var out = CIImage(color: CIColor(red: 0.85, green: 0.86, blue: 0.9)).cropped(to: CGRect(x: 0, y: 0, width: 1, height: height))
    var total: CGFloat = 0
    for im in imgs { total += im.extent.width * (height / im.extent.height) + gap }
    out = CIImage(color: CIColor(red: 0.85, green: 0.86, blue: 0.9)).cropped(to: CGRect(x: 0, y: 0, width: total, height: height))
    for im in imgs {
        let s = height / im.extent.height
        let t = im.transformed(by: CGAffineTransform(scaleX: s, y: s)).transformed(by: CGAffineTransform(translationX: x - im.extent.origin.x * s, y: -im.extent.origin.y * s))
        out = t.composited(over: out)
        x += im.extent.width * s + gap
    }
    return out
}

let files = (try? fm.contentsOfDirectory(atPath: inDir))?.filter { ["jpg", "jpeg", "png", "heic"].contains(($0 as NSString).pathExtension.lowercased()) }.sorted() ?? []
for f in files {
    let t0 = Date()
    guard let src = load("\(inDir)/\(f)") else { print("skip \(f)"); continue }
    let base = (f as NSString).deletingPathExtension
    var note = "none"
    var cropped = src
    if let q = detectQuad(src) { cropped = perspective(src, (q.0, q.1, q.2, q.3)); note = q.4 }
    cropped = limit(cropped, maxSide: 2000)
    // 변형: crop | e1 | e2 | flat+tone | flat+e1 | flat+tone+sharp
    let variants: [(String, CIImage)] = [
        ("crop", cropped),
        ("e1", enhance(cropped, amount: 1.0)),
        ("e2", enhance(cropped, amount: 2.0)),
        ("eSrc", { let q = detectQuad(src); let e = enhance(src, amount: 1.0); return q.map { limit(perspective(e, ($0.0, $0.1, $0.2, $0.3)), maxSide: 2000) } ?? e }()),
        ("ft", paperTone(flatten(cropped))),
        ("fe", enhance(flatten(cropped), amount: 1.0)),
        ("fts", sharpen(paperTone(flatten(cropped)))),
    ]
    var row: [CIImage] = []
    for (n, im) in variants {
        row.append(im)
        save(im, "\(outDir)/\(base)_\(n).jpg", jpeg: true)
    }
    save(hstack(row, height: 900), "\(outDir)/\(base)_compare.png", jpeg: false)
    print("\(f): \(note), \(cropped.extent.width.rounded())x\(cropped.extent.height.rounded()), \(String(format: "%.0f", Date().timeIntervalSince(t0) * 1000))ms (amounts \(amounts))")
}
