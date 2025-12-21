//
//  Color+Hex.swift
//  fotoX
//
//  Extension for creating SwiftUI Colors from hex strings
//

import SwiftUI

extension Color {
    /// Creates a Color from a hex string (e.g., "#FF4081" or "FF4081")
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let length = hexSanitized.count
        
        switch length {
        case 6: // RGB (e.g., FF4081)
            let r = Double((rgb & 0xFF0000) >> 16) / 255.0
            let g = Double((rgb & 0x00FF00) >> 8) / 255.0
            let b = Double(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
            
        case 8: // ARGB (e.g., FFFF4081)
            let a = Double((rgb & 0xFF000000) >> 24) / 255.0
            let r = Double((rgb & 0x00FF0000) >> 16) / 255.0
            let g = Double((rgb & 0x0000FF00) >> 8) / 255.0
            let b = Double(rgb & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
            
        default:
            return nil
        }
    }
    
    /// Returns the hex string representation of the color
    func toHex(includeAlpha: Bool = false) -> String? {
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }
        
        let r = Int(components[0] * 255.0)
        let g = Int(components.count > 1 ? components[1] * 255.0 : components[0] * 255.0)
        let b = Int(components.count > 2 ? components[2] * 255.0 : components[0] * 255.0)
        let a = Int(components.count > 3 ? components[3] * 255.0 : 1.0 * 255.0)
        
        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", a, r, g, b)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}

