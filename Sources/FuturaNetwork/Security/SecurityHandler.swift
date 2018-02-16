import Foundation

// MARK: -
// MARK: host association

public enum HostAssociation {
    case hostRegex(String)
    case hostList([String])
    case singleHost(String)
}

public extension HostAssociation {
    
    func isAssociatedWith(host: String) -> Bool {
        switch self {
        case let .hostRegex(hostsRegex):
            if let _ = host.range(of: hostsRegex, options: .regularExpression) {
                return true
            } else {
                return false
            }
        case let .hostList(associatedHosts):
            for associatedHost in associatedHosts {
                if associatedHost == host {
                    return true
                } else {
                    continue
                }
            }
            return false
        case let .singleHost(associatedHost):
            return associatedHost == host
        }
    }
}

// MARK: -
// MARK: security handler

public protocol SecurityHandler {
    
    func resolveChallenge(_ challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?)
}

// MARK: -
// MARK: certificate pinning security handler

public class CertificatePinningSecurityHandler : SecurityHandler {

    public let validateServerTrust: Bool
    public let certificateContainers: [PinningCertificateContainer]
    
    public init(with certificateContainers: [PinningCertificateContainer], validateServerTrust: Bool) {
        self.certificateContainers = certificateContainers
        self.validateServerTrust = validateServerTrust
    }
    
    public func resolveChallenge(_ challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        
        guard !certificateContainers.isEmpty else { return (.cancelAuthenticationChallenge, nil) }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else { return (.cancelAuthenticationChallenge, nil) }
        
        let host = challenge.protectionSpace.host
        let policy = SecPolicyCreateSSL(true, host as CFString)
        
        SecTrustSetPolicies(serverTrust, policy)
        
        let trustedCertificatesForHost = certificateContainers.filter { $0.isAssociatedWith(host:host) }.flatMap { $0.certificates }
        
        guard !trustedCertificatesForHost.isEmpty else { return (.cancelAuthenticationChallenge, nil) }
        
        if validateServerTrust {
            SecTrustSetAnchorCertificates(serverTrust, trustedCertificatesForHost as CFArray)
            SecTrustSetAnchorCertificatesOnly(serverTrust, true)
            if serverTrust.isValid {
                return (.useCredential, URLCredential(trust: serverTrust))
            } else {
                return (.cancelAuthenticationChallenge, nil)
            }
        } else {
            if SecTrustGetCertificateCount(serverTrust) > 0 {
                let certToCheckData = SecCertificateCopyData(SecTrustGetCertificateAtIndex(serverTrust, 0)!) as Data
                let trustedCertData = trustedCertificatesForHost.map { SecCertificateCopyData($0) as Data }
                if trustedCertData.contains(certToCheckData) {
                    return (.useCredential, URLCredential(trust: serverTrust))
                } else {
                    return (.cancelAuthenticationChallenge, nil)
                }
            } else {
                return (.cancelAuthenticationChallenge, nil)
            }
        }
    }
}

// MARK: -
// MARK: SecTrust

extension SecTrust {
    
    var certificates: [SecCertificate] {
        var certificates: [SecCertificate] = []
        
        let certificateCount = SecTrustGetCertificateCount(self)
        
        guard certificateCount > 0 else {
            return certificates
        }
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(self, i) else { continue }
            certificates.append(certificate)
        }
        
        return certificates
    }
    
    var isValid: Bool {
        var isValid = false
        
        var result = SecTrustResultType.invalid
        let status = SecTrustEvaluate(self, &result)
        
        if status == errSecSuccess {
            let unspecified = SecTrustResultType.unspecified
            let proceed = SecTrustResultType.proceed
            
            isValid = result == unspecified || result == proceed
        }
        
        return isValid
    }
}
