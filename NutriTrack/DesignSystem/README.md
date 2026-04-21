# NutriTrack — Design System

Source de vérité pour l'UI de NutriTrack (macOS/iOS). Toute nouvelle vue doit
utiliser ces composants et tokens. Les vues existantes ont été migrées en
phases 1-4 ; cette phase 5 (polish) a éliminé les résidus hors cas justifiés.

## Règles d'usage

1. **Typographie** : utiliser `Font.nutri*` uniquement. `.font(.system(size:))`
   est interdit sauf pour :
   - icônes hero (taille ≥ 40)
   - micro-labels de data viz (< 11pt)
   - calibrages visuels spécifiques (ex : chiffre central d'un ring)
   Dans ces trois cas, ajouter un commentaire de justification inline.

2. **Champs de saisie** : `TextField`, `SecureField`, `TextEditor` natifs sont
   interdits en dehors de `NutriField.swift`. Utiliser `NutriField` avec la
   variante adaptée (`.text`, `.secure`, `.multiline`, `.number`, `.decimal`,
   `.email`). Exceptions historiques justifiées : formulaires custom inline
   dans `OnboardingView` et les sections `Profile/*` qui utilisent des
   bindings numériques via `value:` + format, dans une structure `identiteRow`/
   `profileRow` trailing-aligned.

3. **Paddings** : utiliser les tokens `Spacing.*`. `.padding(N)` avec un
   entier brut est interdit. `.padding()` sans argument (défaut SwiftUI)
   reste autorisé.

4. **Sheets** : préférer `.nutriSheet(title:size:isPresented:)`. Les
   `.sheet(...)` natifs ne sont autorisés que pour les vues complexes avec
   NavigationStack propre ou contenu à layout très spécifique
   (ex : `AddFoodView`, `ComparePhotosView`, action sheets d'édition).

5. **Dialogues de confirmation** : `.confirmationDialog` est interdit.
   Utiliser `.nutriConfirm(title:message:destructive:...)`.

6. **Steppers** : préférer `NutriStepper`. Le `Stepper` natif est toléré
   dans les formulaires custom où le layout trailing-compact est imposé
   par la structure (`OnboardingView`, `Profile/*`).

7. **Pickers** : préférer `NutriPicker` (auto-switch segmented/menu selon
   le nombre d'options). Le `Picker` natif reste toléré dans les toolbar
   et les formulaires inline profile où `.labelsHidden().frame(width:)`
   est utilisé pour garder la compacité.

8. **Frames sémantiques** : les largeurs de sheet/sidebar/content utilisent
   `NutriLayout.*`. Les frames pour icônes et éléments visuels (avatars,
   cercles de score) peuvent garder des valeurs explicites.

## Composants

| Fichier | Rôle |
|---|---|
| `Components/NutriButton.swift` | Bouton standard (primary / secondary / tertiary / destructive, 3 tailles). |
| `Components/NutriConfirm.swift` | Modifier `.nutriConfirm` — remplace `.confirmationDialog`. |
| `Components/NutriDatePicker.swift` | Picker de date avec style `.inline` ou `.calendar`, label dessus. |
| `Components/NutriField.swift` | Champ de saisie unique (text / secure / multiline / number / decimal / email). |
| `Components/NutriPicker.swift` | Picker avec auto-switch segmented (≤3 options) / menu (≥4). |
| `Components/NutriSectionHeader.swift` | En-tête de section uppercased avec icône et trailing optionnel. |
| `Components/NutriSlider.swift` | Slider 1-10 pour scores Wellness. |
| `Components/NutriStepper.swift` | Stepper avec boutons +/- stylés et affichage central. |
| `Components/NutriToast.swift` | Toast de feedback (success / error / info / warning). |
| `Modifiers/NutriFieldStyle.swift` | Modifier `.nutriFieldStyle(...)` — background + border focus/error. |
| `Modifiers/NutriSheetStyle.swift` | Modifier `.nutriSheet(title:size:isPresented:)` + `NutriSheetSize`. |

## Tokens

### Couleurs — `Tokens/Colors.swift` + `Utilities/Constants.swift`
- **Marque** : `Color.nutriGreen`, `Color.nutriGreenDark`
- **Macros** : `Color.proteineColor`, `Color.glucideColor`, `Color.lipideColor`
- **Alerte** : `Color.alerteOrange`
- **Surface** : `Color.nutriSurface`, `nutriSurfaceFocus`, `nutriSurfaceError`, `nutriSurfaceDisabled`
- **Bordures** : `Color.nutriBorder`, `nutriBorderFocus`, `nutriBorderError`
- **Texte** : `Color.nutriTextPrimary`, `nutriTextSecondary`, `nutriTextTertiary`
- **Feedback** : `Color.nutriSuccess`, `nutriWarning`, `nutriError`, `nutriInfo`
- **Élévation** : `Color.nutriElevatedSurface`

### Typographie — `Tokens/Typography.swift` + `Utilities/Constants.swift`
| Token | Taille | Usage |
|---|---|---|
| `.nutriLargeTitle` | 34pt bold rounded | Titres de grande page |
| `.nutriTitle` | 28pt semibold rounded | Titres principaux |
| `.nutriTitle2` | 22pt semibold rounded | Titres de cards |
| `.nutriTitle3` | 18pt semibold rounded | Sections dans cards |
| `.nutriHeadline` | 17pt rounded | Valeurs emphatiques |
| `.nutriBody` | 14pt rounded | Corps de texte standard |
| `.nutriBodyBold` | 14pt semibold rounded | Emphase inline |
| `.nutriCaption` | 12pt rounded | Légendes, labels |
| `.nutriCaption2` | 11pt rounded | Mentions, footers |
| `.nutriMonoBody` | 14pt monospace | Chiffres alignés (poids, calories) |

### Espacement — `enum Spacing`
- `xxs` = 2, `xs` = 4, `sm` = 8, `md` = 16, `lg` = 24, `xl` = 32, `xxl` = 48

### Radius — `enum Radius`
- `sm` = 8, `md` = 12, `lg` = 16, `xl` = 24

### Élévations — `Tokens/Shadows.swift`
- `NutriShadow.soft` — cards au repos
- `NutriShadow.medium` — éléments actifs (focus, hover)
- `NutriShadow.elevated` — modales, popovers
- Modifier : `.nutriShadow(_:)`

### Layout — `Tokens/Layout.swift`
- **Navigation** : `sidebarWidth`, `sidebarMinWidth`, `sidebarMaxWidth`
- **Contenu** : `contentMinWidth`, `contentIdealWidth`
- **Cards** : `cardMinWidth`, `cardMaxWidth`, `dashboardLeftColumn`
- **Sheets** : `sheetCompactWidth/Height`, `sheetStandardWidth/Height`, `sheetLargeWidth/Height`
- **Boutons** : `buttonSmall` (28), `buttonRegular` (36), `buttonLarge` (44)
- **Champs** : `fieldHeight`, `fieldMultilineMinHeight`, `fieldMultilineMaxHeight`
- **Icônes** : `iconSmall` (14), `iconRegular` (18), `iconLarge` (24), `iconXL` (32)

`NutriSheetSize` : `.compact` / `.standard` / `.large` (dérive les
dimensions depuis `NutriLayout`).
