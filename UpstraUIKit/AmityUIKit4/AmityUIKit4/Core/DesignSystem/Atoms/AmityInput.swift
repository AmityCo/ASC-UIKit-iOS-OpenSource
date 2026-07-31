//
//  AmityInput.swift
//  AmityUIKit4
//
//  Design-system ATOM — text-field family (Boxed / Text / Chip / User).
//  Spec: cleverden front-end-tech-specs/UIKIT/atoms/Input/v1.md
//  Decomposition: docs/superpowers/specs/2026-07-13-atomic-components-decomposition.md
//
//  Conventions (same as AmityToggle, the C1 pattern-setter):
//   • Colours resolve through `viewConfig.color(_:)` (page/component-scoped theme). Never hardcoded.
//   • Icons come from `AmityIcon.DesignSystem` (template-rendered, tinted by an Icon/* token).
//   • A required `variant` discriminator selects the sub-type / bound token family.
//   • Additive — this is a NEW atom; it does not touch `InfoTextField` / `AmityTextEditorView`,
//     which stay owned by Social.
//
//  Input is interactive, so unlike Toggle it owns a live `TextField` + `@FocusState`. The consumer
//  owns the text via a `Binding`; focus (caret) is managed internally by the native field, while the
//  `state` prop still lets a consumer force Focused/Disabled/Error (e.g. validation) per the spec.
//
//  Token grammar bound here (59 total across the family):
//   • Boxed  — `{Surface,Border}/Input/BoxedInput/{Default|Error}` hosting a nested Text Input's
//              icon/placeholder/cursor/count tokens (it has no content tokens of its own).
//   • Text   — `{Icon,Line,Text}/Input/TextInput/{Part}/{State}` incl. the full 12-cell Placeholder
//              `{state}[-{modifier}]` matrix.
//   • Chip   — `{Icon,Line,Text}/Input/ChipInput/{Part}/{State}` (no Focused, no Placeholder modifier).
//   • User   — `Text/Input/UserInput/{Part}/{Default|Disabled}` (text-role only).
//
//  NOTE on the flagged typo: the spec warns `Text/Input/TextInput/Placeholder/Error-Higlight` may be
//  authored misspelled. In the *generated* Swift the case is spelled correctly
//  (`textInputTextInputPlaceholderErrorHighlight` = "Text/Input/TextInput/Placeholder/Error-Highlight");
//  we bind whatever the generator produced, verbatim.
//
//  Requires iOS 15 (`@FocusState`, `.focused`, `.onSubmit`, `.tint`). The project targets iOS 14, so —
//  following the same pattern as `TextFieldFocused` in CustomViewModifiers.swift — the whole atom is
//  gated with `@available(iOS 15.0, *)`.
//

import SwiftUI

// MARK: - Public API types

/// Which Input sub-type to render — selects the bound token family (see the file header / spec grammar).
enum InputVariantEnum {
    case boxed   // BoxedInput — filled pill container hosting a nested Text Input (search bars, compose bar)
    case text    // TextInput — standalone underlined field (title + input row + hint)
    case chip    // ChipInput — multi-value tag/chip field (partial: simplified layout)
    case user    // UserInput — per-row member-picker control (text-role only)
}

/// Default / Focused / Disabled / Error — selects the bound token state. `focused` applies to
/// `boxed`/`text` only; `chip` has no Focused; `user` supports only `default`/`disabled`.
enum InputStateEnum {
    case `default`
    case focused
    case disabled
    case error
}

/// Chip row layout (partial — both currently render as a single scrolling row; see NOTE on `chipBody`).
enum ChipLayoutEnum {
    case wrap
    case overflow
}

/// A committed chip inside a Chip Input field.
struct AmityInputChip: Identifiable, Equatable {
    let id: String
    let label: String   // Text/Input/ChipInput/Title/{state}
    var disabled: Bool

    init(id: String, label: String, disabled: Bool = false) {
        self.id = id
        self.label = label
        self.disabled = disabled
    }
}

/// Row content for the User Input member-picker control. Binary Default/Disabled only.
struct AmityInputUserData: Identifiable {
    let userId: String
    let title: String            // Text/Input/UserInput/Title/{state}
    var username: String?        // Text/Input/UserInput/UserName/{state}
    var description: String?     // Text/Input/UserInput/TextDescription/{state}
    var actionLabel: String?     // Text/Input/UserInput/Action/{state}
    var disabled: Bool

    var id: String { userId }

    init(userId: String,
         title: String,
         username: String? = nil,
         description: String? = nil,
         actionLabel: String? = nil,
         disabled: Bool = false) {
        self.userId = userId
        self.title = title
        self.username = username
        self.description = description
        self.actionLabel = actionLabel
        self.disabled = disabled
    }
}

// MARK: - Atom

/// Design-system text-field atom.
///
///     AmityInput(variant: .boxed,
///                text: $viewModel.query,
///                placeholder: "Search",
///                leadingIcon: .searchR,
///                viewConfig: viewConfig,
///                onSubmit: { viewModel.search($0) })
@available(iOS 15.0, *)
struct AmityInput: View {

    // Required
    private let variant: InputVariantEnum

    // Controlled value
    @Binding private var text: String

    // Content
    private let placeholder: String?
    private let title: String?
    private let hintText: String?
    private let description: String?
    private let username: String?
    private let actionLabel: String?
    private let leadingIcon: AmityIcon.DesignSystem?
    private let trailingIcon: AmityIcon.DesignSystem?
    private let showCharacterCount: Bool
    private let maxLength: Int?
    private let chips: [AmityInputChip]
    private let chipLayout: ChipLayoutEnum
    private let user: AmityInputUserData?
    private let state: InputStateEnum
    private let highlightMatch: Bool
    private let multiline: Bool

    private let viewConfig: AmityViewConfigController

    // Callbacks
    private let onChangeText: ((String) -> Void)?
    private let onChipsChange: (([AmityInputChip]) -> Void)?
    private let onFocus: (() -> Void)?
    private let onBlur: (() -> Void)?
    private let onSubmit: ((String) -> Void)?
    private let onActionClick: ((AmityInputUserData) -> Void)?

    @FocusState private var isFocused: Bool

    // Geometry (from the spec's Geometry section)
    private let boxedRadius: CGFloat = 28    // r99 authored ⇒ ≥ H/2 ⇒ full pill (H=56)
    private let boxedHeight: CGFloat = 56
    private let iconSize: CGFloat = 20
    private let chipRemoveIconSize: CGFloat = 12

    init(variant: InputVariantEnum,
         text: Binding<String> = .constant(""),
         placeholder: String? = nil,
         title: String? = nil,
         hintText: String? = nil,
         description: String? = nil,
         username: String? = nil,
         actionLabel: String? = nil,
         leadingIcon: AmityIcon.DesignSystem? = nil,
         trailingIcon: AmityIcon.DesignSystem? = nil,
         showCharacterCount: Bool = false,
         maxLength: Int? = nil,
         chips: [AmityInputChip] = [],
         chipLayout: ChipLayoutEnum = .wrap,
         user: AmityInputUserData? = nil,
         state: InputStateEnum = .default,
         highlightMatch: Bool = false,
         multiline: Bool = false,
         viewConfig: AmityViewConfigController,
         onChangeText: ((String) -> Void)? = nil,
         onChipsChange: (([AmityInputChip]) -> Void)? = nil,
         onFocus: (() -> Void)? = nil,
         onBlur: (() -> Void)? = nil,
         onSubmit: ((String) -> Void)? = nil,
         onActionClick: ((AmityInputUserData) -> Void)? = nil) {
        self.variant = variant
        self._text = text
        self.placeholder = placeholder
        self.title = title
        self.hintText = hintText
        self.description = description
        self.username = username
        self.actionLabel = actionLabel
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.showCharacterCount = showCharacterCount
        self.maxLength = maxLength
        self.chips = chips
        self.chipLayout = chipLayout
        self.user = user
        self.state = state
        self.highlightMatch = highlightMatch
        self.multiline = multiline
        self.viewConfig = viewConfig
        self.onChangeText = onChangeText
        self.onChipsChange = onChipsChange
        self.onFocus = onFocus
        self.onBlur = onBlur
        self.onSubmit = onSubmit
        self.onActionClick = onActionClick
    }

    var body: some View {
        switch variant {
        case .boxed: boxedBody
        case .text:  textBody
        case .chip:  chipBody
        case .user:  userBody
        }
    }

    // MARK: - Boxed (filled pill hosting a nested Text Input)

    private var boxedBody: some View {
        HStack(spacing: 12) {
            leadingIconView(token: textIconToken)
            textValueField()
            trailingIconView(token: textIconToken)
            if showCharacterCount {
                characterCount(token: .textInputTextInputTextCountDefault)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(minHeight: boxedHeight)
        // Surface binds Default only — invariant regardless of interaction state (spec).
        .background(
            RoundedRectangle(cornerRadius: boxedRadius)
                .fill(Color(viewConfig.color(.surfaceInputBoxedInputDefault)))
        )
        // Border binds Error only — paints solely in the error state; otherwise borderless.
        .overlay {
            if effectiveState == .error {
                RoundedRectangle(cornerRadius: boxedRadius)
                    .strokeBorder(Color(viewConfig.color(.borderInputBoxedInputError)), lineWidth: 1)
            }
        }
    }

    // MARK: - Text (standalone underlined field)

    private var textBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title, !title.isEmpty {
                Text(title)
                    .applyTextStyle(.caption(Color(viewConfig.color(.textInputTextInputTitleDefault))))
            }

            HStack(spacing: 8) {
                leadingIconView(token: textIconToken)
                textValueField()
                trailingIconView(token: textIconToken)
                if showCharacterCount {
                    characterCount(token: .textInputTextInputTextCountDefault)
                }
            }

            Rectangle()
                .fill(Color(viewConfig.color(textUnderlineToken)))
                .frame(height: 1)

            if let hintText, !hintText.isEmpty {
                Text(hintText)
                    .applyTextStyle(.caption(Color(viewConfig.color(textHintToken))))
            }

            if let description, !description.isEmpty {
                Text(description)
                    .applyTextStyle(.caption(Color(viewConfig.color(.textInputTextInputTextDescriptionDefault))))
            }
        }
    }

    /// The core value field shared by Boxed + Text. The placeholder is drawn as a separate overlay so
    /// its colour can be token-driven; the live `TextField` sits on top with the value-text token.
    @ViewBuilder
    private func textValueField() -> some View {
        ZStack(alignment: .leading) {
            if text.isEmpty, let placeholder, !placeholder.isEmpty {
                // Empty ⇒ bare Placeholder token (no `-Filled` modifier).
                Text(placeholder)
                    .applyTextStyle(.body(Color(viewConfig.color(textPlaceholderToken(filled: false)))))
                    .allowsHitTesting(false)
                    .lineLimit(1)
            }

            // Non-empty value ⇒ the `-Filled` Placeholder modifier (spec: same token colours value text).
            // The text style is applied inside `coreTextField` where the receiver is a concrete
            // `TextField` (the `applyTextStyle` extensions exist on Text/TextField/TextEditor, not View).
            coreTextField(style: .body(Color(viewConfig.color(textPlaceholderToken(filled: true)))))
                .tint(Color(viewConfig.color(.textInputTextInputTextCursorDefault)))
                .focused($isFocused)
                .disabled(effectiveState == .disabled)
                .onChange(of: text) { newValue in
                    if let maxLength, newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                    onChangeText?(text)
                }
                .onChange(of: isFocused) { focused in
                    if focused { onFocus?() } else { onBlur?() }
                }
                .onSubmit { onSubmit?(text) }
        }
    }

    /// A plain single-line field, or (Boxed + `multiline`, iOS 16+) a growing vertical field.
    /// `applyTextStyle` is applied here on the concrete `TextField` (the extension is not on `View`).
    @ViewBuilder
    private func coreTextField(style: AmityTextStyle) -> some View {
        if #available(iOS 16.0, *), variant == .boxed, multiline {
            TextField("", text: $text, axis: .vertical)
                .applyTextStyle(style)
                .lineLimit(1...3)
        } else {
            TextField("", text: $text)
                .applyTextStyle(style)
                .lineLimit(1)
        }
    }

    // MARK: - Chip (PARTIAL — simplified single-row layout)

    // NOTE: Chip Input exposes Text/Icon/Line roles only — no Surface/Border token for the chip
    // container itself. Rather than borrow another sub-type's Surface token (drift), each chip is drawn
    // as a capsule *outline* tinted with the Chip Icon token. Both `chipLayout` cases render as one
    // horizontally-scrolling row (true `wrap`/`overflow` flow needs iOS 16 `Layout` and is deferred).
    private var chipBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title, !title.isEmpty {
                Text(title)
                    .applyTextStyle(.caption(Color(viewConfig.color(chipTitleToken(disabled: false)))))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips) { chip in
                        chipView(chip)
                    }
                    chipEntryField()
                    if showCharacterCount {
                        characterCount(token: .textInputChipInputTextCountDefault)
                    }
                }
            }

            Rectangle()
                .fill(Color(viewConfig.color(chipUnderlineToken)))
                .frame(height: 1)

            if let hintText, !hintText.isEmpty {
                Text(hintText)
                    .applyTextStyle(.caption(Color(viewConfig.color(chipHintToken))))
            }

            if let description, !description.isEmpty {
                Text(description)
                    .applyTextStyle(.caption(Color(viewConfig.color(chipDescriptionToken))))
            }
        }
    }

    private func chipView(_ chip: AmityInputChip) -> some View {
        let disabled = chip.disabled || chipState == .disabled
        return HStack(spacing: 4) {
            Text(chip.label)
                .applyTextStyle(.caption(Color(viewConfig.color(chipTitleToken(disabled: disabled)))))
                .lineLimit(1)
            Button {
                var updated = chips
                updated.removeAll { $0.id == chip.id }
                onChipsChange?(updated)
            } label: {
                Image((trailingIcon ?? .crossS).imageResource)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: chipRemoveIconSize, height: chipRemoveIconSize)
                    .foregroundColor(Color(viewConfig.color(chipIconToken)))
            }
            .disabled(disabled)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .overlay(
            Capsule()
                .strokeBorder(Color(viewConfig.color(chipIconToken)), lineWidth: 1)
        )
    }

    private func chipEntryField() -> some View {
        ZStack(alignment: .leading) {
            if text.isEmpty, let placeholder, !placeholder.isEmpty {
                Text(placeholder)
                    .applyTextStyle(.body(Color(viewConfig.color(chipPlaceholderToken))))
                    .allowsHitTesting(false)
                    .lineLimit(1)
            }
            // Chip Placeholder has no `-Filled` modifier, so value + placeholder share one token.
            TextField("", text: $text)
                .applyTextStyle(.body(Color(viewConfig.color(chipPlaceholderToken))))
                .tint(Color(viewConfig.color(.textInputChipInputTextCursorDefault)))
                .focused($isFocused)
                .disabled(chipState == .disabled)
                .frame(minWidth: 60)
                .lineLimit(1)
                .onChange(of: text) { newValue in
                    if let maxLength, newValue.count > maxLength {
                        text = String(newValue.prefix(maxLength))
                    }
                    onChangeText?(text)
                }
                .onChange(of: isFocused) { focused in
                    if focused { onFocus?() } else { onBlur?() }
                }
                .onSubmit {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        let updated = chips + [AmityInputChip(id: UUID().uuidString, label: trimmed)]
                        onChipsChange?(updated)
                        text = ""
                    }
                    onSubmit?(trimmed)
                }
        }
    }

    // MARK: - User (member-row control)

    private var userBody: some View {
        let disabled = userDisabled
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if let titleText = user?.title ?? title, !titleText.isEmpty {
                    Text(titleText)
                        .applyTextStyle(.bodyBold(Color(viewConfig.color(userTitleToken))))
                        .lineLimit(1)
                }
                if let usernameText = user?.username ?? username, !usernameText.isEmpty {
                    Text(usernameText)
                        .applyTextStyle(.caption(Color(viewConfig.color(userUsernameToken))))
                        .lineLimit(1)
                }
                if let descriptionText = user?.description ?? description, !descriptionText.isEmpty {
                    Text(descriptionText)
                        .applyTextStyle(.caption(Color(viewConfig.color(userDescriptionToken))))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if let action = user?.actionLabel ?? actionLabel, !action.isEmpty {
                Button {
                    if let user { onActionClick?(user) }
                } label: {
                    Text(action)
                        .applyTextStyle(.bodyBold(Color(viewConfig.color(userActionToken))))
                }
                .disabled(disabled)
            }
        }
    }

    // MARK: - Effective state

    /// Boxed/Text resolve Focused from the native field unless the consumer forces a state.
    private var effectiveState: InputStateEnum {
        switch state {
        case .disabled: return .disabled
        case .error:    return .error
        case .focused:  return .focused
        case .default:  return isFocused ? .focused : .default
        }
    }

    /// Chip has no Focused token — collapse to Default (still honouring forced Disabled/Error).
    private var chipState: InputStateEnum {
        switch state {
        case .disabled: return .disabled
        case .error:    return .error
        default:        return .default
        }
    }

    /// User is binary Default/Disabled — Error/Focused fall back to Default.
    private var userDisabled: Bool {
        state == .disabled || (user?.disabled ?? false)
    }

    // MARK: - Token resolution — Text Input (also used by Boxed)

    /// Icon tone: Default/Disabled/Error (Focused reuses Default — no Focused icon token).
    private var textIconToken: AmityColorToken {
        switch effectiveState {
        case .disabled: return .iconInputTextInputDisabled
        case .error:    return .iconInputTextInputError
        default:        return .iconInputTextInputDefault
        }
    }

    private var textUnderlineToken: AmityColorToken {
        switch effectiveState {
        case .disabled: return .lineInputTextInputUnderlinedDisabled
        case .error:    return .lineInputTextInputUnderlinedError
        default:        return .lineInputTextInputUnderlinedDefault
        }
    }

    private var textHintToken: AmityColorToken {
        effectiveState == .error ? .textInputTextInputHintTextError : .textInputTextInputHintTextDefault
    }

    /// The 12-cell Placeholder matrix: `{state} × {none | Filled | Highlight}`.
    /// `filled` = the field has typed content; `highlightMatch` = matched-substring emphasis.
    /// Precedence: Highlight > Filled > none (the token set has no combined Filled+Highlight cell).
    private func textPlaceholderToken(filled: Bool) -> AmityColorToken {
        let modifier: PlaceholderModifier = highlightMatch ? .highlight : (filled ? .filled : .none)
        switch (effectiveState, modifier) {
        case (.default, .none):       return .textInputTextInputPlaceholderEnabled
        case (.default, .filled):     return .textInputTextInputPlaceholderEnabledFilled
        case (.default, .highlight):  return .textInputTextInputPlaceholderEnabledHighlight
        case (.focused, .none):       return .textInputTextInputPlaceholderFocused
        case (.focused, .filled):     return .textInputTextInputPlaceholderFocusedFilled
        case (.focused, .highlight):  return .textInputTextInputPlaceholderFocusedHighlight
        case (.disabled, .none):      return .textInputTextInputPlaceholderDisabled
        case (.disabled, .filled):    return .textInputTextInputPlaceholderDisabledFilled
        case (.disabled, .highlight): return .textInputTextInputPlaceholderDisabledHighlight
        case (.error, .none):         return .textInputTextInputPlaceholderError
        case (.error, .filled):       return .textInputTextInputPlaceholderErrorFilled
        case (.error, .highlight):    return .textInputTextInputPlaceholderErrorHighlight
        }
    }

    private enum PlaceholderModifier { case none, filled, highlight }

    // MARK: - Token resolution — Chip Input

    private func chipTitleToken(disabled: Bool) -> AmityColorToken {
        if disabled { return .textInputChipInputTitleDisabled }
        return chipState == .error ? .textInputChipInputTitleError : .textInputChipInputTitleDefault
    }

    private var chipIconToken: AmityColorToken {
        switch chipState {
        case .disabled: return .iconInputChipInputDisabled
        case .error:    return .iconInputChipInputError
        default:        return .iconInputChipInputDefault
        }
    }

    private var chipUnderlineToken: AmityColorToken {
        switch chipState {
        case .disabled: return .lineInputChipInputUnderlinedDisabled
        case .error:    return .lineInputChipInputUnderlinedError
        default:        return .lineInputChipInputUnderlinedDefault
        }
    }

    private var chipPlaceholderToken: AmityColorToken {
        switch chipState {
        case .disabled: return .textInputChipInputPlaceholderDisabled
        case .error:    return .textInputChipInputPlaceholderError
        default:        return .textInputChipInputPlaceholderEnabled
        }
    }

    private var chipHintToken: AmityColorToken {
        chipState == .error ? .textInputChipInputHintTextError : .textInputChipInputHintTextDefault
    }

    private var chipDescriptionToken: AmityColorToken {
        switch chipState {
        case .disabled: return .textInputChipInputTextDescriptionDisabled
        case .error:    return .textInputChipInputTextDescriptionError
        default:        return .textInputChipInputTextDescriptionDefault
        }
    }

    // MARK: - Token resolution — User Input

    private var userTitleToken: AmityColorToken {
        userDisabled ? .textInputUserInputTitleDisabled : .textInputUserInputTitleDefault
    }

    private var userUsernameToken: AmityColorToken {
        userDisabled ? .textInputUserInputUserNameDisabled : .textInputUserInputUserNameDefault
    }

    private var userDescriptionToken: AmityColorToken {
        userDisabled ? .textInputUserInputTextDescriptionDisabled : .textInputUserInputTextDescriptionDefault
    }

    private var userActionToken: AmityColorToken {
        userDisabled ? .textInputUserInputActionDisabled : .textInputUserInputActionDefault
    }

    // MARK: - Shared subviews

    @ViewBuilder
    private func leadingIconView(token: AmityColorToken) -> some View {
        if let leadingIcon {
            Image(leadingIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(Color(viewConfig.color(token)))
        }
    }

    @ViewBuilder
    private func trailingIconView(token: AmityColorToken) -> some View {
        if let trailingIcon {
            Image(trailingIcon.imageResource)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(Color(viewConfig.color(token)))
        }
    }

    private func characterCount(token: AmityColorToken) -> some View {
        let label = maxLength.map { "\(text.count)/\($0)" } ?? "\(text.count)"
        return Text(label)
            .applyTextStyle(.caption(Color(viewConfig.color(token))))
    }
}
