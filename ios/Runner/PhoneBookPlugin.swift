import Contacts
import ContactsUI
import Flutter
import UIKit

/// MethodChannel `bizkeep/phonebook` — 폰 주소록(Contacts) 읽기·쓰기.
///  - requestAccess()            : Bool
///  - fetchAll()                 : [{id, name, company, title, department, phones:[String], emails:[String], addresses:[String], urls:[String]}]
///  - insert(entry)              : String(id) | nil
///  - update(entry with id)      : Bool — name·company·title·department 는 비어 있지 않으면 덮어쓰고, phones/emails/addresses/urls 는 추가만
///  - openInsert(entry)          : Bool — 연락처 앱 "새 연락처" 양식을 미리 채워서 띄움. 저장하면 true, 취소면 false
/// 메모(note)는 iOS 가 별도 entitlement 를 요구해 다루지 않는다.
final class PhoneBookPlugin: NSObject, CNContactViewControllerDelegate {
  static let channelName = "bizkeep/phonebook"
  private let store = CNContactStore()
  private var pendingOpen: FlutterResult?

  static func register(with messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let p = PhoneBookPlugin()
    ch.setMethodCallHandler(p.handle)
  }

  private static let keys: [CNKeyDescriptor] = [
    CNContactIdentifierKey as CNKeyDescriptor,
    CNContactGivenNameKey as CNKeyDescriptor,
    CNContactFamilyNameKey as CNKeyDescriptor,
    CNContactOrganizationNameKey as CNKeyDescriptor,
    CNContactJobTitleKey as CNKeyDescriptor,
    CNContactDepartmentNameKey as CNKeyDescriptor,
    CNContactPhoneNumbersKey as CNKeyDescriptor,
    CNContactEmailAddressesKey as CNKeyDescriptor,
    CNContactPostalAddressesKey as CNKeyDescriptor,
    CNContactUrlAddressesKey as CNKeyDescriptor,
    CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
  ]

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestAccess":
      store.requestAccess(for: .contacts) { ok, _ in DispatchQueue.main.async { result(ok) } }
    case "fetchAll":
      DispatchQueue.global(qos: .userInitiated).async {
        var out: [[String: Any]] = []
        let req = CNContactFetchRequest(keysToFetch: Self.keys)
        do {
          try self.store.enumerateContacts(with: req) { c, _ in out.append(Self.toMap(c)) }
          DispatchQueue.main.async { result(out) }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "fetch", message: error.localizedDescription, details: nil)) }
        }
      }
    case "insert":
      guard let m = call.arguments as? [String: Any] else { result(nil); return }
      let c = CNMutableContact()
      Self.apply(m, to: c, appendOnly: false)
      let save = CNSaveRequest()
      save.add(c, toContainerWithIdentifier: nil)
      do { try store.execute(save); result(c.identifier) } catch { result(FlutterError(code: "insert", message: error.localizedDescription, details: nil)) }
    case "update":
      guard let m = call.arguments as? [String: Any], let id = m["id"] as? String else { result(false); return }
      do {
        let existing = try store.unifiedContact(withIdentifier: id, keysToFetch: Self.keys)
        guard let c = existing.mutableCopy() as? CNMutableContact else { result(false); return }
        Self.apply(m, to: c, appendOnly: true)
        let save = CNSaveRequest()
        save.update(c)
        try store.execute(save)
        result(true)
      } catch { result(FlutterError(code: "update", message: error.localizedDescription, details: nil)) }
    case "openInsert":
      guard let m = call.arguments as? [String: Any] else { result(false); return }
      let c = CNMutableContact()
      Self.apply(m, to: c, appendOnly: false)
      guard let presenter = Self.topViewController() else { result(false); return }
      let vc = CNContactViewController(forNewContact: c)
      vc.contactStore = store
      vc.delegate = self
      pendingOpen = result
      let nav = UINavigationController(rootViewController: vc)
      nav.modalPresentationStyle = .formSheet
      presenter.present(nav, animated: true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // CNContactViewControllerDelegate — 저장하면 contact 가 non-nil, 취소면 nil
  func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
    viewController.navigationController?.dismiss(animated: true)
    pendingOpen?(contact != nil)
    pendingOpen = nil
  }

  private static func toMap(_ c: CNContact) -> [String: Any] {
    let name = CNContactFormatter.string(from: c, style: .fullName) ?? [c.familyName, c.givenName].filter { !$0.isEmpty }.joined(separator: " ")
    return [
      "id": c.identifier,
      "name": name,
      "company": c.organizationName,
      "title": c.jobTitle,
      "department": c.departmentName,
      "phones": c.phoneNumbers.map { $0.value.stringValue },
      "emails": c.emailAddresses.map { String($0.value) },
      "addresses": c.postalAddresses.map { CNPostalAddressFormatter.string(from: $0.value, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ") },
      "urls": c.urlAddresses.map { String($0.value) },
    ]
  }

  /// Dart 가 보낸 항목을 연락처에 반영. appendOnly=true 면 번호·메일·주소·URL 은 뒤에 덧붙이기만 (Dart 쪽에서 이미 없는 것만 보냄).
  private static func apply(_ m: [String: Any], to c: CNMutableContact, appendOnly: Bool) {
    if let name = m["name"] as? String, !name.isEmpty { c.givenName = name; c.familyName = "" }
    if let v = m["company"] as? String, !v.isEmpty { c.organizationName = v }
    if let v = m["title"] as? String, !v.isEmpty { c.jobTitle = v }
    if let v = m["department"] as? String, !v.isEmpty { c.departmentName = v }
    let phones = (m["phones"] as? [[String: String]] ?? []).map { p -> CNLabeledValue<CNPhoneNumber> in
      let label: String
      switch p["label"] { case "work": label = CNLabelWork; case "fax": label = CNLabelPhoneNumberWorkFax; default: label = CNLabelPhoneNumberMobile }
      return CNLabeledValue(label: label, value: CNPhoneNumber(stringValue: p["number"] ?? ""))
    }
    let emails = (m["emails"] as? [String] ?? []).map { CNLabeledValue(label: CNLabelWork, value: $0 as NSString) }
    let addresses = (m["addresses"] as? [String] ?? []).map { s -> CNLabeledValue<CNPostalAddress> in
      let a = CNMutablePostalAddress(); a.street = s
      return CNLabeledValue(label: CNLabelWork, value: a)
    }
    let urls = (m["urls"] as? [String] ?? []).map { CNLabeledValue(label: CNLabelWork, value: $0 as NSString) }
    if appendOnly {
      c.phoneNumbers += phones; c.emailAddresses += emails; c.postalAddresses += addresses; c.urlAddresses += urls
    } else {
      c.phoneNumbers = phones; c.emailAddresses = emails; c.postalAddresses = addresses; c.urlAddresses = urls
    }
  }

  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow } ?? scenes.first?.windows.first
    var vc = window?.rootViewController
    while let p = vc?.presentedViewController { vc = p }
    return vc
  }
}
