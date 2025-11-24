#!/bin/bash
# Screenshot Generation Script for App Store Submission
# This script helps generate required screenshots for iPhone 6.7" and iPad 12.9"

set -e

SCREENSHOT_DIR="AppStoreScreenshots"
mkdir -p "$SCREENSHOT_DIR/iPhone-6.7"
mkdir -p "$SCREENSHOT_DIR/iPad-12.9"

echo "📸 KryptoClaw App Store Screenshot Generator"
echo "============================================"
echo ""
echo "This script will help you generate screenshots for App Store submission."
echo ""
echo "Required Screenshots:"
echo "1. Home Screen (Balance Display)"
echo "2. Send Screen (Transaction Form)"
echo "3. Settings Screen (Privacy Policy visible)"
echo "4. Recovery/Backup Screen"
echo "5. Theme Selection Screen"
echo ""
echo "Target Devices:"
echo "- iPhone 15 Pro Max (6.7\")"
echo "- iPad Pro 12.9\" (6th generation)"
echo ""
echo "Instructions:"
echo "1. Open Xcode"
echo "2. Select 'iPhone 15 Pro Max' simulator"
echo "3. Build and run the app (Cmd+R)"
echo "4. Navigate to each screen listed above"
echo "5. Press Cmd+S to save screenshot (or use Device > Screenshot)"
echo "6. Screenshots will be saved to Desktop"
echo "7. Move screenshots to: $SCREENSHOT_DIR/iPhone-6.7/"
echo ""
echo "Repeat for iPad Pro 12.9\" simulator"
echo ""
echo "After generating screenshots, run:"
echo "  ./scripts/organize_screenshots.sh"
echo ""
echo "Ready to proceed? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Opening Simulator..."
    open -a Simulator
    echo ""
    echo "Next steps:"
    echo "1. In Simulator, go to: Device > Manage Devices"
    echo "2. Add iPhone 15 Pro Max if not present"
    echo "3. Add iPad Pro 12.9\" if not present"
    echo "4. Build app in Xcode and select appropriate simulator"
    echo "5. Take screenshots as described above"
else
    echo "Screenshot generation cancelled."
fi


