#!/bin/bash
# check-hardcoded-strings.sh
# Scans Swift source files for hardcoded English strings that should use the localization system.
# Covers patterns from Section 6 of the Cross-Platform Localization Spec (v1.1).
#
# Usage: ./scripts/check-hardcoded-strings.sh [--strict]
#   --strict  Fail on any violation (default for CI).
#   Without --strict, violations are reported but exit code is 0 (advisory mode).
#
# Suppressing a known intentional violation:
#   Add  // l10n:ok <reason>  at the end of the line, e.g.:
#     Text("Oops! You should not be seeing this screen.") // l10n:ok dev-only error state
#     Button("Next") { ... } // l10n:ok config-driven, not localized by design
#
# Exit code: 0 = clean (or advisory mode), 1 = violations found (strict mode), 2 = setup error

set -euo pipefail

STRICT=true
[[ "${1:-}" == "--advisory" ]] && STRICT=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../AmityUIKit4" && pwd)"
LOCALIZATION_DIR="$PROJECT_DIR/Core/Localization"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Cannot find project directory at $PROJECT_DIR"
    echo "Expected layout: scripts/ sits next to AmityUIKit4/"
    exit 2
fi

VIOLATIONS=0
VIOLATION_LOG=""

add_violation() {
    local file="$1"
    local line_num="$2"
    local description="$3"
    VIOLATION_LOG+="${file}:${line_num}: ${description}"$'\n'
    VIOLATIONS=$((VIOLATIONS + 1))
}

# ─── Shared exclusion helpers ──────────────────────────────────────────────────

is_excluded_file() {
    local f="$1"
    # Test/preview/localization infrastructure files
    # Use pure-bash [[ =~ ]] to avoid subshell/grep SIGTRAP under set -euo pipefail
    [[ "$f" =~ (Tests/|/scripts/|AmityLocalizedStringSet\.swift|AmityStringProvider\.swift|QALocaleVerification\.swift|String\+Extension\.swift|AmityLocalizable\.strings) ]] && return 0
    # Third-party / generated code
    [[ "$f" =~ (/Extenral/|/External/|Shimmer\.swift|ExpandableText\.swift|CollapseableScrollView\.swift) ]] && return 0
    return 1
}

is_excluded_line() {
    local content="$1"
    # Comment lines
    local stripped="${content#"${content%%[![:space:]]*}"}"
    [[ "$stripped" == //* ]] && return 0
    [[ "$stripped" == \** ]] && return 0
    [[ "$stripped" == \#* ]] && return 0

    # Intentional bypass — annotate the line with: // l10n:ok <reason>
    [[ "$content" == *"// l10n:ok"* ]] && return 0

    # Debug / logging / assertions (not user-facing)
    # All checks use pure-bash [[ =~ ]] — avoids subshell/grep SIGTRAP under set -euo pipefail
    [[ "$content" =~ (print|debugPrint|Log\.|assertionFailure|fatalError|precondition|NSLog)\ *\( ]] && return 0

    # Lines already using localization
    [[ "$content" =~ (\.localizedString|\.localized\(|NSLocalizedString|AmityLocalizedStringSet|AmityStringProvider|stringProvider) ]] && return 0

    # Image/icon/technical references
    [[ "$content" =~ (Image\(|systemName:|\.image\(named|UIImage\(named|\.sfSymbol|iconName|\.imageResource|getImageResource|AmityIcon) ]] && return 0

    # Font/color/style references
    [[ "$content" =~ (\.font\(|Font\.|Color\(|UIColor|\.foregroundColor|\.background\(|applyTextStyle) ]] && return 0

    # Import, case, protocol
    [[ "$content" =~ ^[[:space:]]*(import|case|protocol|@) ]] && return 0

    # Accessibility identifiers
    [[ "$content" =~ (accessibilityIdentifier|AccessibilityID|\.id\() ]] && return 0

    # Preview providers
    [[ "$content" =~ (#Preview|PreviewProvider|_Previews) ]] && return 0

    # Deprecated annotations
    [[ "$content" =~ @available\(.*deprecated ]] && return 0

    return 1
}

# Collect Swift files — write to temp file to avoid bash 3.2 herestring (<<<) crash
# with large variables (>64KB). All scans read from $SWIFT_FILES_TMP.
SWIFT_FILES_TMP=$(mktemp) || { echo "Cannot create temp file"; exit 2; }
MATCH_TMP=""  # set later; trap uses it if defined
trap 'rm -f "$SWIFT_FILES_TMP" ${MATCH_TMP:+"$MATCH_TMP"}' EXIT

find "$PROJECT_DIR" -name '*.swift' | sort | while IFS= read -r file; do
    is_excluded_file "$file" || echo "$file"
done > "$SWIFT_FILES_TMP"

if [ ! -s "$SWIFT_FILES_TMP" ]; then
    echo "No Swift files found to scan in $PROJECT_DIR"
    exit 0
fi

scan_pattern() {
    local pattern="$1"
    local check_name="$2"
    local match_tmp
    match_tmp=$(mktemp)

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        local rel_path="${file#"$PROJECT_DIR"/}"

        # Write grep output to temp file — avoids bash 3.2 bug where nested while loops
        # combining a file redirect (< file) with a process substitution (< <(cmd))
        # causes SIGTRAP on macOS.
        grep -n "$pattern" "$file" > "$match_tmp" 2>/dev/null || true

        while IFS=: read -r line_num content; do
            [ -z "$line_num" ] && continue
            is_excluded_line "$content" && continue

            local trimmed="${content#"${content%%[![:space:]]*}"}"
            add_violation "$rel_path" "$line_num" "$check_name: ${trimmed:0:140}"
        done < "$match_tmp"
    done < "$SWIFT_FILES_TMP"

    rm -f "$match_tmp"
}

# ─── Check 1: Text("UpperCase...") — hardcoded SwiftUI text ───────────────────
scan_pattern 'Text(\s*"[A-Z][a-zA-Z ]' "Hardcoded Text()"

# ─── Check 2: Button("UpperCase...") — hardcoded button labels ────────────────
scan_pattern 'Button(\s*"[A-Z][a-zA-Z ]' "Hardcoded Button()"

# Shared match temp file for inline checks (avoids bash 3.2 process-substitution bug)
MATCH_TMP=$(mktemp)

# ─── Check 3: TextField("UpperCase...", — hardcoded placeholder ────────────────
# Note: TextField("", ...) is fine (empty placeholder), only flag non-empty
while IFS= read -r file; do
    [ -z "$file" ] && continue
    local_rel="${file#"$PROJECT_DIR"/}"
    grep -n 'TextField(\s*"[A-Z]' "$file" > "$MATCH_TMP" 2>/dev/null || true
    while IFS=: read -r line_num content; do
        [ -z "$line_num" ] && continue
        is_excluded_line "$content" && continue
        # Extract placeholder text using pure bash regex
        if [[ "$content" =~ TextField\(\"([^\"]+)\" ]]; then
            placeholder="${BASH_REMATCH[1]}"
        else
            continue
        fi
        [ ${#placeholder} -le 1 ] && continue
        # Skip snake_case keys (start with lowercase or underscore)
        [[ "$placeholder" =~ ^[a-z_] ]] && continue
        trimmed="${content#"${content%%[![:space:]]*}"}"
        add_violation "$local_rel" "$line_num" "Hardcoded TextField placeholder: ${trimmed:0:140}"
    done < "$MATCH_TMP"
done < "$SWIFT_FILES_TMP"

# ─── Check 4: Toast.showToast(message: "...") — hardcoded toast messages ──────
while IFS= read -r file; do
    [ -z "$file" ] && continue
    local_rel="${file#"$PROJECT_DIR"/}"
    grep -n 'Toast\.showToast.*message: "[A-Z]' "$file" > "$MATCH_TMP" 2>/dev/null || true
    while IFS=: read -r line_num content; do
        [ -z "$line_num" ] && continue
        is_excluded_line "$content" && continue
        trimmed="${content#"${content%%[![:space:]]*}"}"
        add_violation "$local_rel" "$line_num" "Hardcoded toast message: ${trimmed:0:140}"
    done < "$MATCH_TMP"
done < "$SWIFT_FILES_TMP"

# ─── Check 5: UIAlertController(title:/message: "...") — hardcoded alerts ─────
while IFS= read -r file; do
    [ -z "$file" ] && continue
    local_rel="${file#"$PROJECT_DIR"/}"
    grep -n 'UIAlertAction\|UIAlertController' "$file" 2>/dev/null | grep '"[A-Z][a-z]' > "$MATCH_TMP" || true
    while IFS=: read -r line_num content; do
        [ -z "$line_num" ] && continue
        is_excluded_line "$content" && continue
        trimmed="${content#"${content%%[![:space:]]*}"}"
        add_violation "$local_rel" "$line_num" "Hardcoded alert text: ${trimmed:0:140}"
    done < "$MATCH_TMP"
done < "$SWIFT_FILES_TMP"

# ─── Check 6: ?? "UpperCase..." — config fallback with hardcoded English ──────
while IFS= read -r file; do
    [ -z "$file" ] && continue
    local_rel="${file#"$PROJECT_DIR"/}"
    grep -n '?? *"[A-Z]' "$file" > "$MATCH_TMP" 2>/dev/null || true
    while IFS=: read -r line_num content; do
        [ -z "$line_num" ] && continue
        is_excluded_line "$content" && continue

        # Extract fallback string using pure bash regex
        if [[ "$content" =~ \?\?[[:space:]]*\"([^\"]+)\" ]]; then
            fallback="${BASH_REMATCH[1]}"
        else
            continue
        fi
        [ ${#fallback} -le 1 ] && continue

        # Skip snake_case keys, URLs, file paths, format strings
        [[ "$fallback" =~ ^[a-z_]|^%|https?://|\.(com|json|png|jpg|svg)$ ]] && continue
        [[ "$fallback" =~ ^[A-Z] ]] || continue

        add_violation "$local_rel" "$line_num" "Hardcoded fallback: ?? \"$fallback\""
    done < "$MATCH_TMP"
done < "$SWIFT_FILES_TMP"

# ─── Check 7: title:/message:/placeholder:/description:/text: "UpperCase..." — struct init args ──
while IFS= read -r file; do
    [ -z "$file" ] && continue
    local_rel="${file#"$PROJECT_DIR"/}"
    grep -n '\(title\|message\|placeholder\|description\|text\): *"[A-Z]' "$file" > "$MATCH_TMP" 2>/dev/null || true
    while IFS=: read -r line_num content; do
        [ -z "$line_num" ] && continue
        is_excluded_line "$content" && continue

        # Extract the hardcoded string using pure bash regex
        if [[ "$content" =~ (title|message|placeholder|description|text):[[:space:]]*\"([^\"]+)\" ]]; then
            str_val="${BASH_REMATCH[2]}"
        else
            continue
        fi
        [ ${#str_val} -le 2 ] && continue

        # Skip if it's a localized string
        [[ "$content" =~ (\.localizedString|localizedString|AmityLocalizedStringSet) ]] && continue

        trimmed="${content#"${content%%[![:space:]]*}"}"
        add_violation "$local_rel" "$line_num" "Hardcoded label arg: ${trimmed:0:140}"
    done < "$MATCH_TMP"
done < "$SWIFT_FILES_TMP"

rm -f "$MATCH_TMP"

# ─── Check 7b: .placeholder("UpperCase...") — dot-method syntax (missed by Check 7) ─
while IFS= read -r file; do
    [ -z "$file" ] && continue
    local_rel="${file#"$PROJECT_DIR"/}"
    grep -n '\.placeholder(\s*"[A-Z]' "$file" > "$MATCH_TMP" 2>/dev/null || true
    while IFS=: read -r line_num content; do
        [ -z "$line_num" ] && continue
        is_excluded_line "$content" && continue

        if [[ "$content" =~ \.placeholder\([[:space:]]*\"([^\"]+)\" ]]; then
            str_val="${BASH_REMATCH[1]}"
        else
            continue
        fi
        [ ${#str_val} -le 2 ] && continue
        [[ "$content" =~ (\.localizedString|localizedString|AmityLocalizedStringSet) ]] && continue

        trimmed="${content#"${content%%[![:space:]]*}"}"
        add_violation "$local_rel" "$line_num" "Hardcoded .placeholder() method: ${trimmed:0:140}"
    done < "$MATCH_TMP"
done < "$SWIFT_FILES_TMP"

rm -f "$MATCH_TMP"

# ─── Check 7c: return "UpperCase..." — bare string return (computed vars / funcs) ─
while IFS= read -r file; do
    [ -z "$file" ] && continue
    local_rel="${file#"$PROJECT_DIR"/}"
    grep -n 'return *"[A-Z]' "$file" > "$MATCH_TMP" 2>/dev/null || true
    while IFS=: read -r line_num content; do
        [ -z "$line_num" ] && continue
        is_excluded_line "$content" && continue

        if [[ "$content" =~ return[[:space:]]*\"([^\"]+)\" ]]; then
            str_val="${BASH_REMATCH[1]}"
        else
            continue
        fi
        # Skip short strings, snake_case keys, URLs, format strings
        [ ${#str_val} -le 3 ] && continue
        [[ "$str_val" =~ ^[a-z_]|^%|https?://|\.(com|json|png|jpg|svg)$ ]] && continue
        # Skip localized returns
        [[ "$content" =~ (\.localizedString|localizedString|AmityLocalizedStringSet) ]] && continue

        trimmed="${content#"${content%%[![:space:]]*}"}"
        add_violation "$local_rel" "$line_num" "Hardcoded return string: ${trimmed:0:140}"
    done < "$MATCH_TMP"
done < "$SWIFT_FILES_TMP"

rm -f "$MATCH_TMP"
scan_pattern '\.capitalizeFirstLetter()' "capitalizeFirstLetter() — use resolveReactionDisplayName"

# ─── Check 8b: implicit switch expression "UpperCase..." — Swift 5.9 no-return strings ─
# Catches: case .foo:\n    "String" (bare string, no return/Text/Button prefix)
while IFS= read -r file; do
    [ -z "$file" ] && continue
    local_rel="${file#"$PROJECT_DIR"/}"
    grep -n '^\s*"[A-Z][a-zA-Z]' "$file" > "$MATCH_TMP" 2>/dev/null || true
    while IFS=: read -r line_num content; do
        [ -z "$line_num" ] && continue
        is_excluded_line "$content" && continue

        if [[ "$content" =~ [[:space:]]*\"([^\"]+)\" ]]; then
            str_val="${BASH_REMATCH[1]}"
        else
            continue
        fi
        [ ${#str_val} -le 3 ] && continue
        # Skip snake_case / url / format string values
        [[ "$str_val" =~ ^[a-z_]|^%|https?://|\.(com|json|png|jpg|svg)$ ]] && continue
        # Skip localized
        [[ "$content" =~ (\.localizedString|localizedString|AmityLocalizedStringSet) ]] && continue

        trimmed="${content#"${content%%[![:space:]]*}"}"
        add_violation "$local_rel" "$line_num" "Implicit switch string: ${trimmed:0:140}"
    done < "$MATCH_TMP"
done < "$SWIFT_FILES_TMP"

rm -f "$MATCH_TMP"

# ─── Check 8c: ternary with hardcoded string — condition ? "UpperCase" : "..." ─
while IFS= read -r file; do
    [ -z "$file" ] && continue
    local_rel="${file#"$PROJECT_DIR"/}"
    grep -n '? *"[A-Z][a-zA-Z ]' "$file" > "$MATCH_TMP" 2>/dev/null || true
    while IFS=: read -r line_num content; do
        [ -z "$line_num" ] && continue
        is_excluded_line "$content" && continue

        # Skip lines that already use localization
        [[ "$content" =~ (\.localizedString|localizedString|AmityLocalizedStringSet) ]] && continue
        # Skip single-character / short strings and non-display contexts
        if [[ "$content" =~ \?[[:space:]]*\"([^\"]{3,})\" ]]; then
            str_val="${BASH_REMATCH[1]}"
        else
            continue
        fi
        [ ${#str_val} -le 2 ] && continue

        trimmed="${content#"${content%%[![:space:]]*}"}"
        add_violation "$local_rel" "$line_num" "Ternary hardcoded string: ${trimmed:0:140}"
    done < "$MATCH_TMP"
done < "$SWIFT_FILES_TMP"

rm -f "$MATCH_TMP"

# ─── Check 9: .strings file consistency ────────────────────────────────────────
if [ -d "$LOCALIZATION_DIR" ]; then
    EN_FILE="$LOCALIZATION_DIR/en.lproj/AmityLocalizable.strings"
    TH_FILE="$LOCALIZATION_DIR/th.lproj/AmityLocalizable.strings"

    if [ -f "$EN_FILE" ] && [ -f "$TH_FILE" ]; then
        EN_KEYS=$(grep -c '^ *"' "$EN_FILE" || echo 0)
        TH_KEYS=$(grep -c '^ *"' "$TH_FILE" || echo 0)
        if [ "$EN_KEYS" != "$TH_KEYS" ]; then
            add_violation "Core/Localization" "0" "Key count mismatch: en=$EN_KEYS, th=$TH_KEYS"
        fi

        # Check for syntax errors
        if ! plutil -lint "$EN_FILE" > /dev/null 2>&1; then
            add_violation "en.lproj/AmityLocalizable.strings" "0" "Invalid .strings syntax"
        fi
        if ! plutil -lint "$TH_FILE" > /dev/null 2>&1; then
            add_violation "th.lproj/AmityLocalizable.strings" "0" "Invalid .strings syntax"
        fi
    fi
fi

# ─── Output ────────────────────────────────────────────────────────────────────
file_count=0
while IFS= read -r _f; do [ -n "$_f" ] && file_count=$((file_count + 1)); done < "$SWIFT_FILES_TMP"
echo "Scanned $file_count Swift files"

if [ "$VIOLATIONS" -gt 0 ]; then
    echo ""
    echo "$VIOLATION_LOG"
    echo "Found $VIOLATIONS potential violation(s)"
    if $STRICT; then
        exit 1
    else
        echo "(advisory mode — not failing build)"
        exit 0
    fi
else
    echo "No hardcoded string violations found. ✅"
    exit 0
fi
