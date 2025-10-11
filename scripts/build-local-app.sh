#!/bin/bash
# build-local-app.sh

echo "🚀 Building CarStatus for personal use..."

# Check if Xcode is properly set up
echo "🔧 Checking Xcode setup..."
if ! xcode-select -p | grep -q "Xcode.app"; then
    echo "⚠️  Setting Xcode as active developer directory..."
    
    # Try to find Xcode in common locations
    if [ -d "/Applications/Xcode.app" ]; then
        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
        echo "✅ Set Xcode path to /Applications/Xcode.app"
    elif [ -d "/Applications/Xcode-beta.app" ]; then
        sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer
        echo "✅ Set Xcode path to /Applications/Xcode-beta.app"
    else
        echo "❌ Xcode not found in /Applications/"
        echo "💡 Please install Xcode from the App Store or run:"
        echo "   sudo xcode-select -s /path/to/your/Xcode.app/Contents/Developer"
        exit 1
    fi
fi

PROJECT_DIR="/Users/benjaminwhitworth/Projects/car-status"
cd "$PROJECT_DIR"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf ./LocalBuild
rm -rf /Applications/car-status.app

# Build release version directly (no archiving)
echo "🔨 Building app..."
xcodebuild \
    -project car-status.xcodeproj \
    -scheme car-status \
    -configuration Release \
    -derivedDataPath ./LocalBuild \
    -allowProvisioningUpdates \
    build

# Find the built app
APP_PATH=$(find ./LocalBuild -name "car-status.app" -type d | head -1)

if [ -d "$APP_PATH" ]; then
    echo "✅ Build successful!"
    echo "📍 App location: $APP_PATH"
    
    # Copy to Applications
    echo "📦 Installing to Applications..."
    cp -r "$APP_PATH" /Applications/
    
    # Make it executable
    chmod +x "/Applications/car-status.app/Contents/MacOS/"*
    
    echo "🎉 Installation complete!"
    echo ""
    echo "🚀 You can now:"
    echo "   • Launch from Spotlight: Press Cmd+Space, type 'car-status'"
    echo "   • Open from Applications folder"
    echo "   • Look for the car icon in your menu bar"
    echo ""
    
    # Test launch
    echo "🧪 Testing launch..."
    open /Applications/car-status.app
    
    # Clean up build files
    echo "🧹 Cleaning up build files..."
    rm -rf ./LocalBuild
    
else
    echo "❌ Build failed - checking for issues..."
    echo "📋 Contents of LocalBuild directory:"
    find ./LocalBuild -type f -name "*.app" 2>/dev/null || echo "No .app files found"
    echo "💡 Try building manually in Xcode first to check for errors:"
    echo "   1. Open car-status.xcodeproj"
    echo "   2. Product → Clean Build Folder"
    echo "   3. Product → Build"
    echo "   4. Check for any build errors"
fi
