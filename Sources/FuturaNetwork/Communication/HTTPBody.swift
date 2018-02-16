import Foundation

public enum HTTPBody {
    case empty
    case undefined(Data)
    case plain(Data, encoding: String.Encoding)
    case json(Data, encoding: String.Encoding)
    case xml(Data, encoding: String.Encoding)
    case urlEncoded(Data, encoding: String.Encoding)
    case imageJPEG(Data)
    case imagePNG(Data)
    case pdf(Data)
    case html(Data, encoding: String.Encoding)
}

public extension HTTPBody {
    
    init(with data: Data?, contentType: HTTPHeader.ContentType? = nil) {
        guard let data = data else {
            self = .empty
            return
        }
        
        guard let contentType = contentType else {
            self = .undefined(data)
            return
        }
        
        switch contentType {
        case let .plain(encoding):
            self = .plain(data, encoding: encoding)
        case let .html(encoding):
            self = .html(data, encoding: encoding)
        case .imageJPEG:
            self = .imageJPEG(data)
        case .imagePNG:
            self = .imagePNG(data)
        case .pdf:
            self = .pdf(data)
        case let .json(encoding):
            self = .json(data, encoding: encoding)
        case let .xml(encoding):
            self = .xml(data, encoding: encoding)
        case let .formURLEncoded(encoding):
            self = .urlEncoded(data, encoding: encoding)
        case .undefined:
            self = .undefined(data)
        }
    }
}

public extension HTTPBody {
    
    var data: Data? {
        switch self {
        case .empty:
            return nil
        case let .undefined(data):
            return data
        case let .plain(data, _):
            return data
        case let .json(data, _):
            return data
        case let .xml(data, _):
            return data
        case let .urlEncoded(data, _):
            return data
        case let .imageJPEG(data):
            return data
        case let .imagePNG(data):
            return data
        case let .pdf(data):
            return data
        case let .html(data, _):
            return data
        }
    }
    
    var headers: HTTPHeaders {
        switch self {
        case .empty:
            return [:]
        case .undefined:
            return [.contentType(.undefined)].headersDictionary
        case let .plain(_, encoding):
            return [.contentType(.plain(encoding: encoding))].headersDictionary
        case let .json(_, encoding):
            return [.contentType(.json(encoding: encoding))].headersDictionary
        case let .xml(_, encoding):
            return [.contentType(.xml(encoding: encoding))].headersDictionary
        case let .urlEncoded(_, encoding):
            return [.contentType(.formURLEncoded(encoding: encoding))].headersDictionary
        case .imageJPEG:
            return [.contentType(.imageJPEG)].headersDictionary
        case .imagePNG:
            return [.contentType(.imagePNG)].headersDictionary
        case .pdf:
            return [.contentType(.pdf)].headersDictionary
        case let .html(_, encoding):
            return [.contentType(.html(encoding: encoding))].headersDictionary
        }
    }
}
