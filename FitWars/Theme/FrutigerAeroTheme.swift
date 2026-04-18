import SwiftUI
import SpriteKit

// MARK: - AeroColors

enum AeroColors {
    // Primary palette
    static let skyBlue = Color(red: 0.53, green: 0.81, blue: 0.98)
    static let aqua = Color(red: 0.0, green: 0.80, blue: 0.82)
    static let softGreen = Color(red: 0.56, green: 0.89, blue: 0.56)
    static let pearl = Color(red: 0.97, green: 0.97, blue: 0.99)

    // Accent colors (replacing orange)
    static let primaryAccent = skyBlue
    static let secondaryAccent = aqua
    static let successGreen = softGreen
    static let warningAmber = Color(red: 1.0, green: 0.78, blue: 0.24)

    // Glass/translucency
    static let glassWhite = Color.white.opacity(0.7)
    static let glassBorder = Color.white.opacity(0.5)
    static let shineTint = Color.white.opacity(0.4)

    // Text
    static let primaryText = Color(red: 0.2, green: 0.2, blue: 0.3)
    static let secondaryText = Color(red: 0.45, green: 0.47, blue: 0.55)

    // Stat colors
    static let strengthRed = Color(red: 0.95, green: 0.35, blue: 0.35)
    static let staminaGreen = Color(red: 0.30, green: 0.78, blue: 0.40)
    static let speedBlue = Color(red: 0.30, green: 0.55, blue: 0.95)
}

// MARK: - AeroGradients

enum AeroGradients {
    static let background = LinearGradient(
        colors: [AeroColors.pearl, AeroColors.skyBlue.opacity(0.3)],
        startPoint: .bottom,
        endPoint: .top
    )

    static let buttonPrimary = LinearGradient(
        colors: [AeroColors.skyBlue, AeroColors.aqua],
        startPoint: .top,
        endPoint: .bottom
    )

    static let shine = LinearGradient(
        colors: [Color.white.opacity(0.5), Color.white.opacity(0.0)],
        startPoint: .top,
        endPoint: .center
    )

    static let card = LinearGradient(
        colors: [Color.white.opacity(0.85), Color.white.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tabBar = LinearGradient(
        colors: [Color.white.opacity(0.95), AeroColors.skyBlue.opacity(0.1)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - AeroSKColors

enum AeroSKColors {
    static let hudGlassBackground = SKColor.white.withAlphaComponent(0.15)
    static let hudGlassBorder = SKColor.white.withAlphaComponent(0.4)
    static let hudShine = SKColor.white.withAlphaComponent(0.3)
    static let healthBarBackground = SKColor.white.withAlphaComponent(0.12)
    static let meterBackground = SKColor.white.withAlphaComponent(0.1)
    static let buttonGlow = SKColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 0.4)
    static let labelColor = SKColor.white
    static let secondaryLabel = SKColor(white: 0.85, alpha: 0.9)
}

// MARK: - AeroButtonStyle

struct AeroButtonStyle: ButtonStyle {
    var gradient: LinearGradient = AeroGradients.buttonPrimary
    var cornerRadius: CGFloat = 18
    var shadowColor: Color = AeroColors.skyBlue.opacity(0.3)
    var shadowRadius: CGFloat = 8

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(gradient)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AeroGradients.shine)
                        .frame(height: 28)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowColor, radius: shadowRadius, y: 4)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - AeroCardModifier

struct AeroCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AeroColors.glassWhite)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AeroGradients.shine)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(AeroColors.glassBorder, lineWidth: 1)
                }
            )
            .shadow(color: AeroColors.skyBlue.opacity(0.12), radius: 12, y: 4)
    }
}

extension View {
    func aeroCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(AeroCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - AeroBackgroundModifier

struct AeroBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                AeroGradients.background
                    .ignoresSafeArea()
            )
    }
}

extension View {
    func aeroBackground() -> some View {
        modifier(AeroBackgroundModifier())
    }
}

// MARK: - AeroTabBarAppearance

enum AeroTabBarAppearance {
    static func configure() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        appearance.shadowColor = UIColor(AeroColors.skyBlue).withAlphaComponent(0.15)

        let selectedColor = UIColor(AeroColors.aqua)
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]

        let normalColor = UIColor(AeroColors.secondaryText)
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
