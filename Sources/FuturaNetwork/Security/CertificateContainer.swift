import Foundation

public struct PinningCertificateContainer {
    
    public let association: HostAssociation
    public let certificates: [SecCertificate]
    
    // MARK: -
    // MARK: init
    
    public init(from containerBundle: Bundle = Bundle.main, for association: HostAssociation) {
        self.init(with: certificatesIn(containerBundle), for: association)
    }
    
    public init(with certificates: [SecCertificate], for association: HostAssociation) {
        self.association = association
        self.certificates = certificates
    }
}


// MARK: -
// MARK: host check

public extension PinningCertificateContainer {
    
    func isAssociatedWith(host: String) -> Bool {
        return association.isAssociatedWith(host: host)
    }
}

// MARK: -
// MARK: certificate loading

fileprivate func certificatesIn(_ bundle: Bundle = Bundle.main) -> [SecCertificate] {
    var certificates: [SecCertificate] = []
    
    let paths = Set([".cer", ".CER", ".crt", ".CRT", ".der", ".DER"].map { fileExtension in
        bundle.paths(forResourcesOfType: fileExtension, inDirectory: nil)
        }.joined())
    
    for path in paths {
        if let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData,
            let certificate = SecCertificateCreateWithData(nil, certificateData)
        {
            certificates.append(certificate)
        }
    }
    return certificates
}

