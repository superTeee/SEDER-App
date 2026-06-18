import Foundation
import CryptoKit
import Security

// MARK: - PINService
// Lagrer en hash av brukerens 4-sifrede kode lokalt i iOS Keychain.
// VIKTIG: Koden er KUN en lokal "rask opplåsing" av en allerede aktiv
// Supabase-sesjon — den erstatter ikke passord eller server-side innlogging.
// Selve sesjonen (refresh-token) håndteres fortsatt av Supabase SDK-et.

@MainActor
class PINService: ObservableObject {

    @Published var isPINSet: Bool
    @Published var failedAttempts = 0

    private let account = "com.tomerikheggedal.vitola.pinHash"
    private let maxAttempts = 5

    init() {
        isPINSet = Self.readHash(account: "com.tomerikheggedal.vitola.pinHash") != nil
    }

    // MARK: - Sett ny kode
    func setPIN(_ pin: String) {
        Self.save(Self.hash(pin), account: account)
        isPINSet = true
        failedAttempts = 0
    }

    // MARK: - Verifiser kode
    func verify(_ pin: String) -> Bool {
        guard let stored = Self.readHash(account: account) else { return false }
        let match = Self.hash(pin) == stored
        if match {
            failedAttempts = 0
        } else {
            failedAttempts += 1
        }
        return match
    }

    var attemptsRemaining: Int {
        max(0, maxAttempts - failedAttempts)
    }

    var isLockedOut: Bool {
        failedAttempts >= maxAttempts
    }

    // MARK: - Fjern kode
    func clearPIN() {
        Self.delete(account: account)
        isPINSet = false
        failedAttempts = 0
    }

    // MARK: - Hashing (SHA256, ikke reversibel — selve koden lagres aldri)
    private static func hash(_ pin: String) -> String {
        let digest = SHA256.hash(data: Data(pin.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Keychain-hjelpere
    private static func save(_ value: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = Data(value.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private static func readHash(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
