import SwiftUI

struct ColorTokens {
  static let accent = Color(hex: "#00BFFF")
  static let orange = Color(hex: "#00BFFF")
  static let labelGray = Color(hex: "#ABABAB")
  static let labelGray2 = Color(hex: "#646464")
  static let labelGray3 = Color(hex: "#202020")
}

extension Color {
  init(hex: String) {
    let scanner = Scanner(string: hex)
    _ = scanner.scanString("#")
    
    var rgbValue: UInt64 = 0
    scanner.scanHexInt64(&rgbValue)
    
    let r = Double((rgbValue >> 16) & 0xFF) / 255.0
    let g = Double((rgbValue >> 8) & 0xFF) / 255.0
    let b = Double(rgbValue & 0xFF) / 255.0
    
    self.init(red: r, green: g, blue: b)
  }
}

struct GradientStyles {
  static let gradient1 = LinearGradient(
    gradient: Gradient(colors: [
      Color(red: 0/255, green: 191/255, blue: 255/255),
      Color(red: 17/255, green: 0/255, blue: 255/255)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
  
  static let gradient2 = LinearGradient(
    gradient: Gradient(colors: [ Color(red: 1, green: 0, blue: 0.133),
                                 Color(red: 1, green: 0, blue: 0.133),
                                 Color(red: 1, green: 0.4, blue: 0),
                                 Color(red: 1, green: 0.667, blue: 0)]),
    startPoint: .leading,
    endPoint: .trailing
  )
  static let gradient3 = LinearGradient(
    gradient: Gradient(colors: [ .gray]),
    startPoint: .leading,
    endPoint: .trailing
  )
}
