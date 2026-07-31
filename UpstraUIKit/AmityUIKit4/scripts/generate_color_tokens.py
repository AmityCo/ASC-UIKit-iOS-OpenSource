#!/usr/bin/env python3
"""
Generates AmityColorTokens.generated.swift from AmityUIKitDesignTokens.json.

The design tokens JSON has two objects:
  - "alias":    alias name -> "{theme.<key>}" reference into the theme palette
  - "semantic": semantic token name -> { "light": value, "dark": value } where a
                value is either "{<alias name>}" or a raw hex color ("#RRGGBB")

This script emits:
  - enum AmityColorAlias   (one case per alias, rawValue = alias name)
  - enum AmityColorToken   (one case per semantic token, rawValue = token name)
  - AmityColorToken.values (generated switch mapping each token to its
                            light/dark AmityColorTokenValue)
  - AmityColorAlias.uiColor(theme:) (generated switch mapping each alias to an
                            AmityThemeColor property or AmityFixedColor)

Run it again whenever design updates AmityUIKitDesignTokens.json:
    python3 scripts/generate_color_tokens.py
"""

import json
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODULE_DIR = os.path.join(SCRIPT_DIR, "..", "AmityUIKit4")
TOKENS_JSON = os.path.join(MODULE_DIR, "AmityUIKitDesignTokens.json")
OUTPUT_SWIFT = os.path.join(
    MODULE_DIR, "Core", "Utilities", "ConfigControllers", "AmityColorTokens.generated.swift"
)

# Maps "{theme.<key>}" references from the alias object to Swift expressions.
# Keys not present in AmityThemeColor resolve through AmityFixedColor.
THEME_KEY_TO_SWIFT = {
    "theme.primary_color": "theme.primaryColor",
    "theme.primary_shade1_color": "theme.primaryColorShade1",
    "theme.primary_shade2_color": "theme.primaryColorShade2",
    "theme.primary_shade3_color": "theme.primaryColorShade3",
    "theme.primary_shade4_color": "theme.primaryColorShade4",
    "theme.secondary_color": "theme.secondaryColor",
    "theme.secondary_shade1_color": "theme.secondaryColorShade1",
    "theme.secondary_shade2_color": "theme.secondaryColorShade2",
    "theme.secondary_shade3_color": "theme.secondaryColorShade3",
    "theme.secondary_shade4_color": "theme.secondaryColorShade4",
    "theme.neutral_grey_shade1_color": "theme.neutralGreyShade1Color",
    "theme.neutral_grey_shade2_color": "theme.neutralGreyShade2Color",
    "theme.neutral_grey_shade3_color": "theme.neutralGreyShade3Color",
    "theme.neutral_grey_shade4_color": "theme.neutralGreyShade4Color",
    "theme.neutral_grey_shade5_color": "theme.neutralGreyShade5Color",
    "theme.neutral_grey_shade6_color": "theme.neutralGreyShade6Color",
    "theme.base_color": "theme.baseColor",
    "theme.base_shade1_color": "theme.baseColorShade1",
    "theme.base_shade2_color": "theme.baseColorShade2",
    "theme.base_shade3_color": "theme.baseColorShade3",
    "theme.base_shade4_color": "theme.baseColorShade4",
    "theme.base_inverse_color": "theme.baseInverseColor",
    "theme.alert_color": "theme.alertColor",
    "theme.alert_shade1_color": "theme.alertColorShade1",
    "theme.background_color": "theme.backgroundColor",
    "theme.background_shade1_color": "theme.backgroundShade1Color",
    "theme.highlight_color": "theme.highlightColor",
    "theme.destructive_shade1_color": "theme.destructiveShade1Color",
    "theme.destructive_shade2_color": "theme.destructiveShade2Color",
    "theme.destructive_shade3_color": "theme.destructiveShade3Color",
    "theme.destructive_shade4_color": "theme.destructiveShade4Color",
    "theme.destructive_shade5_color": "theme.destructiveShade5Color",
    "theme.transparent_black_shade1_color": "theme.transparentBlackShade1Color",
    "theme.transparent_black_shade2_color": "theme.transparentBlackShade2Color",
    "theme.transparent_black_shade3_color": "theme.transparentBlackShade3Color",
    "theme.transparent_black_shade4_color": "theme.transparentBlackShade4Color",
    "theme.transparent_black_shade5_color": "theme.transparentBlackShade5Color",
    "theme.transparent_white_shade1_color": "theme.transparentWhiteShade1Color",
    "theme.transparent_white_shade2_color": "theme.transparentWhiteShade2Color",
    "theme.transparent_white_shade3_color": "theme.transparentWhiteShade3Color",
    "theme.transparent_white_shade4_color": "theme.transparentWhiteShade4Color",
    "theme.transparent_white_shade5_color": "theme.transparentWhiteShade5Color",
    "theme.transparent_white_shade6_color": "theme.transparentWhiteShade6Color",
    "theme.transparent_white_shade7_color": "theme.transparentWhiteShade7Color",
    "theme.transparent_red_shade1_color": "theme.transparentRedShade1Color",
    "theme.black_color": "AmityFixedColor.shared.black",
    "theme.white_color": "AmityFixedColor.shared.white",
    "theme.event_host_bg_color": "AmityFixedColor.shared.eventHostBg",
    "theme.event_host_fg_color": "AmityFixedColor.shared.eventHost",
    "theme.live_color": "AmityFixedColor.shared.live",
}

HEX_PATTERN = re.compile(r"#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$")


def camel_case(path):
    """'Border/Tab/Pill/Active' -> 'borderTabPillActive'; '&' reads as 'And' per spec."""
    words = []
    for segment in path.split("/"):
        for part in re.split(r"[^A-Za-z0-9]+", segment.replace("&", " And ")):
            if part:
                words.append(part)
    if not words:
        fail(f"Cannot derive a case name from '{path}'")
    name = words[0][0].lower() + words[0][1:]
    for word in words[1:]:
        name += word[0].upper() + word[1:]
    if name[0].isdigit():
        name = "_" + name
    return name


def fail(message):
    print(f"error: {message}", file=sys.stderr)
    sys.exit(1)


def build_case_names(keys, kind):
    """Returns {key: caseName}, failing on collisions."""
    names = {}
    seen = {}
    for key in keys:
        name = camel_case(key)
        if name in seen:
            fail(f"{kind} case name collision: '{key}' and '{seen[name]}' both map to '{name}'")
        seen[name] = key
        names[key] = name
    return names


def value_expr(value, token_key, alias_names):
    if value.startswith("{") and value.endswith("}"):
        ref = value[1:-1]
        if ref not in alias_names:
            fail(f"semantic token '{token_key}' references unknown alias '{ref}'")
        return f".alias(.{alias_names[ref]})"
    if HEX_PATTERN.fullmatch(value):
        return f'.hex("{value}")'
    fail(f"semantic token '{token_key}' has unsupported value '{value}'")


def main():
    with open(TOKENS_JSON) as f:
        tokens = json.load(f)

    aliases = tokens["alias"]
    semantics = tokens["semantic"]

    alias_names = build_case_names(sorted(aliases), "alias")
    token_names = build_case_names(sorted(semantics), "semantic token")

    for alias_key, theme_ref in aliases.items():
        if not (theme_ref.startswith("{") and theme_ref.endswith("}")):
            fail(f"alias '{alias_key}' has non-reference value '{theme_ref}'")
        if theme_ref[1:-1] not in THEME_KEY_TO_SWIFT:
            fail(f"alias '{alias_key}' references unknown theme key '{theme_ref}' — add it to THEME_KEY_TO_SWIFT")

    lines = []
    lines.append("//")
    lines.append("//  AmityColorTokens.generated.swift")
    lines.append("//  AmityUIKit4")
    lines.append("//")
    lines.append("//  Auto-generated from AmityUIKitDesignTokens.json by scripts/generate_color_tokens.py.")
    lines.append("//  Do not edit manually — re-run the script after updating the design tokens JSON.")
    lines.append("//")
    lines.append("")
    lines.append("import UIKit")
    lines.append("")

    # AmityColorAlias
    lines.append("/// Alias color tokens from the design system. Each alias resolves to a theme")
    lines.append("/// palette color (`AmityThemeColor`) or a fixed color (`AmityFixedColor`).")
    lines.append("enum AmityColorAlias: String, CaseIterable {")
    for key in sorted(aliases):
        lines.append(f"    /// {aliases[key]}")
        lines.append(f'    case {alias_names[key]} = "{key}"')
    lines.append("}")
    lines.append("")

    lines.append("extension AmityColorAlias {")
    lines.append("    /// Resolves this alias against the given theme palette.")
    lines.append("    func uiColor(theme: AmityThemeColor) -> UIColor {")
    lines.append("        switch self {")
    for key in sorted(aliases):
        swift_expr = THEME_KEY_TO_SWIFT[aliases[key][1:-1]]
        lines.append(f"        case .{alias_names[key]}: return {swift_expr}")
    lines.append("        }")
    lines.append("    }")
    lines.append("}")
    lines.append("")

    # AmityColorToken
    lines.append("/// Semantic color tokens from the design system. Resolve one against the")
    lines.append("/// current theme with `viewConfig.color(_:)`.")
    lines.append("enum AmityColorToken: String, CaseIterable {")
    for key in sorted(semantics):
        lines.append(f'    case {token_names[key]} = "{key}"')
    lines.append("}")
    lines.append("")

    lines.append("extension AmityColorToken {")
    lines.append("    /// The light & dark values this token resolves to.")
    lines.append("    var values: (light: AmityColorTokenValue, dark: AmityColorTokenValue) {")
    lines.append("        switch self {")
    for key in sorted(semantics):
        entry = semantics[key]
        light = value_expr(entry["light"], key, alias_names)
        dark = value_expr(entry["dark"], key, alias_names)
        lines.append(f"        case .{token_names[key]}: return ({light}, {dark})")
    lines.append("        }")
    lines.append("    }")
    lines.append("}")

    with open(OUTPUT_SWIFT, "w") as f:
        f.write("\n".join(lines) + "\n")

    print(f"Generated {len(aliases)} aliases and {len(semantics)} semantic tokens")
    print(f"  -> {os.path.relpath(OUTPUT_SWIFT, os.path.join(SCRIPT_DIR, '..'))}")


if __name__ == "__main__":
    main()
