// Encore/DesignSystem.swift
import SwiftUI

// MARK: - Design System

/// Central source of truth for spacing, sizing, corner radii, and typography.
/// Use DS.* everywhere instead of hardcoded literals.
enum DS {

    // MARK: Spacing

    enum Spacing {
        /// Horizontal page margin on all scroll views
        static let pageMargin:  CGFloat = 16
        /// Vertical gap between cards in a stack
        static let cardGap:     CGFloat = 12
        /// Inner padding on all surface cards
        static let cardPadding: CGFloat = 16
        /// Gap between a section label and its first content row
        static let sectionGap:  CGFloat = 8
    }

    // MARK: Row Heights

    enum RowHeight {
        /// Schedule set rows
        static let schedule:   CGFloat = 60
        /// Day picker pill bar
        static let dayPicker:  CGFloat = 44
    }

    // MARK: Corner Radius

    enum Radius {
        /// Surface cards
        static let card: CGFloat = 16
        /// Small chips and inline tags
        static let chip: CGFloat = 10
        /// Pills (capsule approximation when exact size unknown)
        static let pill: CGFloat = 99
    }

    // MARK: Typography

    enum Font {
        /// 36pt Black — onboarding / display
        static let display   = SwiftUI.Font.system(size: 36, weight: .black)
        /// 28pt Black — festival name hero title
        static let hero      = SwiftUI.Font.system(size: 28, weight: .black)
        /// 28pt Black — large stat numbers
        static let stat      = SwiftUI.Font.system(size: 28, weight: .black)
        /// 22pt Bold — star rating display
        static let rating    = SwiftUI.Font.system(size: 22, weight: .bold)
        /// 16pt Bold — card section titles
        static let cardTitle = SwiftUI.Font.system(size: 16, weight: .bold)
        /// 14pt Semibold — list item primary text
        static let listItem  = SwiftUI.Font.system(size: 14, weight: .semibold)
        /// 12pt Regular — metadata / secondary info
        static let metadata  = SwiftUI.Font.system(size: 12, weight: .regular)
        /// 11pt Bold — section labels and caps
        static let label     = SwiftUI.Font.system(size: 11, weight: .bold)
        /// 10pt Bold — tight caps labels
        static let caps      = SwiftUI.Font.system(size: 10, weight: .bold)
    }

    // MARK: Walk Time Severity Colors

    enum WalkSeverity {
        /// Enough time — green
        static let safe  = Color.appCTA
        /// Within 5 min of walk time — teal
        static let close = Color.appTeal
        /// Gap is less than walk time — warn orange
        static let tight = Color.appWarn
        /// No time at all — danger red
        static let over  = Color.appDanger
    }

    // MARK: Journal Colors

    enum Journal {
        static let starFilled = Color.appCTA
        static let starEmpty  = Color.appAccent.opacity(0.3)
    }
}

// MARK: - Additional Spacing

extension DS.Spacing {
    static let sectionHeaderGap: CGFloat = 20
    static let inlineGap: CGFloat = 6
}
