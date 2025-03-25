import SwiftUI

struct ColorTokens {
  
  static let accent = Color(hex: "#00BFFF")
  static let orange = Color(hex: "#00BFFF")

  static let gradient1Start = Color(hex: "#FF0022")
  static let gradient1End = Color(hex: "#FFAA00")
  
  static let gradient2Start = Color(hex: "#FF0022")
  static let gradient2End = Color(hex: "#FFAA00")
  
  static let gradient3Start = Color(hex: "#FF0022")
  static let gradient3End = Color(hex: "#FFAA00")
  
  static let gradient4Start = Color(hex: "#FF0022")
  static let gradient4End = Color(hex: "#FFAA00")
  
  static let loadingStart = Color(hex: "#FF0022")
  static let loadingEnd = Color(hex: "#FFAA00")
  
  static let labelWhite = Color(hex: "#FFFFFF")
  static let labelGray = Color(hex: "#ABABAB")
  static let labelGray2 = Color(hex: "#646464")
  static let labelGray3 = Color(hex: "#202020")
  static let labelGray4 = Color(hex: "#121010")
  static let labelBlack = Color(hex: "#0A0202")
  
  static let cardGradientStart = Color(hex: "#02060A").opacity(0.0)
  static let cardGradientEnd = Color(hex: "#02060A").opacity(0.8)
  
  static let backgroundScreen1Start = Color(hex: "#0A0202").opacity(0.0)
  static let backgroundScreen1End = Color(hex: "#0A0202").opacity(1.0)
  
  static let paywallDownStart = Color(hex: "#0A0202").opacity(0.0)
  static let paywallDownEnd = Color(hex: "#0A0202").opacity(1.0)
  
  static let paywallUpStart = Color(hex: "#0A0202").opacity(0.0)
  static let paywallUpEnd = Color(hex: "#0A0202").opacity(1.0)
  
  static let presetUpStart = Color(hex: "#0A0202").opacity(0.0)
  static let presetUpEnd = Color(hex: "#0A0202").opacity(1.0)
  
  static let presetDownStart = Color(hex: "#0A0202").opacity(0.0)
  static let presetDownEnd = Color(hex: "#0A0202").opacity(1.0)
  
  static let backgroundScreen45Start = Color(hex: "#0A0202").opacity(0.0)
  static let backgroundScreen45End = Color(hex: "#0A0202").opacity(1.0)
  
  static let blackout40 = Color.black.opacity(0.4)
  static let blackout30 = Color.black.opacity(0.3)
  static let blackout20 = Color.black.opacity(0.2)
  static let blackout10 = Color.black.opacity(0.1)
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
