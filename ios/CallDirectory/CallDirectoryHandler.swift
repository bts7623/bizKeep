import Foundation
import CallKit

/// 수신 전화 식별 익스텐션. 앱이 App Group 컨테이너에 써 둔 calldir.json 을 읽어 번호→라벨을 등록한다.
/// 파일 포맷: {"entries": [[821012345678, "김전영 · 폭스소프트"], ...]} — 번호 오름차순 정렬 필수.
final class CallDirectoryHandler: CXCallDirectoryProvider {
  static let appGroup = "group.com.bts.bizkeep"

  override func beginRequest(with context: CXCallDirectoryExtensionContext) {
    context.delegate = self
    // 증분 갱신이어도 전체 교체 (데이터가 수천 건 이하라 단순·안전)
    if context.isIncremental {
      context.removeAllIdentificationEntries()
    }
    for (number, label) in loadEntries() {
      context.addIdentificationEntry(withNextSequentialPhoneNumber: number, label: label)
    }
    context.completeRequest()
  }

  private func loadEntries() -> [(CXCallDirectoryPhoneNumber, String)] {
    guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup) else { return [] }
    let url = dir.appendingPathComponent("calldir.json")
    guard let data = try? Data(contentsOf: url),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let raw = obj["entries"] as? [[Any]] else { return [] }
    var out: [(CXCallDirectoryPhoneNumber, String)] = []
    out.reserveCapacity(raw.count)
    for e in raw {
      guard e.count >= 2 else { continue }
      let n: Int64
      if let i = e[0] as? Int64 { n = i } else if let i = e[0] as? Int { n = Int64(i) } else if let d = e[0] as? Double { n = Int64(d) } else { continue }
      guard let label = e[1] as? String, !label.isEmpty else { continue }
      out.append((n, label))
    }
    // 안전장치: 오름차순 + 중복 제거 (CallKit 은 정렬 안 되면 전체 실패)
    out.sort { $0.0 < $1.0 }
    var dedup: [(CXCallDirectoryPhoneNumber, String)] = []
    for e in out where dedup.last?.0 != e.0 { dedup.append(e) }
    return dedup
  }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
  func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
    // 실패해도 앱 쪽에서 상태 조회로 알 수 있음
  }
}
