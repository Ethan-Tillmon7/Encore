import SwiftUI

// MARK: - SwiftUI Color tokens

extension Color {
    static let appBackground  = Color(uiColor: .appBackground)
    static let appSurface     = Color(uiColor: .appSurface)
    static let appAccent      = Color(uiColor: .appAccent)
    static let appCTA         = Color(uiColor: .appCTA)
    static let appTeal        = Color(uiColor: .appTeal)
    static let appTextPrimary = Color(uiColor: .appTextPrimary)
    static let appTextMuted   = Color(uiColor: .appTextMuted)
}

// MARK: - UIColor adaptive tokens

extension UIColor {
    static let appBackground = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(appHex: "1C2522") : UIColor(appHex: "FAFDE6")
    }
    static let appSurface = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(appHex: "2A332F") : UIColor(appHex: "FFFFF0")
    }
    static let appAccent      = UIColor(appHex: "A8BFB2")
    static let appCTA         = UIColor(appHex: "E8F7D0")
    static let appTeal        = UIColor(appHex: "D4ECEC")
    static let appTextPrimary = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(appHex: "EAEAEF") : UIColor(appHex: "202030")
    }
    static let appTextMuted   = UIColor(appHex: "A8BFB2")

    convenience init(appHex: String) {
        var hex = appHex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard hex.count == 6, let val = UInt64(hex, radix: 16) else {
            assertionFailure("Invalid hex color: \(appHex)")
            self.init(red: 0, green: 0, blue: 0, alpha: 1)
            return
        }
        let r = CGFloat((val & 0xFF0000) >> 16) / 255
        let g = CGFloat((val & 0x00FF00) >> 8)  / 255
        let b = CGFloat(val & 0x0000FF)          / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
