import Flutter
import CallKit
import UIKit

/// MethodChannel `bizkeep/calldir`
///  - sync(entries: [[Int, String]])  : App Group 에 calldir.json 저장 후 익스텐션 리로드
///  - status()                        : "enabled" | "disabled" | "unknown"
///  - openSettings()                  : 설정 > 전화 > 통화 차단 및 발신자 확인 열기
final class CallDirPlugin: NSObject {
  static let channelName = "bizkeep/calldir"
  static let extensionId = "com.bts.bizkeep.calldir"
  static let appGroup = "group.com.bts.bizkeep"

  static func register(with messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let p = CallDirPlugin()
    ch.setMethodCallHandler(p.handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "sync":
      guard let args = call.arguments as? [String: Any], let entries = args["entries"] as? [[Any]] else { result(false); return }
      DispatchQueue.global(qos: .utility).async {
        let ok = self.write(entries: entries)
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: Self.extensionId) { err in
          DispatchQueue.main.async { result(ok && err == nil ? "ok" : (err.map { "reload: \($0.localizedDescription)" } ?? "write failed")) }
        }
      }
    case "status":
      CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: Self.extensionId) { status, _ in
        let s: String
        switch status { case .enabled: s = "enabled"; case .disabled: s = "disabled"; default: s = "unknown" }
        DispatchQueue.main.async { result(s) }
      }
    case "openSettings":
      if #available(iOS 13.2, *) {
        CXCallDirectoryManager.sharedInstance.openSettings { err in DispatchQueue.main.async { result(err == nil) } }
      } else {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func write(entries: [[Any]]) -> Bool {
    guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroup) else { return false }
    let url = dir.appendingPathComponent("calldir.json")
    guard let data = try? JSONSerialization.data(withJSONObject: ["entries": entries]) else { return false }
    do { try data.write(to: url, options: .atomic); return true } catch { return false }
  }
}
