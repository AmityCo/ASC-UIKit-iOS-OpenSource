# AmityUIKit4 Localization & Text Override Guide

> **For consumers (app developers)** — How to translate the UIKit into your language or override any text string.

---

## Overview

AmityUIKit4 supports a **5-level string resolution chain**. Each level is checked in order; the first non-empty value wins.

```
Level 1 ── AmityUIKitConfig.json  "text" field  (highest priority)
Level 2 ── AmityStringProvider custom override
Level 3 ── Consumer app bundle  (your app's .lproj files)
Level 4 ── UIKit framework bundle  (built-in translations)
Level 5 ── Key string fallback  (lowest priority)
```

You can use any combination of these levels. Most consumers will use **Level 1** for one-off text changes and **Level 3** for full language translation.

---

## Level 1 — Config Text Override (per-element)

Override any UI element's text directly in `AmityUIKitConfig.json` without touching translations.

### Setup

Ensure your app loads its own config file before any UIKit views appear:

```swift
// AppDelegate.swift or SceneDelegate.swift
if let path = Bundle.main.path(forResource: "AmityUIKitConfig", ofType: "json") {
    AmityUIKit4Manager.setConfigFile(path)
}
```

> ⚠️ **Important:** There may be two `AmityUIKitConfig.json` files in an Xcode project — one at the project root (not bundled) and one inside the app folder (bundled). Always edit the **bundled** one — the file inside your app's source folder (e.g. `SampleApp/AmityUIKitConfig.json`).

### Usage

In your bundled `AmityUIKitConfig.json`, set the `"text"` field for any element:

```json
{
  "customizations": {
    "social_home_page/*/newsfeed_button": {
      "text": "Home Feed"
    },
    "social_home_page/*/explore_button": {
      "text": "Discover"
    },
    "post_detail_page/*/like_button": {
      "text": "Thumbs Up"
    }
  }
}
```

### Rules

- An **empty string** `""` is treated as "not set" — the next level is used.
- Any **non-empty string** takes priority over all translation files.
- Config text is **not** locale-aware — it shows the same text in every language.
- Changes require a **rebuild** of the app (the JSON is bundled at compile time).

### Common element keys

| Key | Default text | Description |
|-----|-------------|-------------|
| `social_home_page/*/newsfeed_button` | Newsfeed | Home feed tab |
| `social_home_page/*/explore_button` | Explore | Explore communities tab |
| `social_home_page/*/clips_button` | Clips | Clips tab |
| `social_home_page/*/my_communities_button` | My communities | My communities tab |
| `post_detail_page/*/like_button` | Like | Post like button |
| `post_detail_page/*/comment_button` | Comment | Post comment button |
| `community_profile_page/*/post_button` | Post | Create post button |
| `select_post_target_page/*/my_timeline_text` | My Timeline | My timeline row |

---

## Level 2 — Programmatic String Override

Override specific keys at runtime via `AmityStringProvider`. Useful for A/B testing or user-preference-based text.

```swift
// Override individual keys
AmityStringProvider.social.setOverride(
    key: AmityLocalizedStringSet.Social.socialHomeNewsfeedTab,
    value: "Home"
)

// Override multiple keys at once
AmityStringProvider.social.setOverrides([
    AmityLocalizedStringSet.Social.socialHomeExploreTab: "Discover",
    AmityLocalizedStringSet.Social.socialHomeClipsTab:   "Videos"
])

// Remove an override (falls back to Level 3+)
AmityStringProvider.social.removeOverride(
    key: AmityLocalizedStringSet.Social.socialHomeNewsfeedTab
)
```

Available providers:

| Provider | Covers |
|----------|--------|
| `AmityStringProvider.social` | Social feed, posts, communities |
| `AmityStringProvider.common` | Shared UI (buttons, errors, dialogs) |
| `AmityStringProvider.chat` | Chat & messaging |

---

## Level 3 — Consumer App Translation Files

Add a full translation for any language. This is the **recommended approach** for localizing into a new language not included in the UIKit.

### Step 1 — Create the `.lproj` directory in your app

```
MyApp/
├── en.lproj/
│   └── AmityLocalizable.strings   ← optional English overrides
├── th.lproj/
│   └── AmityLocalizable.strings   ← Thai translation
└── ja.lproj/
    └── AmityLocalizable.strings   ← Japanese translation
```

### Step 2 — Add strings to `AmityLocalizable.strings`

The file name **must** be `AmityLocalizable.strings` (not `Localizable.strings`).

```strings
/* Social home tabs */
"social_home_newsfeed_tab" = "ฟีด";
"social_home_explore_tab" = "สำรวจ";
"social_home_clips_tab" = "คลิป";
"social_home_my_communities_tab" = "ชุมชนของฉัน";

/* Post actions */
"post_like_button_text" = "ถูกใจ";
"post_comment_button_text" = "แสดงความคิดเห็น";
"post_share_button_text" = "แชร์";
```

You do not need to include every key — any key not found in your file falls through to the UIKit's built-in translations.

### Step 3 — Register the language in your Xcode project

In your Xcode project settings under **Info → Localizations**, add the language. Xcode automatically sets up the `.lproj` directory as a known region.

Your app's `Info.plist` must also declare the language:

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>th</string>
</array>
```

### Step 4 — Tell UIKit to check your bundle first

This is done automatically. `AmityStringProvider` and `String.localizedString` check `Bundle.main` (your app bundle) **before** the UIKit framework bundle.

### How it works

```
User device language = Thai
  → Check Bundle.main/th.lproj/AmityLocalizable.strings  ← your overrides
  → Check Framework/th.lproj/AmityLocalizable.strings    ← UIKit built-in Thai
  → Check Bundle.main/en.lproj/AmityLocalizable.strings
  → Check Framework/en.lproj/AmityLocalizable.strings
  → Return key name as fallback
```

### SPM consumers (future)

When UIKit4 is distributed via SPM, the framework bundle is accessed via `Bundle.module`. The consumer bundle check (`Bundle.main`) still works the same way — place your `AmityLocalizable.strings` files in your app target's lproj directories as described above.

---

## Built-in Languages

AmityUIKit4 ships with the following translations out of the box:

| Language | Code | Status |
|----------|------|--------|
| English | `en` | ✅ Complete (878 keys) |

Additional languages can be contributed via pull request or provided by the consumer app at Level 3.

---

## Localizing Reaction Names

Reaction emoji tooltips (shown when long-pressing a reaction) are localized through the standard string resolution chain.

### Default reactions

The UIKit ships with 7 default reaction display names:

| Key | English | Thai |
|-----|---------|------|
| `amity_common_reaction_like` | Like | ถูกใจ |
| `amity_common_reaction_love` | Love | รัก |
| `amity_common_reaction_fire` | Fire | ไฟ |
| `amity_common_reaction_happy` | Happy | มีความสุข |
| `amity_common_reaction_sad` | Sad | เศร้า |
| `amity_common_reaction_heart` | Heart | หัวใจ |
| `amity_common_reaction_grinning` | Grinning | ยิ้มกว้าง |

Include these keys in your `AmityLocalizable.strings` file to translate them:

```strings
/* Reaction display names */
"amity_common_reaction_like"     = "ถูกใจ";
"amity_common_reaction_love"     = "รัก";
"amity_common_reaction_fire"     = "ไฟ";
"amity_common_reaction_happy"    = "มีความสุข";
"amity_common_reaction_sad"      = "เศร้า";
"amity_common_reaction_heart"    = "หัวใจ";
"amity_common_reaction_grinning" = "ยิ้มกว้าง";
```

Or via the programmatic API (Level 2):

```swift
AmityStringProvider.common.setOverrides([
    "amity_common_reaction_like":     "ถูกใจ",
    "amity_common_reaction_love":     "รัก",
    "amity_common_reaction_fire":     "ไฟ",
    "amity_common_reaction_happy":    "มีความสุข",
    "amity_common_reaction_sad":      "เศร้า",
    "amity_common_reaction_heart":    "หัวใจ",
    "amity_common_reaction_grinning": "ยิ้มกว้าง",
])
```

### Custom reactions

If you've configured custom reactions via `AmityUIKitConfig.json` (e.g., a reaction named `"celebrate"`), translate it by adding the corresponding key:

```strings
/* Custom reaction — name must match the "name" field in config.json */
"amity_common_reaction_celebrate" = "เฉลิมฉลอง";
```

The naming convention is: `amity_common_reaction_{reaction_name}` where `{reaction_name}` matches the `name` field in your `social_reactions` or `message_reactions` array in `config.json`.

### Resolution rules

1. Key is constructed as `amity_common_reaction_{name}` from the reaction's `name` field in config.
2. Resolved through the standard chain (Levels 2–5). **Config text (Level 1) does not apply** to reaction display names.
3. If no translation is found at any level, the UIKit falls back to title-casing the reaction name (e.g., `"celebrate"` → `"Celebrate"`).

> ⚠️ The `name` field in `config.json` is also used as the **API identifier** sent to the Amity backend. **Never translate the `name` field itself** — only add an `amity_common_reaction_{name}` key in your strings file.

---

## Format Strings (Plurals & Variables)

Some strings contain `%@` or `%d` placeholders. Pass the value using the `localized(arguments:)` method:

```swift
// %d integer
let text = AmityLocalizedStringSet.Social.commentCountPlural.localized(arguments: 42)
// → "42 comments"

// %@ string (member count)
let text = AmityLocalizedStringSet.Social.communityMemberCountPlural.localized(arguments: "1,234")
// → "1,234 members"
```

In your `.strings` file, preserve the format specifier:

```strings
"comment_count_plural" = "%d ความคิดเห็น";
"community_member_count_plural" = "%@ สมาชิก";
```

> Thai does not use grammatical plurals — singular and plural forms are usually identical.

---


## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Text still in English after setting Thai | `.lproj` not added to Xcode localizations | Add language in Xcode project settings |
| Consumer overrides not showing | Wrong file edited (root vs bundled) | Edit the file inside your app source folder, not the project root |
| Config text not showing | App not rebuilt after JSON change | JSON is compiled into the bundle — rebuild required |
| `%@` showing literally | Wrong format specifier in `.strings` | Use `%@` for strings, `%d` for integers |
| Empty text despite override | Config has `"text": ""` which is treated as nil | Use any non-empty string, or remove the key |
| Remote config overriding local | `syncNetworkConfig()` cached server values | Server-side config (from CMS) takes priority when synced |
