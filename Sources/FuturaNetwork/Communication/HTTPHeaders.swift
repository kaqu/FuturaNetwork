// https://www.w3.org/International/articles/http-charset/index

import Foundation

public typealias HTTPHeaders = [String : String]

public enum HTTPHeader {
    case userAgent(String)
    case accept(String)
    case acceptCharset(String)
    case authorization(String)
    case contentType(ContentType)
    case custom(key: String, value: String)
}

public extension HTTPHeader {
    
    var key: String {
        switch self {
        case .userAgent:
            return "User-Agent"
        case .accept:
            return "Accept"
        case .acceptCharset:
            return "Accept-Charset"
        case .authorization:
            return "Authorization"
        case .contentType:
            return "Content-Type"
        case let .custom(key, _):
            return key
        }
    }
    
    var value: String {
        switch self {
        case let .userAgent(value):
            return value
        case let .accept(value):
            return value
        case let .acceptCharset(value):
            return value
        case let .authorization(value):
            return value
        case let .contentType(value):
            return value.httpHeaderValue
        case let .custom(_, value):
            return value
        }
    }
}

public extension HTTPHeader {
    
    public enum ContentType {
        case plain(encoding: String.Encoding)
        case html(encoding: String.Encoding)
        case imageJPEG
        case imagePNG
        case pdf
        case json(encoding: String.Encoding)
        case xml(encoding: String.Encoding)
        case formURLEncoded(encoding: String.Encoding)
        case undefined
    }
}

public extension HTTPHeader.ContentType {
    
    var httpHeaderValue: String {
        switch self {
        case let .plain(encoding):
            return "text/plain; charset=\(encoding.httpHeaderValue)"
        case let .html(encoding):
            return "text/html; charset=\(encoding.httpHeaderValue)"
        case .imageJPEG:
            return "image/jpeg"
        case .imagePNG:
            return "image/png"
        case .pdf:
            return "application/pdf"
        case let .json(encoding):
            return "application/json; charset=\(encoding.httpHeaderValue)"
        case let .xml(encoding):
            return "application/xml; charset=\(encoding.httpHeaderValue)"
        case let .formURLEncoded(encoding):
            return "application/x-www-form-urlencoded; charset=\(encoding.httpHeaderValue)"
        case .undefined:
            return "undefined"
        }
    }
    
    var characterEncoding: String.Encoding? {
        switch self {
        case let .plain(encoding):
            return encoding
        case let .html(encoding):
            return encoding
        case .imageJPEG:
            return nil
        case .imagePNG:
            return nil
        case .pdf:
            return nil
        case let .json(encoding):
            return encoding
        case let .xml(encoding):
            return encoding
        case let .formURLEncoded(encoding):
            return encoding
        case .undefined:
            return nil
        }
    }
    
    init?(withHeaderValue name: String?) {
        guard let name = name else {
            return nil
        }
        switch name {
        case name where name.contains("text/plain"):
            self = .plain(encoding: String.Encoding(withName: name.httpHeaderCharset ?? "") ?? .isoLatin1)
        case name where name.contains("text/html"):
            self = .html(encoding: String.Encoding(withName: name.httpHeaderCharset ?? "") ?? .isoLatin1)
        case name where name.contains("image/jpeg"):
            self = .imageJPEG
        case name where name.contains("image/png"):
            self = .imagePNG
        case name where name.contains("application/pdf"):
            self = .pdf
        case name where name.contains("application/json"):
            self = .json(encoding: String.Encoding(withName: name.httpHeaderCharset ?? "") ?? .utf8)
        case name where name.contains("application/xml"):
            self = .xml(encoding: String.Encoding(withName: name.httpHeaderCharset ?? "") ?? .utf8)
        case name where name.contains("application/x-www-form-urlencoded"):
            self = .formURLEncoded(encoding: String.Encoding(withName: name.httpHeaderCharset ?? "") ?? .utf8)
        default:
            return nil
        }
    }
}


public extension Array where Element == HTTPHeader {
    
    var headersDictionary: HTTPHeaders {
        return self.reduce([:], { result, header -> HTTPHeaders in
            var result = result
            result[header.key] = header.value
            return result
        })
    }
}

public extension Dictionary where Key == String, Value == String {
    
    mutating func setHeader(_ header: HTTPHeader) {
        self[header.key] = header.value
    }
}

fileprivate extension String {
    
    var httpHeaderCharset: String? {
        let components = self.components(separatedBy: "charset=")
        if components.count > 1 {
            if components[1].contains(";") {
                return components[1].components(separatedBy: ";")[0]
            } else {
                return components[1]
            }
        } else {
            return nil
        }
    }
}

internal extension String.Encoding {
    
    // TODO: add more data encodings
    init?(withName name: String) {
        switch name.lowercased() {
        case "ascii":
            self = .ascii
        case "utf-8":
            self = .utf8
        case "iso/iec 8859-1", "iso-8859-1":
            self = .isoLatin1
        case "iso/iec 8859-2", "iso-8859-2":
            self = .isoLatin2
        default:
            fatalError("Not implemented yet!") // TODO: to complete!
//            return nil
        }
    }
    
    var httpHeaderValue: String {
        switch self {
        case .ascii:
            return "ascii"
        case .utf8:
            return "utf-8"
        case .isoLatin1:
            return "iso-8859-1"
        case .isoLatin2:
            return "iso-8859-2"
        default:
            fatalError("Not implemented yet!") // TODO: to complete!
        }
    }
}
