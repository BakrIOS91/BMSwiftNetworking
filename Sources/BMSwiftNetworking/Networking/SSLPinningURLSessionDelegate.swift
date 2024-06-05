//
//  SSLPinningURLSessionDelegate.swift
//
//
//  Created by Bakr mohamed on 05/06/2024.
//

/// Explanation of the Code:
/// Class Declaration and Initialization:

/// SSLPinningURLSessionDelegate class implements the URLSessionDelegate protocol.
/// It has an array sslCertificates to store the pinned SSL certificates.
/// The initializer accepts an array of SecCertificate objects representing the pinned certificates.
/// urlSession(_:didReceive:completionHandler:) Method:

/// This method handles server trust authentication challenges.
/// It first checks if the authentication method is NSURLAuthenticationMethodServerTrust and retrieves the serverTrust object.
///                     If the method is not serverTrust, it calls the completion handler with .performDefaultHandling.
///                     Retrieving Server Certificates:
///
///                         It initializes an empty array serverCertificates to store the certificates from the server trust.
///                     It gets the number of certificates in the server's trust chain using SecTrustGetCertificateCount.
///                     It iterates over the certificates in the server's trust chain using SecTrustGetCertificateAtIndex and appends each certificate to the ///serverCertificates array.
///                     Comparing Server Certificates with Pinned Certificates:
///
///                         It iterates over the server certificates and compares each one with the pinned certificates.
///                     The comparison is done by checking if the data of the server certificate matches the data of any pinned certificate using SecCertificateCopyData.
///                     If a match is found, it calls the completion handler with .useCredential and the server trust credential.
///                     Handling No Match:
///
///                         If no matching certificate is found, it calls the completion handler with .cancelAuthenticationChallenge to cancel the authentication challenge.
// /


import Foundation

/// A URLSessionDelegate implementation that handles SSL pinning.
public final class SSLPinningURLSessionDelegate: NSObject, URLSessionDelegate {
    
    /// Array of pinned SSL certificates.
    private var sslCertificates: [SecCertificate]
    
    /// Initializes the SSLPinningURLSessionDelegate with an array of pinned certificates.
    ///
    /// - Parameter sslCertificates: An array of SecCertificate representing the pinned certificates.
    init(sslCertificates: [SecCertificate]) {
        self.sslCertificates = sslCertificates
    }
    
    /// Handles the server trust authentication challenge to perform SSL pinning.
    ///
    /// - Parameters:
    ///   - session: The URL session containing the challenge.
    ///   - challenge: The authentication challenge.
    ///   - completionHandler: A closure that your delegate method must call to continue the URL loading process.
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Check if the authentication method is server trust and retrieve the server trust object.
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            // If not, perform default handling.
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Array to store the server's certificates.
        var serverCertificates: [SecCertificate] = []
        
        // Get the number of certificates in the server's trust object.
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        // Iterate over each certificate in the server's trust chain.
        for index in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, index) {
                // Append each certificate to the serverCertificates array.
                serverCertificates.append(certificate)
            }
        }
        
        // Compare each server certificate with the pinned certificates.
        for serverCertificate in serverCertificates {
            if sslCertificates.contains(where: { pinnedCertificate in
                // Check if the data of the pinned certificate matches the server certificate.
                SecCertificateCopyData(pinnedCertificate) == SecCertificateCopyData(serverCertificate)
            }) {
                // If a match is found, use the server trust and call the completion handler with the useCredential disposition.
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }
        
        // If no matching certificate is found, cancel the authentication challenge.
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

