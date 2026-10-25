// 맥에서 픽스처 명함 사진을 Vision OCR 해 .txt 로 저장 (iOS 앱과 같은 엔진).
// 사용: swift tools/ocr_fixtures.swift test/fixtures/cards
import Foundation
import Vision
import AppKit

let dir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "test/fixtures/cards"
let fm = FileManager.default
let files = (try? fm.contentsOfDirectory(atPath: dir))?.filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".png") }.sorted() ?? []

for f in files {
    let path = "\(dir)/\(f)"
    guard let img = NSImage(contentsOfFile: path), let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { print("skip \(f)"); continue }
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = .accurate
    req.recognitionLanguages = ["ko-KR", "en-US"]
    req.usesLanguageCorrection = false
    try? VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
    let obs = (req.results ?? []).sorted { a, b in
        // 위→아래, 같은 줄은 왼→오 (Vision 좌표는 아래가 0)
        let ay = a.boundingBox.midY, by = b.boundingBox.midY
        if abs(ay - by) > min(a.boundingBox.height, b.boundingBox.height) * 0.6 { return ay > by }
        return a.boundingBox.minX < b.boundingBox.minX
    }
    var lines: [String] = []
    var meta: [String] = []
    for o in obs {
        guard let c = o.topCandidates(1).first else { continue }
        lines.append(c.string)
        let b = o.boundingBox
        meta.append(String(format: "%.3f\t%.3f\t%.3f\t%.3f\t%.2f\t%@", b.minX, 1 - b.maxY, b.width, b.height, c.confidence, c.string))
    }
    let base = (f as NSString).deletingPathExtension
    try? lines.joined(separator: "\n").write(toFile: "\(dir)/\(base).txt", atomically: true, encoding: .utf8)
    try? (["x\ty\tw\th\tconf\ttext"] + meta).joined(separator: "\n").write(toFile: "\(dir)/\(base).boxes.tsv", atomically: true, encoding: .utf8)
    print("\(f): \(lines.count) lines")
}
