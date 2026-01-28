# XiaoLi IME Fork Changes

This document describes all changes made to fork azooKey-Desktop into XiaoLi IME.

## Summary

XiaoLi IME is a fork of [azooKey-Desktop](https://github.com/azooKey/azooKey-Desktop), rebranded and customized for distribution.

## Bundle ID and Input Source Changes

### Bundle Identifier
- Changed from: `dev.ensan.inputmethod.azooKeyMac`
- Changed to: `ai.kizuna.inputmethod.XiaoLiIME`

### Input Source IDs
- Japanese: `ai.kizuna.inputmethod.XiaoLiIME.Japanese`
- Roman/English: `ai.kizuna.inputmethod.XiaoLiIME.Roman`

### App Group Identifier
- `group.ai.kizuna.inputmethod.XiaoLiIME`

## File Changes

### Renamed Files

| Original | New |
|----------|-----|
| `azooKeyMac.xcscheme` | `XiaoLiIME.xcscheme` |
| `azooKeyMacTests.swift` | `XiaoLiIMETests.swift` |
| `azooKeyMacUITests.swift` | `XiaoLiIMEUITests.swift` |
| `azooKeyMacUITestsLaunchTests.swift` | `XiaoLiIMEUITestsLaunchTests.swift` |

### Modified Files

#### Info.plist (`azooKeyMac/Info.plist`)
- Updated `InputMethodServerControllerClass` to `$(PRODUCT_MODULE_NAME).XiaoLiInputController`
- Updated all input source IDs to use `ai.kizuna.inputmethod.XiaoLiIME.*`

#### Input Controller (`azooKeyMac/InputController/azooKeyMacInputController.swift`)
- Renamed class from `azooKeyMacInputController` to `XiaoLiInputController`
- Updated application support directory to `XiaoLiIME`
- Updated app group identifier
- Updated menu title to "XiaoLi"
- Updated input mode selection calls

#### Input Controller Helper (`azooKeyMac/InputController/azooKeyMacInputControllerHelper.swift`)
- Updated GitHub repository URL
- Updated memory directory reference from `azooKeyMemoryDir` to `xiaoliMemoryDir`

#### SegmentsManager (`Core/Sources/Core/InputUtils/SegmentsManager.swift`)
- Updated version string from "azooKey on macOS" to "XiaoLi IME on macOS"
- Renamed `azooKeyMemoryDir` to `xiaoliMemoryDir`

#### CustomInputTableStore (`Core/Sources/Core/Configs/CustomInputTableStore.swift`)
- Updated table name from `azooKeyMac.customRomajiTable` to `XiaoLiIME.customRomajiTable`
- Updated app support subdirectory from `azooKeyMac` to `XiaoLiIME`

#### Build Scripts
- `install.sh`: Updated scheme, app name, process name
- `pkgbuild.sh`: Updated scheme and app name
- `pkg.plist`: Updated app bundle path

#### Test Files
- Updated module imports from `azooKeyMac` to `XiaoLiIME`
- Updated class names

#### README.md
- Replaced with XiaoLi-specific documentation

## Target Names

The Xcode project targets have been renamed:
- `azooKeyMac` → `XiaoLiIME`
- `azooKeyMacTests` → `XiaoLiIMEMacTests`
- `azooKeyMacUITests` → `XiaoLiIMEMacUITests`

## Directory Structure

Application support directory:
- Old: `~/Library/Application Support/azooKeyMac/`
- New: `~/Library/Application Support/XiaoLiIME/`

Memory directory:
- Old: `~/Library/Application Support/azooKeyMac/memory/`
- New: `~/Library/Application Support/XiaoLiIME/memory/`

## Menu Bar Icons

The menu bar icons (`main.tiff`, `main@2x.tiff`, `en.tiff`, `en@2x.tiff`) are template images that work with both light and dark mode.

## Localization

XiaoLi IME supports three languages:
- English (`en.lproj`)
- Japanese (`ja.lproj`)
- Simplified Chinese (`zh-Hans.lproj`)

### Localization Files

Each language directory contains:
- `InfoPlist.strings` - App name and input source names
- `Localizable.strings` - All UI strings

### Localized UI Elements

- Menu items (Live Conversion, Smart Conversion, Settings)
- Settings window (all tabs: Basic, Customize, Advanced)
- User dictionary editor
- Romaji table editor
- Error messages
- Help text

### Adding New Languages

1. Create a new `.lproj` directory (e.g., `ko.lproj` for Korean)
2. Copy `Localizable.strings` and `InfoPlist.strings` from an existing language
3. Translate all string values
4. Add the language to the Xcode project's localization settings

## Dependencies

No dependency changes were made. The project still uses:
- AzooKeyKanaKanjiConverter (Zenzai engine)
- llama.cpp (Neural inference)
- SwiftyMarisa (LOUDS trie)
- swift-transformers (Tokenization)

## Building

```bash
# Clone with submodules
git clone --recursive https://github.com/kizuna-ai-lab/XiaoLi-Desktop

# Build and install
./install.sh

# Or with options
./install.sh --ignore-lint    # Skip SwiftLint
./install.sh --dry-run        # Build without installing
```

## Notes

1. The Xcode project file is still named `azooKeyMac.xcodeproj` but produces `XiaoLiIME.app`
2. Some internal comments still reference "azooKeyMac" but this doesn't affect functionality
3. Code signing requires valid Apple Developer credentials
