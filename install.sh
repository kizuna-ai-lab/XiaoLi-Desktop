#!/bin/bash
set -xe -o pipefail

IGNORE_LINT=false
DRY_RUN=false
DEBUG_MODE=false

# Parse command-line options
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ignore-lint) IGNORE_LINT=true ;;
        --dry-run) DRY_RUN=true ;;
        --debug) DEBUG_MODE=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Set configuration based on debug mode
if [ "$DEBUG_MODE" = true ]; then
    BUILD_CONFIG="Debug"
    echo "Building in DEBUG mode..."
else
    BUILD_CONFIG="Release"
    echo "Building in RELEASE mode..."
fi

# Always clean DerivedData cache to avoid configuration mismatch issues
echo "Cleaning Xcode DerivedData cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/azooKeyMac-*

if [ "$IGNORE_LINT" = false ]; then
    if command -v swiftlint &> /dev/null
    then
        # Fix auto-fixable errors
        swiftlint --fix --format
        # Check other errors
        swiftlint --quiet --strict
    else
        echo "swiftlint could not be found. Please rerun the script as \`./install.sh --ignore-lint\`."
        echo "For contributing to XiaoLi IME on macOS, we strongly recommend you to install swiftlint"
        echo "To install swiftlint, run \`brew install swiftlint\`"
        exit 1
    fi
else
    echo "Skipping swiftlint checks due to --ignore-lint option."
fi


# Check if xcpretty is installed
if command -v xcpretty &> /dev/null
then
    xcodebuild -project azooKeyMac.xcodeproj -scheme XiaoLiIME -configuration "$BUILD_CONFIG" clean archive -archivePath build/archive.xcarchive CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO | xcpretty
else
    echo "xcpretty could not be found. Proceeding without xcpretty."
    xcodebuild -project azooKeyMac.xcodeproj -scheme XiaoLiIME -configuration "$BUILD_CONFIG" clean archive -archivePath build/archive.xcarchive CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
fi

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN: Would execute the following commands:"
    echo "  sudo rm -rf /Library/Input\ Methods/XiaoLiIME.app"
    echo "  sudo cp -r build/archive.xcarchive/Products/Applications/XiaoLiIME.app /Library/Input\ Methods/"
    echo "  pkill XiaoLiIME"
    echo "Build completed successfully. Use without --dry-run to actually install."
else
    sudo rm -rf /Library/Input\ Methods/XiaoLiIME.app
    sudo cp -r build/archive.xcarchive/Products/Applications/XiaoLiIME.app /Library/Input\ Methods/
    pkill XiaoLiIME || true
    sleep 1
    # Re-register input source using TIS API
    swift - << 'EOF'
import Carbon

let bundleURL = URL(fileURLWithPath: "/Library/Input Methods/XiaoLiIME.app")
let status = TISRegisterInputSource(bundleURL as CFURL)
if status != noErr {
    print("Warning: TISRegisterInputSource returned \(status)")
}
EOF
    echo ""
    echo "Installation complete. (Configuration: $BUILD_CONFIG)"
fi
