#!/bin/bash
# pre-push-cleanup.sh

echo "🧹 Cleaning up project before git push..."

cd /Users/benjaminwhitworth/Projects/car-status

# Remove build artifacts
echo "Removing build artifacts..."
rm -rf build/
rm -rf LocalBuild/
rm -rf .build/
rm -rf DerivedData/

# Remove macOS system files
echo "Removing system files..."
find . -name ".DS_Store" -delete

# Remove Xcode user data (these should be in .gitignore but let's be sure)
echo "Cleaning Xcode user data..."
rm -rf car-status.xcodeproj/xcuserdata/
rm -rf car-status.xcodeproj/project.xcworkspace/xcuserdata/

# Show what will be committed
echo ""
echo "📋 Files staged for commit:"
git status --short

echo ""
echo "✅ Cleanup complete! Ready for git commit."
