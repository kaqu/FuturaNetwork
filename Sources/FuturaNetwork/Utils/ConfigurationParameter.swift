import Foundation

public enum ConfigurationParameter<T> {
    case inherit
    case override(with: T)
    case merge(with: T, merge: (T,T)->T)
}

public extension ConfigurationParameter {
    
    func resolve(with config: T) -> T {
        switch self {
        case .inherit:
            return config
        case let .override(value):
            return value
        case let .merge(value, merge):
            return merge(config, value)
        }
    }
}
