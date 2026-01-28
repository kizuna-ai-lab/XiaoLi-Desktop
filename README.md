# XiaoLi IME (小李输入法)

XiaoLi IME is a Japanese input method for macOS, forked from [azooKey-Desktop](https://github.com/azooKey/azooKey-Desktop). It features the high-precision neural kana-kanji conversion engine "Zenzai".

**Currently in alpha - functionality is not guaranteed.**

## Features

* High-precision conversion powered by "Zenzai" neural kana-kanji conversion
  * Profile prompt feature
  * Learning history feature
  * User dictionary feature
* LLM-powered "Smart Conversion" feature
* Live conversion
* Native AZIK support

## System Requirements

* macOS 15+
* Xcode 16.1+ (for development)
* Git LFS installed

## Installation

### From Source

```bash
# Install Git LFS first
brew install git-lfs
git lfs install

# Clone the repository with submodules
git clone https://github.com/kizuna-ai-lab/XiaoLi-Desktop --recursive
cd xiaoli-ime

# Build and install
./install.sh
```

After installation:
1. Log out and log back in to macOS
2. Go to "System Settings" > "Keyboard" > "Input Sources" > Edit > "+" button > "Japanese" > Add XiaoLi IME > Done
3. Select XiaoLi IME from the menu bar icon

## Development Guide

### Prerequisites
* macOS 15+
* Xcode 16.1+
* Git LFS installed
* SwiftLint installed (recommended)

### Building and Debugging

Make sure your environment is set up correctly. Git LFS is required for proper cloning.

```bash
# Update submodules
git submodule update --init

# Build and install
./install.sh
```

During development, you can kill the XiaoLi IME process to reload the latest version:
```bash
pkill XiaoLiIME
```

### Troubleshooting

If the build fails:
* You may need to change the "Team ID" in Xcode GUI
  * Open `azooKeyMac.xcodeproj` in Xcode
  * Go to XiaoLiIME target > Signing & Capabilities > Change Team to Personal Team
  * Replace all bundle ID strings in the repository (e.g., `ai.kizuna.inputmethod.XiaoLiIME` → `dev.yourname.inputmethod.XiaoLiIME`)
* If you see "Packages are not supported when using legacy build locations", check your Xcode Derived Data settings
* Xcode 16.0 may have compatibility issues. Use Xcode 16.1+

If conversion accuracy seems poor:
* Check if Git LFS files are properly downloaded. The file `azooKeyMac/Resources/zenz-v3-small-gguf/ggml-model-Q5_K_M.gguf` should be about 70MB.

## Credits

XiaoLi IME is based on [azooKey-Desktop](https://github.com/azooKey/azooKey-Desktop) by [ensan-hcl](https://github.com/ensan-hcl).

### Original azooKey References
* https://mzp.hatenablog.com/entry/2017/09/17/220320
* https://www.logcg.com/en/archives/2078.html
* https://stackoverflow.com/questions/27813151/how-to-develop-a-simple-input-method-for-mac-os-x-in-swift
* https://mzp.booth.pm/items/809262

## License

MIT License - see [LICENSE](LICENSE) file for details.
