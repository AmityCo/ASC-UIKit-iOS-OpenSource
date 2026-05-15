#!/usr/bin/env bash
#
# check-missing-translations.sh
#
# For every AmityLocalizable.strings locale bundle found in SampleApp,
# compares it against the framework's EN source of truth and reports:
#
#   MISSING      — key exists in EN but is absent from the locale file
#   UNTRANSLATED — key exists in locale but has the same value as EN
#   ORPHAN       — key exists in locale but not in EN (stale, safe to remove)
#
# Usage (run from AmityUIKit4/ directory):
#   bash scripts/check-missing-translations.sh              # exits 1 on violations
#   bash scripts/check-missing-translations.sh --advisory   # reports, always exits 0
#
# Violations = MISSING + UNTRANSLATED  (these block a complete translation)
# Orphans are warnings only            (stale keys, don't block translation)
#

ADVISORY=0
if [ "${1:-}" = "--advisory" ]; then
    ADVISORY=1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
EN_FILE="$ROOT_DIR/AmityUIKit4/Core/Localization/en.lproj/AmityLocalizable.strings"
SAMPLE_DIR="$ROOT_DIR/../SampleApp/SampleApp"

if [ ! -f "$EN_FILE" ]; then
    echo "ERROR: EN source not found at: $EN_FILE" >&2
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required." >&2
    echo "       Install Xcode Command Line Tools: xcode-select --install" >&2
    exit 1
fi

python3 - "$ADVISORY" "$EN_FILE" "$SAMPLE_DIR" << 'PYEOF'
import sys, re, pathlib

# ── Arguments ──────────────────────────────────────────────────────────────
advisory   = sys.argv[1] == "1"
en_path    = sys.argv[2]
sample_dir = sys.argv[3]

# Keys where identical EN/locale values are intentionally correct
# (symbols, abbreviations, or punctuation that require no translation)
KNOWN_SAME = {
    "alt_text_button_title",         # "ALT" — same in all languages
    "amity_common_required_indicator", # " *"  — asterisk indicator
    "event_detail_header_rsvp",      # "RSVP" — international acronym, same in all languages
}

# ── Parser ──────────────────────────────────────────────────────────────────
def parse_strings(path):
    """Parse a .strings file and return dict of key -> value."""
    result = {}
    try:
        content = pathlib.Path(path).read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        print(f"  ERROR: Cannot read {path}: {e}", file=sys.stderr)
        return result
    # Match "key" = "value"; allowing escaped characters inside quotes
    for m in re.finditer(r'"((?:[^"\\]|\\.)*?)"\s*=\s*"((?:[^"\\]|\\.)*?)"\s*;', content):
        result[m.group(1)] = m.group(2)
    return result

# ── Load EN source of truth ─────────────────────────────────────────────────
en      = parse_strings(en_path)
en_keys = set(en.keys())
print(f"check-missing-translations: EN source — {len(en_keys)} keys")
print()

# ── Discover locale files ───────────────────────────────────────────────────
locale_files = []
for lproj_dir in sorted(pathlib.Path(sample_dir).glob("*.lproj")):
    strings_file = lproj_dir / "AmityLocalizable.strings"
    if not strings_file.exists():
        continue
    locale_code = lproj_dir.stem   # "th", "ja", "ko", etc.
    if locale_code == "en":
        continue  # EN is the source, not a target
    locale_files.append((locale_code, strings_file))

if not locale_files:
    print("check-missing-translations: No locale bundles found in SampleApp. Nothing to check.")
    print("  Add <lang>.lproj/AmityLocalizable.strings to SampleApp/SampleApp/ to get started.")
    sys.exit(0)

# ── Check each locale ───────────────────────────────────────────────────────
total_missing      = 0
total_untranslated = 0
total_orphans      = 0

for locale_code, locale_path in locale_files:
    locale      = parse_strings(locale_path)
    locale_keys = set(locale.keys())

    missing      = sorted(en_keys - locale_keys)
    orphans      = sorted(locale_keys - en_keys)
    untranslated = sorted(
        k for k in (en_keys & locale_keys)
        if locale[k] == en[k] and k not in KNOWN_SAME
    )

    n_missing      = len(missing)
    n_untranslated = len(untranslated)
    n_orphans      = len(orphans)
    violations     = n_missing + n_untranslated

    print(f"── {locale_code} ({len(locale_keys)}/{len(en_keys)} keys) ──")

    if missing:
        print(f"  MISSING ({n_missing}) — add these keys to {locale_code}.lproj/AmityLocalizable.strings:")
        for k in missing:
            en_val = en.get(k, "")
            print(f'    ✗  "{k}" = "{en_val}";')

    if untranslated:
        print(f"  UNTRANSLATED ({n_untranslated}) — value is identical to English:")
        for k in untranslated:
            print(f'    ~  "{k}" = "{en[k]}";')

    if orphans:
        print(f"  ORPHAN ({n_orphans}) — in {locale_code} but not in EN (stale, safe to remove):")
        for k in orphans:
            print(f"    ?  {k}")

    if violations == 0 and n_orphans == 0:
        print(f"  ✅ Fully translated — no issues.")
    elif violations == 0:
        print(f"  ✅ Fully translated ({n_orphans} stale orphan(s) — consider removing).")
    else:
        print(f"  ✗  {violations} violation(s): {n_missing} missing, {n_untranslated} untranslated"
              + (f", {n_orphans} orphan(s)" if n_orphans else ""))

    print()
    total_missing      += n_missing
    total_untranslated += n_untranslated
    total_orphans      += n_orphans

# ── Summary ─────────────────────────────────────────────────────────────────
total_violations = total_missing + total_untranslated

if total_violations == 0:
    suffix = f" ({total_orphans} stale orphan(s))" if total_orphans else ""
    print(f"check-missing-translations: All {len(locale_files)} locale(s) fully translated{suffix}. ✅")
    sys.exit(0)

# Violations found
print(f"check-missing-translations: {total_violations} violation(s) across "
      f"{len(locale_files)} locale(s) — "
      f"{total_missing} missing, {total_untranslated} untranslated"
      + (f", {total_orphans} orphan(s)" if total_orphans else ""))

if not advisory:
    print()
    print("To fix:")
    if total_missing > 0:
        print("  - Add the missing keys above to each locale's AmityLocalizable.strings")
    if total_untranslated > 0:
        print("  - Translate the untranslated values (currently identical to English)")
    print("  - See docs/consumer-localization-guide.md for instructions")
    print()
    print("To suppress a key that is intentionally identical to English, add it to")
    print("KNOWN_SAME in this script with a comment explaining why.")
    sys.exit(1)
else:
    print("(advisory mode — not failing build)")
    sys.exit(0)

PYEOF
