import SwiftUI

struct Typography {
    static let largeTitle = Font.custom("SF Pro Display", size: 32).weight(.medium).leading(.loose)
    static let headline = Font.custom("SF Pro Display", size: 20).weight(.regular).leading(.loose)
    static let bodyMedium = Font.custom("SF Pro Display", size: 16).weight(.medium).leading(.standard)
    static let subheadline = Font.custom("SF Pro", size: 16).weight(.semibold).leading(.tight)
    static let footnote = Font.custom("SF Pro", size: 15).weight(.regular).leading(.standard)
    static let button = Font.custom("SF Pro Display", size: 18).weight(.semibold).leading(.tight)
}

extension Font {
    func leading(_ leading: Leading) -> Font {
        switch leading {
        case .loose: return self
        case .standard: return self
        case .tight: return self
        }
    }
}

enum Leading {
    case loose
    case standard
    case tight
}
