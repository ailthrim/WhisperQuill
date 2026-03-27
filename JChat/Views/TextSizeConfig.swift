//
//  TextSizeConfig.swift
//  JChat
//
//  Text scaling infrastructure for macOS. Because SwiftUI's .dynamicTypeSize()
//  modifier does not actually change rendered font sizes on macOS, we use a manual
//  scale-factor approach: DynamicTypeSize steps map to a CGFloat multiplier that
//  flows through the environment, and .appFont() applies it at each call site.
//
//  Cmd+/- stepping and persistence still use DynamicTypeSize — it provides clean
//  enum cases, ordered stepping, and string-based persistence. We just map the
//  final result to a scale factor instead of feeding it to .dynamicTypeSize().

import SwiftUI

// MARK: - Zoom action

/// The three things Cmd+/-, Cmd+0 can do.
enum TextZoomAction {
    case increase, decrease, reset
}

// MARK: - Text scale environment key

/// Scale factor that .appFont() reads. 1.0 = default size (.large step).
/// Set on the root view by ContentView based on the user's Cmd+/- zoom level.
private struct TextScaleFactorKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var textScaleFactor: CGFloat {
        get { self[TextScaleFactorKey.self] }
        set { self[TextScaleFactorKey.self] = newValue }
    }
}

// MARK: - Semantic text styles with base point sizes

/// Base point sizes for each semantic text role at scale 1.0.
/// Tuned for Josh's 13.6" Retina MacBook Air (effective 1470×956).
/// Body = 14pt, secondary = 13pt, absolute floor = 12pt.
enum AppTextStyle {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    case caption2

    /// The unscaled point size for this style.
    var basePointSize: CGFloat {
        switch self {
        case .largeTitle:   return 28
        case .title:        return 22
        case .title2:       return 18
        case .title3:       return 16
        case .headline:     return 15
        case .body:         return 14
        case .callout:      return 13.5
        case .subheadline:  return 13
        case .footnote:     return 12.5
        case .caption:      return 12
        case .caption2:     return 12
        }
    }

    /// Absolute minimum rendered size — nothing goes below this.
    static let minimumPointSize: CGFloat = 12
}

// MARK: - Scaled font view modifier

/// Applies a font sized to `basePointSize * textScaleFactor`, floored at 12pt.
/// Use via the `.appFont()` view extension instead of calling directly.
private struct ScaledFontModifier: ViewModifier {
    let style: AppTextStyle
    let design: Font.Design
    let weight: Font.Weight

    @Environment(\.textScaleFactor) private var scaleFactor

    func body(content: Content) -> some View {
        let size = max(style.basePointSize * scaleFactor, AppTextStyle.minimumPointSize)
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    /// Scaled font that responds to Cmd+/- zoom. Drop-in replacement for .font().
    func appFont(
        _ style: AppTextStyle,
        design: Font.Design = .default,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(ScaledFontModifier(style: style, design: design, weight: weight))
    }
}

// MARK: - DynamicTypeSize stepping, persistence & scale factor

extension DynamicTypeSize {

    /// Available sizes for Cmd+/- stepping, smallest to largest.
    /// Starts at .small (not .xSmall) to keep the smallest text above ~12pt.
    static let steppableSizes: [DynamicTypeSize] = [
        .small, .medium, .large,
        .xLarge, .xxLarge, .xxxLarge,
        .accessibility1, .accessibility2, .accessibility3,
    ]

    /// The multiplier this step applies to base font sizes.
    /// .large = 1.0 (default). Steps below shrink, steps above enlarge.
    var scaleFactor: CGFloat {
        switch self {
        case .small:           return 0.85
        case .medium:          return 0.925
        case .large:           return 1.0
        case .xLarge:          return 1.1
        case .xxLarge:         return 1.2
        case .xxxLarge:        return 1.35
        case .accessibility1:  return 1.5
        case .accessibility2:  return 1.7
        case .accessibility3:  return 1.9
        default:               return 1.0
        }
    }

    /// String key for storing in AppSettings (SwiftData).
    var persistenceKey: String {
        switch self {
        case .xSmall:          return "xSmall"
        case .small:           return "small"
        case .medium:          return "medium"
        case .large:           return "large"
        case .xLarge:          return "xLarge"
        case .xxLarge:         return "xxLarge"
        case .xxxLarge:        return "xxxLarge"
        case .accessibility1:  return "accessibility1"
        case .accessibility2:  return "accessibility2"
        case .accessibility3:  return "accessibility3"
        case .accessibility4:  return "accessibility4"
        case .accessibility5:  return "accessibility5"
        @unknown default:      return "large"
        }
    }

    /// Restore from a stored persistence key. Returns nil for unknown strings.
    static func from(persistenceKey: String) -> DynamicTypeSize? {
        steppableSizes.first { $0.persistenceKey == persistenceKey }
    }

    /// One step larger. Returns nil if already at the biggest steppable size.
    func steppedUp() -> DynamicTypeSize? {
        guard let idx = Self.steppableSizes.firstIndex(of: self),
              idx + 1 < Self.steppableSizes.count else { return nil }
        return Self.steppableSizes[idx + 1]
    }

    /// One step smaller. Returns nil if already at the smallest steppable size.
    func steppedDown() -> DynamicTypeSize? {
        guard let idx = Self.steppableSizes.firstIndex(of: self),
              idx > 0 else { return nil }
        return Self.steppableSizes[idx - 1]
    }

    /// The "home" size — what Cmd+0 resets to.
    static let defaultSize: DynamicTypeSize = .large
}
