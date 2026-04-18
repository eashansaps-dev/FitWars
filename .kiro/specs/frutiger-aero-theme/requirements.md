# Requirements: Frutiger Aero Theme

## Requirement 1: Centralized Theme System

### Description
A centralized theme module provides all Frutiger Aero visual constants (colors, gradients, button styles, card styles, shadows) as a single source of truth, replacing the current scattered orange/dark styling.

### Acceptance Criteria
- 1.1 A `FrutigerAeroTheme.swift` file exists containing `AeroColors`, `AeroGradients`, `AeroButtonStyle`, `AeroCardModifier`, `AeroBackgroundModifier`, and `AeroTabBarAppearance`.
- 1.2 No themed SwiftUI view contains hardcoded `.orange` color references — all accent colors come from `AeroColors`.
- 1.3 `AeroGradients` provides at least: `background`, `buttonPrimary`, `shine`, `card`, and `tabBar` gradient definitions.

## Requirement 2: SwiftUI View Theming

### Description
All SwiftUI screens adopt the Frutiger Aero aesthetic with light/white backgrounds, glossy buttons, translucent glass cards, and soft shadows — replacing the current dark/flat/orange design.

### Acceptance Criteria
- 2.1 All six main screens (SignInView, AvatarCustomizerView, DashboardView, BattleView, BattleResultView, ProfileView) apply the `aeroBackground()` modifier for a pearl-to-skyBlue gradient background.
- 2.2 All content containers that previously used `.background(.ultraThinMaterial, in: RoundedRectangle(...))` now use the `.aeroCard()` modifier for glass-effect cards.
- 2.3 All primary action buttons ("FIGHT", "Let's Fight", "Done", "Next", "Sign in with Apple") use `AeroButtonStyle` for glossy rounded appearance.
- 2.4 `AeroButtonStyle` renders a gradient-filled rounded rectangle with a white-to-transparent shine overlay on the top portion and a soft colored shadow beneath.
- 2.5 Buttons styled with `AeroButtonStyle` scale to 0.96 when pressed and return to 1.0 when released, with an easeInOut animation.

## Requirement 3: Tab Bar Styling

### Description
The tab bar adopts a Wii-like glossy, floating appearance with aqua accent color replacing orange.

### Acceptance Criteria
- 3.1 `AeroTabBarAppearance.configure()` is called during app initialization (in `FitWarsApp.init()`) and `MainTabView` uses `.tint(AeroColors.aqua)` instead of `.tint(.orange)`.
- 3.2 The tab bar has a white/translucent background (white at 0.92 opacity) with a subtle sky-blue shadow.

## Requirement 4: SpriteKit HUD & Controls Theming

### Description
The SpriteKit battle scene retains its dark background for gameplay contrast, but the HUD overlay and input controls receive a complementary glossy treatment consistent with the Frutiger Aero aesthetic.

### Acceptance Criteria
- 4.1 `BattleScene.backgroundColor` remains a dark color — the battle arena is not changed to a light theme.
- 4.2 `HealthBarNode` background uses translucent white (`white.withAlphaComponent(0.12)`) and includes a shine overlay node across the top portion of the bar.
- 4.3 All `SKLabelNode` instances in `HUDOverlay` use white or near-white `fontColor` for readability against the dark background.
- 4.4 `InputManager.createButton()` uses translucent white fills (`white.withAlphaComponent(0.2)`) with white borders and adds a shine child `SKShapeNode` to each button.
- 4.5 `VirtualJoystick` base and thumb nodes use translucent white styling consistent with `AeroSKColors`.

## Requirement 5: Visual Consistency Rules

### Description
Consistent corner radii, shadows, and spacing are enforced across all themed elements to maintain the cohesive bubbly Frutiger Aero feel.

### Acceptance Criteria
- 5.1 `AeroCardModifier` defaults to `cornerRadius = 20` and `AeroButtonStyle` defaults to `cornerRadius = 18`.
- 5.2 `AeroCardModifier` applies a shadow with color `skyBlue.opacity(0.12)`, radius `12`, and y-offset `4`.
- 5.3 All `RoundedRectangle` corner radius values in themed views are >= 8 (no sharp corners).

## Requirement 6: Accent Color Migration

### Description
All orange accent colors throughout the app are replaced with the Frutiger Aero palette (aqua, sky blue, soft green) while preserving stat-specific colors (red/green/blue) for game identity.

### Acceptance Criteria
- 6.1 Stat display colors (strength=red, stamina=green, speed=blue) are preserved using `AeroColors.strengthRed`, `AeroColors.staminaGreen`, and `AeroColors.speedBlue`.
- 6.2 Step indicators in `AvatarCustomizerView` use `AeroColors.primaryAccent` (sky blue) instead of `.orange` for the active step dot.
- 6.3 All selection highlights (avatar options, character selection, hair style pills) use `AeroColors.primaryAccent` or `AeroColors.secondaryAccent` instead of `.orange`.
