//
//  LiltTheme.swift
//  viLilt
//
//  Melodic & Chromatic Design System for viLilt
//  "Talk. Listen. Nothing else."
//

import SwiftUI

public struct LiltTheme {
    public static let liltViolet = Color(red: 0.54, green: 0.33, blue: 0.98)     // #8B55FA - Acoustic Violet
    public static let liltCyan = Color(red: 0.12, green: 0.82, blue: 0.95)       // #1FD1F3 - Resonance Cyan
    public static let liltIndigo = Color(red: 0.38, green: 0.28, blue: 0.92)     // #6147EA - Deep Neural Indigo
    public static let liltRose = Color(red: 0.98, green: 0.35, blue: 0.58)       // #FA5994 - Melodic Rose
    public static let darkTitanium = Color(red: 0.06, green: 0.07, blue: 0.11)   // #0F121C - Space Black
    public static let pearl = Color(red: 0.96, green: 0.97, blue: 1.0)           // #F5F7FF - Pearl White
    public static let pureWhite = Color.white
    public static let primaryText = Color.primary
    public static let secondaryText = Color.secondary
    
    // Gradients
    public static let liltGradient = LinearGradient(
        colors: [liltViolet, liltCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let orbGradient = AngularGradient(
        colors: [liltViolet, liltRose, liltCyan, liltIndigo, liltViolet],
        center: .center
    )
    
    public static let darkBackgroundGradient = LinearGradient(
        colors: [Color(red: 0.05, green: 0.06, blue: 0.09), Color(red: 0.08, green: 0.09, blue: 0.14)],
        startPoint: .top,
        endPoint: .bottom
    )
}
