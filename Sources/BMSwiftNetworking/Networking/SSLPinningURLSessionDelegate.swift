//
//  SSLPinningURLSessionDelegate.swift
//
//  Created by Bakr Mohamed on 05/06/2024.
//
//  Description:
//  This file provides a secure implementation of SSL/TLS pinning for URLSession
//  connections. It supports two types of pinning:
//
//  1. Certificate Pinning
//     - Validates the server's certificate against a pre-bundled/pinned certificate.
//
//  2. Public Key Pinning
//     - Validates the server's public key (SHA256 hash) against pre-configured pinned keys.
//
//  By using this delegate with URLSession, your app ensures that only trusted servers
//  (with known certificates or public keys) are allowed, helping to prevent MITM attacks.
//

import Foundation
import Security
import CryptoKit

/// `SSLPinningURLSessionDelegate`
///
/// A URLSession delegate that enforces SSL/TLS pinning.
/// Supports:
/// - Certificate Pinning
/// - Public Key Pinning
///
/// Usage:
/// ```swift
/// let config = SSLPinningConfiguration(
///     isEnabled: true,
///     allowFallback: false,
///     pinnedHosts: ["example.com"],
///     pinnedPublicKeyHashes: ["sha256/abc123..."],
///     pinnedCertificates: [cert]
/// )
/// let delegate = SSLPinningURLSessionDelegate(configuration: config)
/// let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
/// ```
///
/// Security:
/// - Prevents unauthorized certificates even if the system root CA trusts them.
/// - Blocks Man-in-the-Middle (MITM) attacks by validating the expected cert/key.
final class SSLPinningURLSessionDelegate: NSObject, URLSessionDelegate {

    // MARK: - Properties
    
    /// Configuration for SSL pinning (enabled state, fallback, pinned certs/keys).
    private let configuration: SSLPinningConfiguration

    // MARK: - Initialization
    
    /// Initialize with a configuration for SSL pinning
    /// - Parameter configuration: The SSL pinning configuration object.
    init(configuration: SSLPinningConfiguration) {
        self.configuration = configuration
        super.init()
    }

    // MARK: - URLSessionDelegate
    
    /// Handles authentication challenges (SSL/TLS).
    ///
    /// - Parameters:
    ///   - session: The URLSession instance.
    ///   - challenge: The authentication challenge (e.g. server trust).
    ///   - completionHandler: Must be called with the authentication decision.
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Ensure SSL pinning is enabled
        guard configuration.isEnabled else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Ensure this is a "server trust" challenge (SSL/TLS handshake)
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let host = challenge.protectionSpace.host

        // Validate host against our pinned hosts
        guard configuration.pinnedHosts.contains(host) else {
            // If fallback is allowed → let system handle it, otherwise reject.
            if configuration.allowFallback {
                completionHandler(.performDefaultHandling, nil)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
            return
        }

        // Validate the server’s certificate or public key
        if validateServerTrust(serverTrust) {
            // Use the credential if validation succeeds
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            // If validation fails → fallback or cancel
            if configuration.allowFallback {
                completionHandler(.performDefaultHandling, nil)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }

    // MARK: - SSL Validation
    
    /// Validates the server's trust object (certificates/public keys).
    /// - Parameter serverTrust: The SecTrust object from server.
    /// - Returns: `true` if validation passes, otherwise `false`.
    private func validateServerTrust(_ serverTrust: SecTrust) -> Bool {
        // Extract all server certificates in the trust chain
        var serverCertificates: [SecCertificate] = []
        let certificateCount = SecTrustGetCertificateCount(serverTrust)

        // Collect each certificate
        for index in 0..<certificateCount {
            if let certificate = getCertificateAtIndex(serverTrust, index) {
                serverCertificates.append(certificate)
            }
        }

        // Validate against pinned certificates (if any)
        if !configuration.pinnedCertificates.isEmpty {
            return validateCertificatePinning(serverCertificates: serverCertificates)
        }

        // Validate against pinned public key hashes (if any)
        if !configuration.pinnedPublicKeyHashes.isEmpty {
            return validatePublicKeyPinning(serverCertificates: serverCertificates)
        }

        // If neither pinning method is configured → fail
        return false
    }

    // MARK: - Certificate Pinning
    
    /// Compares server certificates against locally pinned certificates.
    /// - Parameter serverCertificates: Certificates received from server.
    /// - Returns: `true` if a match is found, else `false`.
    private func validateCertificatePinning(serverCertificates: [SecCertificate]) -> Bool {
        for serverCertificate in serverCertificates {
            if configuration.pinnedCertificates.contains(where: { pinnedCertificate in
                // Match by raw certificate data
                SecCertificateCopyData(pinnedCertificate) == SecCertificateCopyData(serverCertificate)
            }) {
                return true
            }
        }
        return false
    }

    // MARK: - Public Key Pinning
    
    /// Compares server public keys (SHA-256 hash) against pinned public key hashes.
    /// - Parameter serverCertificates: Certificates received from server.
    /// - Returns: `true` if a match is found, else `false`.
    private func validatePublicKeyPinning(serverCertificates: [SecCertificate]) -> Bool {
        for serverCertificate in serverCertificates {
            if validateCertificatePublicKey(serverCertificate) {
                return true
            }
        }
        return false
    }

    /// Validates a single certificate's public key against pinned hashes.
    /// - Parameter certificate: A server certificate.
    /// - Returns: `true` if the public key hash matches a pinned hash.
    private func validateCertificatePublicKey(_ certificate: SecCertificate) -> Bool {
        // Extract public key
        guard let key = SecCertificateCopyKey(certificate) else {
            return false
        }

        // Convert key to raw data
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            return false
        }

        // Compute SHA256 hash of public key
        let hash = SHA256.hash(data: publicKeyData)
        let publicKeyHash = Data(hash).map { String(format: "%02x", $0) }.joined()
        let formattedHash = "sha256/\(publicKeyHash)"

        // Compare with pinned hashes
        return configuration.pinnedPublicKeyHashes.contains(formattedHash)
    }

    // MARK: - Helpers
    
    /// Retrieves certificate at given index (handles iOS 15+ API changes).
    /// - Parameters:
    ///   - serverTrust: The server's trust object.
    ///   - index: Index of certificate in trust chain.
    /// - Returns: `SecCertificate?` at index if available.
    private func getCertificateAtIndex(_ serverTrust: SecTrust, _ index: Int) -> SecCertificate? {
        if #available(iOS 15.0, *) {
            guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) else {
                return nil
            }
            let certificateCount = CFArrayGetCount(certificateChain)
            guard index < certificateCount else { return nil }

            guard let certificate = CFArrayGetValueAtIndex(certificateChain, index) else {
                return nil
            }
            return Unmanaged<SecCertificate>.fromOpaque(certificate).takeUnretainedValue()
        } else {
            // Legacy API for < iOS 15
            return SecTrustGetCertificateAtIndex(serverTrust, index)
        }
    }
}

/// Configuration object for SSL pinning.
///
/// Holds pinned certificates, pinned public key hashes, and host restrictions.
public struct SSLPinningConfiguration {
    /// Whether SSL pinning is active.
    fileprivate let isEnabled: Bool
    
    /// If true, fallback to default handling when pinning fails.
    fileprivate let allowFallback: Bool
    
    /// Hosts for which SSL pinning applies.
    fileprivate let pinnedHosts: Set<String>
    
    /// SHA-256 hashes of trusted public keys, formatted as "sha256/HEX".
    fileprivate let pinnedPublicKeyHashes: Set<String>
    
    /// Certificates bundled with the app for certificate pinning.
    fileprivate let pinnedCertificates: [SecCertificate]

    /// Initializes a configuration for SSL pinning.
    /// - Parameters:
    ///   - isEnabled: Enables or disables pinning.
    ///   - allowFallback: Allow fallback to system handling if pinning fails.
    ///   - pinnedHosts: Hosts that require pinning.
    ///   - pinnedPublicKeyHashes: Public key hashes (SHA-256).
    ///   - pinnedCertificates: Pinned certificates (optional).
    public init(
        isEnabled: Bool,
        allowFallback: Bool,
        pinnedHosts: Set<String>,
        pinnedPublicKeyHashes: Set<String>,
        pinnedCertificates: [SecCertificate] = []
    ) {
        self.isEnabled = isEnabled
        self.allowFallback = allowFallback
        self.pinnedHosts = pinnedHosts
        self.pinnedPublicKeyHashes = pinnedPublicKeyHashes
        self.pinnedCertificates = pinnedCertificates
    }
}
