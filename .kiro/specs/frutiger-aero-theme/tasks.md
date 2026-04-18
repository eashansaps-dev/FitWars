# Tasks: Frutiger Aero Theme

## Task 1: Create Centralized Theme Module
> **Requirements**: 1.1, 1.2, 1.3

- [x] 1.1 Create `FitWars/Theme/FrutigerAeroTheme.swift` with `AeroColors` enum containing all color constants: `skyBlue`, `aqua`, `softGreen`, `white`, `pearl`, `primaryAccent`, `secondaryAccent`, `successGreen`, `warningAmber`, `glassWhite`, `glassBorder`, `shineTint`, `primaryText`, `secondaryText`, `strengthRed`, `staminaGreen`, `speedBlue`.
- [x] 1.2 Add `AeroGradients` enum to the theme file with `background`, `buttonPrimary`, `shine`, `card`, and `tabBar` LinearGradient definitions as specified in the design document.
- [x] 1.3 Add `AeroSKColors` enum with SpriteKit-compatible SKColor constants: `hudGlassBackground`, `hudGlassBorder`, `hudShine`, `healthBarBackground`, `meterBackground`, `buttonGlow`, `labelColor`, `secondaryLabel`.

## Task 2: Create Glossy Button Style
> **Requirements**: 2.3, 2.4, 2.5

- [x] 2.1 Create `AeroButtonStyle` conforming to `ButtonStyle` in the theme file. It should accept configurable `gradient`, `cornerRadius` (default 18), `shadowColor`, and `shadowRadius` parameters.
- [x] 2.2 Implement `makeBody()` to render: gradient-filled RoundedRectangle base → white-to-transparent shine overlay clipped to top portion → clipShape to cornerRadius → shadow with `shadowColor` at `shadowRadius` with y-offset 4 → scaleEffect 0.96 when pressed with easeInOut animation.

## Task 3: Create Glass Card Modifier
> **Requirements**: 2.2, 5.1, 5.2

- [x] 3.1 Create `AeroCardModifier` conforming to `ViewModifier` in the theme file with configurable `cornerRadius` (default 20) and `padding` (default 16).
- [x] 3.2 Implement `body()` to layer: `.ultraThinMaterial` RoundedRectangle → `glassWhite` fill RoundedRectangle → shine gradient overlay clipped to card shape → `glassBorder` stroke (lineWidth 1) → shadow(color: skyBlue.opacity(0.12), radius: 12, y: 4).
- [x] 3.3 Add `View` extension with `.aeroCard(cornerRadius:)` convenience method.

## Task 4: Create Background Modifier
> **Requirements**: 2.1

- [x] 4.1 Create `AeroBackgroundModifier` conforming to `ViewModifier` in the theme file that applies `AeroGradients.background` with `.ignoresSafeArea()`.
- [x] 4.2 Add `View` extension with `.aeroBackground()` convenience method.

## Task 5: Create Tab Bar Appearance Configuration
> **Requirements**: 3.1, 3.2

- [x] 5.1 Create `AeroTabBarAppearance` enum with a static `configure()` method that sets `UITabBarAppearance` with: opaque white background at 0.92 opacity, sky-blue shadow color at 0.15 opacity, selected item color = aqua, unselected item color = secondaryText.
- [x] 5.2 Call `AeroTabBarAppearance.configure()` in `FitWarsApp.init()` alongside `FirebaseApp.configure()`.
- [x] 5.3 Change `MainTabView` from `.tint(.orange)` to `.tint(AeroColors.aqua)`.

## Task 6: Theme SignInView
> **Requirements**: 2.1, 2.3, 6.3

- [x] 6.1 Apply `.aeroBackground()` to SignInView's root VStack.
- [x] 6.2 Change the app icon `Image(systemName:)` foreground from `.orange` to `AeroColors.primaryAccent`.
- [x] 6.3 Replace the "Sign in with Apple" button styling: use a white background with `AeroColors.glassBorder` stroke, or apply `AeroButtonStyle` with a white/dark variant.
- [x] 6.4 Update text colors to use `AeroColors.primaryText` and `AeroColors.secondaryText`.

## Task 7: Theme AvatarCustomizerView
> **Requirements**: 2.1, 2.3, 6.2, 6.3

- [x] 7.1 Apply `.aeroBackground()` to AvatarCustomizerView's root VStack.
- [x] 7.2 Replace step indicator dot fill from `.orange` to `AeroColors.primaryAccent` for active step, and `.gray.opacity(0.3)` to `AeroColors.skyBlue.opacity(0.2)` for inactive steps.
- [x] 7.3 Replace all `.orange` selection highlights in skin tone, face shape, eye style, hair style, and outfit selectors with `AeroColors.primaryAccent`.
- [x] 7.4 Apply `AeroButtonStyle` to the "Next" / "Let's Fight" button. Update the "Back" button to use `AeroColors.pearl` background with `AeroColors.primaryText` foreground.
- [x] 7.5 Replace `.orange.opacity(0.2)` option backgrounds with `AeroColors.skyBlue.opacity(0.15)`.

## Task 8: Theme DashboardView
> **Requirements**: 2.1, 2.2, 6.1

- [x] 8.1 Apply `.aeroBackground()` to DashboardView's ScrollView.
- [x] 8.2 Replace `characterCard`'s `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))` with `.aeroCard()`.
- [x] 8.3 Replace each `statBox`'s `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))` with `.aeroCard(cornerRadius: 16)`.
- [x] 8.4 Replace `todayProgress`'s `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))` with `.aeroCard()`.
- [x] 8.5 Update stat icon colors to use `AeroColors.strengthRed`, `AeroColors.staminaGreen`, `AeroColors.speedBlue`. Update XP badge backgrounds from `color.opacity(0.15)` to `color.opacity(0.12)` with `.aeroCard(cornerRadius: 12)` style.
- [x] 8.6 Update navigation title and text colors to use `AeroColors.primaryText` / `AeroColors.secondaryText`.

## Task 9: Theme BattleView
> **Requirements**: 2.1, 2.2, 2.3, 6.1, 6.3

- [x] 9.1 Apply `.aeroBackground()` to BattleView's NavigationStack content (excluding the BattleSpriteView which stays dark).
- [x] 9.2 Replace the "⚔️ FIGHT" button from `.background(.orange)` to `.buttonStyle(AeroButtonStyle())`.
- [x] 9.3 Update `miniStat` boxes from `color.opacity(0.1)` background to use `.aeroCard(cornerRadius: 12)` with the stat color as a subtle tint.
- [x] 9.4 Update difficulty picker `.pickerStyle(.segmented)` tint to use `AeroColors.primaryAccent`.
- [x] 9.5 Replace `.foregroundStyle(.secondary)` on "Quick Resolve" and "Find New Opponent" buttons with `AeroColors.secondaryText`.

## Task 10: Theme BattleResultView
> **Requirements**: 2.1, 2.2, 2.3, 6.1

- [x] 10.1 Apply `.aeroBackground()` to BattleResultView's ScrollView.
- [x] 10.2 Replace the stat breakdown section's `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))` with `.aeroCard()`.
- [x] 10.3 Replace the workout suggestions section's `.background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))` with `.aeroCard()` and change the `.orange` icon/label colors to `AeroColors.primaryAccent`.
- [x] 10.4 Replace the "Done" button from `.background(.orange)` to `.buttonStyle(AeroButtonStyle())`.
- [x] 10.5 Update victory/defeat text colors: victory stays `.green` (or `AeroColors.successGreen`), defeat stays `.red` (or `AeroColors.strengthRed`).

## Task 11: Theme ProfileView
> **Requirements**: 2.1, 6.1, 6.3

- [x] 11.1 Apply `.aeroBackground()` to ProfileView's NavigationStack/List. Consider using `.scrollContentBackground(.hidden)` on the List to allow the gradient background to show through.
- [x] 11.2 Update stat row icon colors to use `AeroColors.strengthRed`, `AeroColors.staminaGreen`, `AeroColors.speedBlue`.
- [x] 11.3 Update the "Upgrade to Apple ID" button to use `AeroColors.primaryAccent` styling instead of default system blue.

## Task 12: Theme SpriteKit HUD Overlay
> **Requirements**: 4.1, 4.2, 4.3

- [x] 12.1 Update `HealthBarNode`: change `background.fillColor` from `SKColor(white: 0.15, alpha: 0.8)` to `AeroSKColors.healthBarBackground`. Add a shine `SKShapeNode` covering the top 30% of the bar with `AeroSKColors.hudShine` fill. Update `border.strokeColor` to `AeroSKColors.hudGlassBorder`.
- [x] 12.2 Update `SpecialMeterNode`: change `background.fillColor` to `AeroSKColors.meterBackground`. Update `border.strokeColor` to `AeroSKColors.hudGlassBorder`. Add shine overlay similar to health bar.
- [x] 12.3 Verify all `SKLabelNode` instances in `HUDOverlay` (youLabel, cpuLabel, timerLabel, readyLabel, countLabel, damageLabel) use white or `AeroSKColors.labelColor` / `AeroSKColors.secondaryLabel`.

## Task 13: Theme SpriteKit Input Controls
> **Requirements**: 4.4, 4.5

- [x] 13.1 Update `InputManager.createButton()`: change `btn.fillColor` from `color.withAlphaComponent(0.6)` to `SKColor.white.withAlphaComponent(0.2)`. Change `btn.strokeColor` to `SKColor.white.withAlphaComponent(0.5)`. Set `btn.lineWidth = 1.5`. Add a shine child `SKShapeNode(circleOfRadius: radius * 0.7)` with `fillColor = SKColor.white.withAlphaComponent(0.15)` positioned at `(0, radius * 0.2)`.
- [x] 13.2 Update `VirtualJoystick`: change `base.strokeColor` to `AeroSKColors.hudGlassBorder`, `base.fillColor` to `AeroSKColors.hudGlassBackground`. Change `thumb.fillColor` to `SKColor.white.withAlphaComponent(0.35)`, `thumb.strokeColor` to `AeroSKColors.hudGlassBorder`.

## Task 14: Theme CharacterSelectionView
> **Requirements**: 2.1, 2.3, 6.3

- [x] 14.1 Apply `.aeroBackground()` to CharacterSelectionView's root VStack.
- [x] 14.2 Replace `.orange` selection highlights with `AeroColors.primaryAccent` in character option borders and icon foreground.
- [x] 14.3 Replace the "Let's Fight" button from `.background(.orange)` to `.buttonStyle(AeroButtonStyle())`.
